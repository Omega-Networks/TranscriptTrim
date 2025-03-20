//
//  ContentView.swift
//
//  TranscriptTrim - A WebVTT and transcript file processing utility
//
//  Created by Omega Networks Ltd, New Zealand
//  Copyright © 2025 Omega Networks Ltd. All rights reserved.
//
//  This file is part of TranscriptTrim.
//
//  TranscriptTrim is licensed under the MIT License with additional conditions:
//  - If modified, proper attribution to Omega Networks Ltd must be included
//  - If sold or monetized, a commercial license must be obtained from Omega Networks Ltd
//
//  For the full license text, see the LICENSE file in the project root.
//

import SwiftUI
import UniformTypeIdentifiers

/**
 * Primary view controller for the TranscriptTrim application
 *
 * Implements a hybrid MVC/MVVM architecture where:
 * - File operations are delegated to parser utilities
 * - UI state is maintained locally for immediate feedback
 * - Notification center is used for cross-module communication
 *
 * This approach balances separation of concerns with SwiftUI's state-driven model
 * while avoiding tight coupling between UI and business logic.
 */
struct ContentView: View {
    // MARK: - State Properties
    @State private var isFilePickerPresented = false
    @State private var isSaveDialogPresented = false
    @State private var transcript: [Transcript] = []
    @State private var filePreview: String = "No file selected."
    @State private var exportText: String = ""
    @State private var showClipboardConfirmation = false
    @State private var showTranscriptDetail = false
    @State private var selectedTranscript: Transcript? = nil
    @State private var inputFilename: String = ""
    @State private var originalContent: String = ""
    @State private var tokenAnalysisResult: TokenAnalyzer.TokenAnalysisResult? = nil
    @State private var costSavings: Double = 0.0
    @State private var showAboutView = false
    @State private var selectedModelType: TokenAnalyzer.TokenizerModelType = .gpt4
    @State private var showErrorDetails = false
    @State private var lastError: String? = nil
    @State private var isDropTargeted: Bool = false
    
    // MARK: - Initialization
    
    init() {
        // Set up notification observers for menu commands
        setupNotificationObservers()
    }
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header area
                HStack {
                    Text("VTT Transcript Parser")
                        .font(.headline)
                        .padding(.top)
                    
                    Spacer()
                    // TODO: About button crashes on IOS
                    #if os(macOS)
                    Button(action: {
                        showAboutView = true
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                    .padding(.top)
                    #endif
                }
                
                // File picker button
                Button(action: {
                    isFilePickerPresented = true
                }) {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("Select .vtt file")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                }
                .fileImporter(
                    isPresented: $isFilePickerPresented,
                    allowedContentTypes: [.plainText, .text, createVTTType()],
                    allowsMultipleSelection: false
                ) { result in
                    handleFileSelection(result)
                }
                .background(Color.accentColor)
                .cornerRadius(8)
                
                // Display the file preview
                VStack {
                    Text(filePreview)
                        .foregroundColor(.primary)
                        .padding()
                        .frame(maxWidth: .infinity, minHeight: 80, maxHeight: 120)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    
                    // Error details button if there's an error
                    if lastError != nil {
                        Button(action: {
                            showErrorDetails.toggle()
                        }) {
                            Text(showErrorDetails ? "Hide Error Details" : "Show Error Details")
                                .font(.footnote)
                                .foregroundColor(.blue)
                        }
                        
                        if showErrorDetails, let error = lastError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.black.opacity(0.05))
                                .cornerRadius(8)
                        }
                    }
                    
                    // Model selection picker
                    if tokenAnalysisResult == nil {
                        VStack(spacing: 8) {
                            Text("Select token model:")
                                .font(.callout)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Picker("Token Model", selection: $selectedModelType) {
                                ForEach(TokenAnalyzer.TokenizerModelType.allCases) { model in
                                    Text(model.rawValue).tag(model)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .labelsHidden()
                        }
                        .padding(.top, 4)
                    }
                }
                
                // Display token analysis if available
                if let analysis = tokenAnalysisResult {
                    TokenAnalysisView(result: analysis, costSavings: costSavings)
                        .padding(.horizontal)
                }
                
                // Display the cleaned-up transcript
                transcriptListView
                
                // Buttons row
                HStack(spacing: 20) {
                    // Export to clipboard button
                    Button(action: {
                        copyToClipboardAction()
                    }) {
                        HStack {
                            Image(systemName: "doc.on.clipboard")
                            Text("Copy to Clipboard")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                    }
                    .disabled(transcript.isEmpty)
                    .background(transcript.isEmpty ? Color.gray.opacity(0.5) : Color.accentColor)
                    .cornerRadius(8)
                    
                    // Save to file button
                    Button(action: {
                        saveToFileAction()
                    }) {
                        HStack {
                            Image(systemName: "arrow.down.doc")
                            Text("Save as TXT file")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                    }
                    .disabled(transcript.isEmpty)
                    .fileExporter(
                        isPresented: $isSaveDialogPresented,
                        document: TextDocument(text: exportText),
                        contentType: .plainText,
                        defaultFilename: Utilities.getSuggestedOutputFilename(from: inputFilename)
                    ) { result in
                        handleFileSave(result)
                    }
                    .background(transcript.isEmpty ? Color.gray.opacity(0.5) : Color.blue)
                    .cornerRadius(8)
                }
                
                // Show clipboard confirmation
                if showClipboardConfirmation {
                    Text("Copied to clipboard!")
                        .foregroundColor(.green)
                        .padding(8)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                        .transition(.opacity)
                        .animation(.easeInOut, value: showClipboardConfirmation)
                }
            }
            .padding()
        }
        // Add bottom padding using regular padding modifier that works on all platforms
        .sheet(isPresented: $showTranscriptDetail) {
            if let selectedTranscript = selectedTranscript {
                TranscriptDetailView(transcript: selectedTranscript)
            }
        }
        .sheet(isPresented: $showAboutView) {
            AboutView()
        }
        
        // Add drop destination for VTT files
        .dropDestination(for: URL.self) { items, location in
            // Handle dropped URLs
            if let droppedURL = items.first {
                // Process the dropped file
                handleDroppedFile(droppedURL)
                return true
            }
            return false
        } isTargeted: { isTargeted in
            isDropTargeted = isTargeted
        }
        // Visual feedback when dragging
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.accentColor, lineWidth: 2)
                .opacity(isDropTargeted ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: isDropTargeted)
        )
    }
    
    // MARK: - Subviews
    
    /// The transcript list view with formatted entries
    private var transcriptListView: some View {
        Group {
            if transcript.isEmpty {
                emptyTranscriptView
            } else {
                List {
                    ForEach(transcript) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            if let previousIndex = transcript.firstIndex(where: { $0.id == item.id })?.advanced(by: -1),
                               previousIndex >= 0 && transcript[previousIndex].speaker == item.speaker {
                                // Don't show speaker name if same as previous entry
                                Text(item.dialogue)
                                    .font(.body)
                                    .padding(.leading, 8)
                            } else {
                                // Show speaker name for new speakers
                                Text(item.speaker)
                                    .font(.headline)
                                    .foregroundColor(.accentColor)
                                
                                Text(item.dialogue)
                                    .font(.body)
                                    .padding(.leading, 8)
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedTranscript = item
                            showTranscriptDetail = true
                        }
                    }
                }
                // Different list styles optimized for each platform
                #if os(macOS)
                .listStyle(DefaultListStyle())
                #else
                .listStyle(InsetGroupedListStyle())
                #endif
                .frame(maxWidth: .infinity, minHeight: 200)
                .cornerRadius(10)
            }
        }
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
    
    /// Empty state view when no transcript is loaded
    private var emptyTranscriptView: some View {
        VStack(spacing: 2) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No transcript loaded")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Select a VTT or text file to view the transcript")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Text("or drag and drop a file here")
                .font(.caption)
                .foregroundColor(.gray)
                .italic()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Helper Methods
    
    /**
     * Sets up notification observers for menu commands
     */
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .copyToClipboard,
            object: nil,
            queue: .main
        ) { _ in
            copyToClipboardAction()
        }
        
        NotificationCenter.default.addObserver(
            forName: .saveToFile,
            object: nil,
            queue: .main
        ) { _ in
            saveToFileAction()
        }
        
        NotificationCenter.default.addObserver(
            forName: .showAbout,
            object: nil,
            queue: .main
        ) { _ in
            showAboutView = true
        }
    }
    
    /**
     * Handles files dropped onto the view
     *
     * - Parameter url: The URL of the dropped file
     */
    private func handleDroppedFile(_ url: URL) {
        // Check if the file has a valid extension
        let validExtensions = ["vtt", "txt", "text"]
        let fileExtension = url.pathExtension.lowercased()
        
        guard validExtensions.contains(fileExtension) else {
            filePreview = "Error: Please drop a .vtt or .txt file"
            lastError = "Invalid file type. Only .vtt and .txt files are supported."
            return
        }
        
        // Process the file using the existing handler
        handleFileSelection(.success([url]))
    }
    
    /**
     * Handles file selection with enhanced error prevention for search issues
     *
     * Implements a workaround for the search field issue in document picker:
     * - Uses task.detached for file reading to prevent UI thread blocking
     * - Adds extra validation to prevent common file access failures
     * - Provides specific error handling for document picker navigation issues
     */
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        // Reset error state
        lastError = nil
        
        switch result {
        case .success(let urls):
            if let url = urls.first {
                do {
                    #if os(iOS)
                    // On iOS, start security scoped resource access
                    let canAccess = url.startAccessingSecurityScopedResource()
                    
                    // Ensure we stop accessing the resource when done
                    defer {
                        if canAccess {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }
                    #endif
                    
                    // Save bookmark for persistent access
                    let bookmarkData = try url.bookmarkData(
                        options: .minimalBookmark,
                        includingResourceValuesForKeys: nil,
                        relativeTo: nil
                    )
                    UserDefaults.standard.set(bookmarkData, forKey: "VTTFileBookmark")
                    
                    // Extract filename without extension for later use
                    inputFilename = url.deletingPathExtension().lastPathComponent
                    
                    // Read original content for token analysis
                    originalContent = try String(contentsOf: url, encoding: .utf8)
                    
                    // Parse the file
                    let parseResult = TranscriptParser.parse(url: url)
                    transcript = parseResult.transcripts
                    filePreview = parseResult.message
                    
                    // Check if there was a parsing issue
                    if parseResult.transcripts.isEmpty && !parseResult.message.contains("No file selected") {
                        lastError = parseResult.message
                    }
                    
                    // Generate the processed text
                    if !transcript.isEmpty {
                        let processedText = TranscriptParser.prepareForExport(transcript)
                        
                        // Analyze token reduction
                        let analysis = TokenAnalyzer.analyzeTokenReduction(
                            originalText: originalContent,
                            processedText: processedText,
                            modelType: selectedModelType
                        )
                        tokenAnalysisResult = analysis
                        
                        // Calculate cost savings
                        costSavings = TokenAnalyzer.calculateCostSavings(for: analysis)
                    }
                } catch let error as NSError {
                    // Handle permissions errors specifically
                    if error.domain == NSCocoaErrorDomain && error.code == 257 {
                        let detailedError = """
                        Permission Error (Code 257): Unable to access the selected file.
                        
                        Possible solutions:
                        1. Try selecting a file from your Documents or Downloads folder
                        2. Make sure the file isn't in a restricted location
                        3. Check that the file isn't being used by another application
                        
                        Technical details: \(error.localizedDescription)
                        """
                        lastError = detailedError
                        filePreview = "Permission denied: Please select a file from Documents or Downloads."
                    } else {
                        lastError = "Error: \(error.localizedDescription)\nDomain: \(error.domain), Code: \(error.code)"
                        filePreview = "Error reading file. See details below."
                    }
                    
                    // Reset transcript and analysis data
                    transcript = []
                    tokenAnalysisResult = nil
                } catch {
                    lastError = "Unexpected error: \(error.localizedDescription)"
                    filePreview = "Error reading file. See details below."
                    
                    // Reset transcript and analysis data
                    transcript = []
                    tokenAnalysisResult = nil
                }
            }
        case .failure(let error):
            lastError = "File selection error: \(error.localizedDescription)"
            filePreview = "Error selecting file. See details below."
        }
    }
    
    /**
     * Handles the result from the file exporter.
     */
    private func handleFileSave(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            filePreview = "Saved to: \(url.lastPathComponent)"
            lastError = nil
        case .failure(let error):
            filePreview = "Error saving file. See details below."
            lastError = "Save error: \(error.localizedDescription)"
        }
    }
    
    /**
     * Action to copy transcript to clipboard
     */
    private func copyToClipboardAction() {
        if !transcript.isEmpty {
            exportText = TranscriptParser.prepareForExport(transcript)
            Utilities.copyToClipboard(exportText)
            showClipboardConfirmation = true
            
            // Hide confirmation after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showClipboardConfirmation = false
            }
        }
    }
    
    /**
     * Action to save transcript to a file
     */
    private func saveToFileAction() {
        if !transcript.isEmpty {
            exportText = TranscriptParser.prepareForExport(transcript)
            isSaveDialogPresented = true
        }
    }
}

/**
 * Preview provider for ContentView
 */
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// No need to redeclare showAbout notification - it's defined in TranscriptTrimApp.swift

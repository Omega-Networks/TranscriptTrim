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
 * The main view of the Transcript Trim application.
 * Handles file selection, transcript display, and export operations.
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
    
    // MARK: - Initialization
    
    init() {
        // Set up notification observers for menu commands
        setupNotificationObservers()
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 20) {
            // Header area
            Text("VTT Transcript Parser")
                .font(.headline)
                .padding(.top)
            
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
                .foregroundColor(.primary)
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
                    .background(Color.gray.opacity(0.7))
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            
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
                    .foregroundColor(.primary)
                }
                .disabled(transcript.isEmpty)
                .background(transcript.isEmpty ? Color.gray : Color.accentColor)
                .cornerRadius(8)
                
                // Save to file button
                Button(action: {
                    saveToFileAction()
                }) {
                    HStack {
                        Image(systemName: "arrow.down.doc")
                        Text("Save as TXT")
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
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
                .background(transcript.isEmpty ? Color.gray : Color.blue)
                .cornerRadius(8)
            }
            .padding(.bottom)
            
            // Show clipboard confirmation
            if showClipboardConfirmation {
                Text("Copied to clipboard!")
                    .foregroundColor(.green)
                    .padding(8)
                    .cornerRadius(8)
                    .transition(.opacity)
                    .animation(.easeInOut, value: showClipboardConfirmation)
            }
        }
        .padding()
        .sheet(isPresented: $showTranscriptDetail) {
            if let selectedTranscript = selectedTranscript {
                TranscriptDetailView(transcript: selectedTranscript)
            }
        }
    }
    
    // MARK: - Subviews
    
    /// The transcript list view with formatted entries
    private var transcriptListView: some View {
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
        #if os(iOS)
        .listStyle(InsetGroupedListStyle())
        #else
        .listStyle(DefaultListStyle())
        #endif
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
        .frame(maxWidth: .infinity)
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
    }
    
    /**
     * Handles the result from the file importer.
     */
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                // Save bookmark for persistent access
                do {
                    let bookmarkData = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
                    UserDefaults.standard.set(bookmarkData, forKey: "VTTFileBookmark")
                    
                    // Extract filename without extension for later use
                    inputFilename = url.deletingPathExtension().lastPathComponent
                    
                    // Parse the file
                    let parseResult = TranscriptParser.parse(url: url)
                    transcript = parseResult.transcripts
                    filePreview = parseResult.message
                } catch {
                    print("Failed to create bookmark: \(error)")
                }
            }
        case .failure(let error):
            filePreview = "Error selecting file: \(error.localizedDescription)"
        }
    }
    
    /**
     * Handles the result from the file exporter.
     */
    private func handleFileSave(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            filePreview = "Saved to: \(url.lastPathComponent)"
        case .failure(let error):
            filePreview = "Error saving file: \(error.localizedDescription)"
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

//
//  TranscriptTrimApp.swift
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

/**
 * Main entry point for the TranscriptTrim application.
 *
 * Implements a platform-adaptive architecture using SwiftUI Scene-based structure.
 * Note: While UIKit delegate patterns would allow more direct handling of lifecycle events,
 * SwiftUI Scene approach enables cross-platform code sharing with platform-specific optimizations.
 */
@main
struct TranscriptTrimApp: App {
    @State private var appError: Error?
    @State private var showError = false
    @Environment(\.openWindow) private var openWindow
    
    var body: some Scene {
        WindowGroup(id: "main") {
            Group {
                #if os(iOS)
                NavigationView {
                    ContentView()
                        .navigationTitle("TranscriptTrim")
                        .navigationBarTitleDisplayMode(.inline)
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .accentColor(.blue)
                #else
                ContentView()
                    .frame(minWidth: 420, minHeight: 420)
                    .accentColor(.blue)
                #endif
            }
            // Direct alert modifier instead of custom modifier
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(appError?.localizedDescription ?? "An unknown error occurred")
            }
            .onReceive(NotificationCenter.default.publisher(for: .appError)) { notification in
                if let error = notification.object as? Error {
                    appError = error
                    showError = true
                }
            }
        }
        #if os(macOS)
        .windowStyle(DefaultWindowStyle())
        .windowToolbarStyle(UnifiedWindowToolbarStyle())
        .commands {
            CommandGroup(replacing: .newItem) {}  // Disable New Document menu item
            
            // TODO: This don't function
            CommandMenu("Transcript") {
                Button("Copy to Clipboard") {
                    NotificationCenter.default.post(name: .copyToClipboard, object: nil)
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                
                Button("Save as TXT file") {
                    NotificationCenter.default.post(name: .saveToFile, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])

                // Add explicit New Window command
                Button("New Window") {
                    openWindow(id: "main")
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])

                Divider()
                
                Button("Select VTT File") {
                    NotificationCenter.default.post(name: .selectFile, object: nil)
                }
                .keyboardShortcut("o", modifiers: [.command])
            }
            
            // Add About menu item in the app menu
            CommandGroup(replacing: .appInfo) {
                Button("About TranscriptTrim") {
                    NotificationCenter.default.post(name: .showAbout, object: nil)
                }
            }
        }
        #endif
    }
    
    // All UI configuration handled through SwiftUI modifiers directly
}

// No custom alert modifier needed - using SwiftUI's built-in alert

// MARK: - Notification Extensions

/**
 * Application-wide notification names
 *
 * Using a centralized extension avoids string literal repetition and provides
 * compiler validation for notification names across the codebase.
 */
extension Notification.Name {
    static let copyToClipboard = Notification.Name("copyToClipboard")
    static let saveToFile = Notification.Name("saveToFile")
    static let showAbout = Notification.Name("showAbout")
    static let selectFile = Notification.Name("selectFile")
    static let appError = Notification.Name("appError")
}

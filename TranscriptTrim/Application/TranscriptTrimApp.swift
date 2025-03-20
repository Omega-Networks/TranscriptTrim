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
 * The main entry point for the Transcript Trim application.
 * Sets up the app and initializes the root view.
 */
@main
struct TranscriptTrimApp: App {
    // State to track if the About view should be shown
    @State private var showAboutView = false
    
    var body: some Scene {
        // Primary window group with title
        WindowGroup("TranscriptTrim", id: "main-window") {
            ContentView()
                .frame(minWidth: 700, minHeight: 800)
            // Listen for the About notification
                .onReceive(NotificationCenter.default.publisher(for: .showAbout)) { _ in
                    showAboutView = true
                }
            // Present the About view as a sheet when needed
                .sheet(isPresented: $showAboutView) {
                    AboutView()
                }
        }
        .defaultSize(width: 900, height: 800)
#if os(macOS)
        .windowToolbarStyle(UnifiedWindowToolbarStyle())
        .commands {
            CommandGroup(replacing: .newItem) {}  // Disable New Document menu item
            
            // Window menu is automatically created by SwiftUI with WindowGroup
            
            CommandMenu("Transcript") {
                Button("Copy to Clipboard") {
                    NotificationCenter.default.post(name: .copyToClipboard, object: nil)
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                
                Button("Save as TXT") {
                    NotificationCenter.default.post(name: .saveToFile, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                
                Divider()
                
                // Add explicit New Window command
                Button("New Window") {
                    NSApp.sendAction(#selector(NSResponder.newWindowForTab(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
            
            // Add About menu item in the app menu
            CommandGroup(replacing: .appInfo) {
                Button("About TranscriptTrim") {
                    showAboutView = true  // Directly set the state instead of using notification
                }
            }
        }
#endif
    }
}

// Notification names for menu actions
extension Notification.Name {
    static let copyToClipboard = Notification.Name("copyToClipboard")
    static let saveToFile = Notification.Name("saveToFile")
    static let showAbout = Notification.Name("showAbout")
}

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
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 700, minHeight: 800)
        }
        #if os(macOS)
        .windowStyle(DefaultWindowStyle())
        .commands {
            CommandGroup(replacing: .newItem) {}  // Disable New Document menu item
            
            CommandMenu("Transcript") {
                Button("Copy to Clipboard") {
                    NotificationCenter.default.post(name: .copyToClipboard, object: nil)
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                
                Button("Save as TXT") {
                    NotificationCenter.default.post(name: .saveToFile, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
        }
        #endif
    }
    
}

// Notification names for menu actions
extension Notification.Name {
    static let copyToClipboard = Notification.Name("copyToClipboard")
    static let saveToFile = Notification.Name("saveToFile")
}

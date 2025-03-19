//
//  Utilities.swift
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
 * Contains various utility functions used throughout the app.
 */
class Utilities {
    /**
     * Copies text to the system clipboard.
     * Uses platform-specific APIs while maintaining cross-platform compatibility.
     *
     * - Parameter text: The text to copy to clipboard
     */
    static func copyToClipboard(_ text: String) {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        #else
        UIPasteboard.general.string = text
        #endif
    }
    
    /**
     * Gets a suggested output filename based on the input filename.
     * Replaces the original extension with ".txt"
     *
     * - Parameter inputFilename: Original filename
     * - Returns: Suggested output filename with .txt extension
     */
    static func getSuggestedOutputFilename(from inputFilename: String) -> String {
        // If filename is empty, use a default name
        if inputFilename.isEmpty {
            return "transcript.txt"
        }
        
        return "\(inputFilename).txt"
    }
}

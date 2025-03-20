//
//  Models.swift
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
 * Represents a single transcript entry with a speaker and their dialogue.
 */
struct Transcript: Identifiable, Equatable, Hashable {
    var id = UUID()
    var speaker: String
    var dialogue: String
    
    // Equatable conformance
    static func == (lhs: Transcript, rhs: Transcript) -> Bool {
        return lhs.id == rhs.id &&
               lhs.speaker == rhs.speaker &&
               lhs.dialogue == rhs.dialogue
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(speaker)
        hasher.combine(dialogue)
    }
}

/**
 * FileDocument implementation for text file system integration
 *
 * Provides bidirectional conversion between application data and system file formats:
 * - Read: Converts file data to in-memory string representation
 * - Write: Serializes processed content back to file system
 *
 * This implementation uses Swift's newer FileDocument protocol rather than
 * UIDocument subclassing, allowing integration with SwiftUI file handling
 * while maintaining separation from UIKit dependencies.
 */
struct TextDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    
    var text: String
    
    init(text: String) {
        self.text = text
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }
}

/**
 * Domain-specific error handling with recovery suggestions
 *
 * Implements the LocalizedError protocol to integrate with system-level
 * error presentation while adding application-specific context through:
 * - Categorized error types for programmatic handling
 * - User-friendly descriptions for display
 * - Actionable recovery suggestions
 *
 * This approach balances technical precision with UX considerations by
 * keeping error handling centralized rather than scattered throughout the app.
 */
enum AppError: Error, LocalizedError {
    case filePermissionDenied(String)
    case fileFormatInvalid(String)
    case fileReadError(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .filePermissionDenied(let details):
            return "Permission denied: \(details)"
        case .fileFormatInvalid(let details):
            return "Invalid file format: \(details)"
        case .fileReadError(let details):
            return "Error reading file: \(details)"
        case .unknown(let details):
            return "Unknown error: \(details)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .filePermissionDenied:
            return "Try saving the file to your Documents folder first, or select a different file."
        case .fileFormatInvalid:
            return "Please ensure the file contains either VTT format with <v> tags or text with Speaker: Dialogue format."
        case .fileReadError:
            return "Try selecting the file again, or check if it's being used by another application."
        case .unknown:
            return "Please try again or restart the application."
        }
    }
}

/**
 * Utility function to create a custom UTType for VTT files
 */
func createVTTType() -> UTType {
    // Try to get the system-defined type if available
    if let vttType = UTType(filenameExtension: "vtt") {
        return vttType
    }
    
    // Otherwise create a dynamic type
    return UTType(exportedAs: "com.webvtt.vtt",
                  conformingTo: .text)
}

// No UIKit color extensions needed - using pure SwiftUI

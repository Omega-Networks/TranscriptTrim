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
struct Transcript: Identifiable {
    var id = UUID()
    var speaker: String
    var dialogue: String
}

/**
 * Document type for exporting text files to the file system.
 * Conforms to FileDocument protocol for SwiftUI file export operations.
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

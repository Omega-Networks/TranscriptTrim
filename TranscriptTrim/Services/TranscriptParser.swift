//
//  TranscriptParser.swift
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
 * Specialized parser for WebVTT and transcript file formats
 *
 * Implements the Strategy pattern to handle multiple format types through:
 * - Format detection based on content structure
 * - Format-specific parsing algorithms
 * - Unified data model output regardless of input format
 *
 * This approach allows for future format support without modifying
 * consuming code, maintaining the open/closed principle.
 */
class TranscriptParser {
    /**
     * Parses content without requiring direct URL access.
     * This version helps avoid search-related issues in file pickers.
     *
     * - Parameters:
     *   - content: String content to parse
     *   - fileName: Optional file name for reference
     * - Returns: A tuple containing the transcript array and a status message
     */
    static func parse(content: String, fileName: String = "file") -> (transcripts: [Transcript], message: String) {
        // Check if the content is empty
        if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return ([], "Error: The file appears to be empty.")
        }
        
        // Parse the content based on detected format
        let transcripts = processContent(content)
        
        if transcripts.isEmpty {
            return ([], "Warning: No transcript entries found. The file may not be in a supported format. Please ensure it contains either '<v Speaker>Text</v>' or 'Speaker: Text' formats.")
        } else {
            return (transcripts, "Previewing file: \(fileName) - \(transcripts.count) entries found")
        }
    }
    
    /**
     * Parses a file at the given URL into an array of Transcript objects.
     * Handles both VTT and plain text formats automatically.
     * Enhanced with better error handling and permissions management.
     *
     * - Parameter url: URL of the transcript file to parse
     * - Returns: A tuple containing the transcript array and a status message
     */
    static func parse(url: URL) -> (transcripts: [Transcript], message: String) {
        do {
            // Start accessing security-scoped resource
            let canAccess = url.startAccessingSecurityScopedResource()
            
            // Make sure we stop accessing the resource at the end
            defer {
                if canAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            // Verify file is not in a restricted location
            guard url.isReadable else {
                return ([], "This file appears to be in a restricted location. Please move it to your Documents folder and try again.")
            }
            
            // Try to read the content with better error reporting
            let content: String
            do {
                content = try String(contentsOf: url, encoding: .utf8)
            } catch {
                // Try alternative encodings if UTF-8 fails
                if let data = try? Data(contentsOf: url) {
                    // Try common encodings
                    for encoding in [String.Encoding.ascii, .isoLatin1, .windowsCP1252] {
                        if let decodedContent = String(data: data, encoding: encoding) {
                            content = decodedContent
                            break
                        }
                    }
                    // If we reach here without assigning content, none of the encodings worked
                    throw NSError(domain: "com.omeganetworks.transcripttrim",
                                 code: 1001,
                                 userInfo: [NSLocalizedDescriptionKey: "File encoding not recognized. Try saving the file as UTF-8."])
                } else {
                    throw error
                }
            }
            
            // Parse the content based on detected format
            let transcripts = processContent(content)
            
            if transcripts.isEmpty {
                return ([], "Warning: No transcript entries found. The file may not be in a supported format. Please ensure it contains either '<v Speaker>Text</v>' or 'Speaker: Text' formats.")
            } else {
                return (transcripts, "Previewing file: \(url.lastPathComponent) - \(transcripts.count) entries found")
            }
        } catch let error as NSError {
            // Handle permission errors specifically with better guidance
            if error.domain == NSCocoaErrorDomain && error.code == 257 {
                return ([], "Permission denied: Please select a file from Documents or Downloads folder. iOS apps can only access files in specific locations or those explicitly shared with the app.")
            } else if error.domain == NSCocoaErrorDomain && (error.code == 260 || error.code == 258) {
                return ([], "The file couldn't be opened because it doesn't exist or was moved. Please select the file again.")
            } else {
                return ([], "Error reading the file: \(error.localizedDescription) (Error code: \(error.code))")
            }
        } catch {
            return ([], "Error reading the file: \(error.localizedDescription)")
        }
    }
    
    /**
     * Determines the format of the content and routes to the appropriate parser.
     *
     * - Parameter content: String content of the transcript file
     * - Returns: Array of parsed Transcript objects
     */
    private static func processContent(_ content: String) -> [Transcript] {
        // Check if the content is empty
        if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return []
        }
        
        // First try to process the file as a VTT file with <v> tags
        if content.contains("<v ") {
            return processVTTFormat(content)
        } else {
            // Otherwise try to process as text format with "Speaker: Text" format
            return processTextFormat(content)
        }
    }
    
    /**
     * Processes WebVTT format with specialized tag handling
     *
     * Uses a two-phase parsing strategy:
     * 1. Primary regex-based extraction for standard compliant VTT
     * 2. Fallback manual string operations for edge cases and non-standard formats
     *
     * This approach handles the wide variation in WebVTT implementations
     * while maintaining performance for well-formed content.
     *
     * - Parameter content: String content in VTT format
     * - Returns: Array of parsed Transcript objects
     */
    private static func processVTTFormat(_ content: String) -> [Transcript] {
        let lines = content.split(separator: "\n")
        var transcripts: [Transcript] = []
        
        // Create regex pattern to match <v Speaker>Text</v> pattern
        do {
            // Improved regex pattern that's more flexible with whitespace
            let pattern = #"<v\s+([^>]+)>(.*?)</v>"#
            let regex = try NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
            
            // Process each line
            for line in lines {
                let lineStr = String(line)
                let range = NSRange(lineStr.startIndex..<lineStr.endIndex, in: lineStr)
                
                // Look for matches with the regex pattern
                let matches = regex.matches(in: lineStr, options: [], range: range)
                
                for match in matches {
                    if match.numberOfRanges >= 3,
                       let speakerRange = Range(match.range(at: 1), in: lineStr),
                       let dialogueRange = Range(match.range(at: 2), in: lineStr) {
                        
                        let speaker = String(lineStr[speakerRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                        let dialogue = String(lineStr[dialogueRange])
                            .replacingOccurrences(of: "\n", with: " ")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if !dialogue.isEmpty {
                            transcripts.append(Transcript(speaker: speaker, dialogue: dialogue))
                        }
                    }
                }
                
                // If no regex match, try the basic <v Speaker>Text</v> format manually
                if matches.isEmpty && lineStr.contains("<v ") && lineStr.contains("</v>") {
                    if let speakerStart = lineStr.range(of: "<v ")?.upperBound,
                       let speakerEnd = lineStr.range(of: ">", range: speakerStart..<lineStr.endIndex)?.lowerBound,
                       let dialogueStart = lineStr.range(of: ">", range: speakerStart..<lineStr.endIndex)?.upperBound,
                       let dialogueEnd = lineStr.range(of: "</v>")?.lowerBound {
                        
                        let speaker = String(lineStr[speakerStart..<speakerEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
                        let dialogue = String(lineStr[dialogueStart..<dialogueEnd])
                            .replacingOccurrences(of: "\n", with: " ")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if !dialogue.isEmpty {
                            transcripts.append(Transcript(speaker: speaker, dialogue: dialogue))
                        }
                    }
                }
            }
        } catch {
            print("Regex error: \(error)")
        }
        
        return transcripts
    }
    
    /**
     * Processes plain text format with "Speaker: Text" pattern
     * Enhanced with more flexible text parsing
     *
     * - Parameter content: String content in text format
     * - Returns: Array of parsed Transcript objects
     */
    private static func processTextFormat(_ content: String) -> [Transcript] {
        // Try with different paragraph separators
        let paragraphs: [String]
        if content.contains("\n\n") {
            paragraphs = content.split(separator: "\n\n").map(String.init)
        } else {
            paragraphs = content.split(separator: "\n").map(String.init)
        }
        
        var transcripts: [Transcript] = []
        
        for paragraph in paragraphs {
            let lineStr = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty lines
            if lineStr.isEmpty {
                continue
            }
            
            // Try to extract speaker and dialogue
            if let colonIndex = lineStr.firstIndex(of: ":") {
                let speaker = String(lineStr[..<colonIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
                let dialogueStart = lineStr.index(after: colonIndex)
                let dialogue = String(lineStr[dialogueStart...]).trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !speaker.isEmpty && !dialogue.isEmpty {
                    transcripts.append(Transcript(speaker: speaker, dialogue: dialogue))
                }
            } else {
                // Try an alternative format like "Speaker - Text"
                if let dashIndex = lineStr.firstIndex(of: "-") {
                    let possibleSpeaker = String(lineStr[..<dashIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let dialogueStart = lineStr.index(after: dashIndex)
                    let possibleDialogue = String(lineStr[dialogueStart...]).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Only consider this a match if possibleSpeaker is a reasonable length for a name
                    if !possibleSpeaker.isEmpty && possibleSpeaker.count < 30 && !possibleDialogue.isEmpty {
                        transcripts.append(Transcript(speaker: possibleSpeaker, dialogue: possibleDialogue))
                    }
                }
            }
        }
        
        return transcripts
    }
    
    /**
     * Prepares transcript data for export, removing duplicate speaker names
     * for consecutive entries from the same speaker.
     *
     * - Parameter transcripts: Array of Transcript objects
     * - Returns: Formatted string for export
     */
    static func prepareForExport(_ transcripts: [Transcript]) -> String {
        var exportString = ""
        var lastSpeaker = ""
        
        for (index, item) in transcripts.enumerated() {
            let dialogue = item.dialogue.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if item.speaker == lastSpeaker {
                // Skip speaker name for consecutive lines from same speaker
                exportString += dialogue + "\n"
            } else {
                // Add a line break between different speakers but not before the first one
                if index > 0 {
                    exportString += "\n"
                }
                
                // Include speaker name for new speakers
                exportString += "\(item.speaker): \(dialogue)\n"
                lastSpeaker = item.speaker
            }
        }
        return exportString
    }
}

// Extension to test if a URL is readable (helps with permission checks)
extension URL {
    var isReadable: Bool {
        // On iOS, startAccessingSecurityScopedResource is needed
        #if os(iOS)
        let canAccess = self.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                self.stopAccessingSecurityScopedResource()
            }
        }
        #endif
        
        return FileManager.default.isReadableFile(atPath: self.path)
    }
}

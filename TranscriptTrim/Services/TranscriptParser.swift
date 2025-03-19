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
 * Handles parsing different transcript file formats and converting them to structured data.
 */
class TranscriptParser {
    /**
     * Parses a file at the given URL into an array of Transcript objects.
     * Handles both VTT and plain text formats automatically.
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
            
            // Try to read the content
            let content = try String(contentsOf: url, encoding: .utf8)
            
            // Parse the content based on detected format
            let transcripts = processContent(content)
            
            if transcripts.isEmpty {
                return ([], "Warning: No transcript entries found. The file may not be in a supported format.")
            } else {
                return (transcripts, "Previewing file: \(url.lastPathComponent) - \(transcripts.count) entries found")
            }
        } catch let error as NSError {
            // Handle permission errors specifically
            if error.domain == NSCocoaErrorDomain && error.code == 257 {
                return ([], "Permission denied: Please move the file to Documents or Desktop folder and try again.")
            } else {
                return ([], "Error reading the file: \(error.localizedDescription)")
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
        // First try to process the file as a VTT file with <v> tags
        if content.contains("<v ") {
            return processVTTFormat(content)
        } else {
            // Otherwise try to process as text format with "Speaker: Text" format
            return processTextFormat(content)
        }
    }
    
    /**
     * Processes VTT format with <v> tags
     *
     * - Parameter content: String content in VTT format
     * - Returns: Array of parsed Transcript objects
     */
    private static func processVTTFormat(_ content: String) -> [Transcript] {
        let lines = content.split(separator: "\n")
        var transcripts: [Transcript] = []
        
        // Create regex pattern to match <v Speaker>Text</v> pattern
        do {
            let pattern = #"<v ([^>]+)>(.*?)</v>"#
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
                        
                        let speaker = String(lineStr[speakerRange])
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
                        
                        let speaker = String(lineStr[speakerStart..<speakerEnd])
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
     *
     * - Parameter content: String content in text format
     * - Returns: Array of parsed Transcript objects
     */
    private static func processTextFormat(_ content: String) -> [Transcript] {
        let lines = content.split(separator: "\n\n") // Split by double newlines
        var transcripts: [Transcript] = []
        
        for line in lines {
            let lineStr = String(line).trimmingCharacters(in: .whitespacesAndNewlines)
            
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

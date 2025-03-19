//
//  TokenAnalyzer.swift
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

import Foundation

/**
 * Provides functionality for analyzing token counts in different text formats.
 * Uses a simplified estimation method with disclaimers.
 */
class TokenAnalyzer {
    
    /// Analysis result containing token counts and reduction metrics
    struct TokenAnalysisResult {
        let originalTokenCount: Int
        let processedTokenCount: Int
        let tokensReduced: Int
        let percentageReduction: Double
        let modelType: TokenizerModelType
        
        /// Formatted percentage reduction (e.g., "85.2%")
        var formattedPercentageReduction: String {
            return String(format: "%.1f%%", percentageReduction)
        }
        
        /// Formatted token counts with thousands separators
        var formattedOriginalTokenCount: String {
            return formatNumber(originalTokenCount)
        }
        
        var formattedProcessedTokenCount: String {
            return formatNumber(processedTokenCount)
        }
        
        var formattedTokensReduced: String {
            return formatNumber(tokensReduced)
        }
        
        /// Helper to format numbers with thousands separators
        private func formatNumber(_ number: Int) -> String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.groupingSeparator = ","
            return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
        }
    }
    
    /// Types of tokenizer models available
    enum TokenizerModelType: String, CaseIterable, Identifiable {
        case gpt4 = "GPT-4"
        case gpt35 = "GPT-3.5"
        case claude = "Claude"
        case standard = "Standard"
        
        var id: String { self.rawValue }
        
        /// Price per 1000 tokens (input tokens)
        var pricePerThousandTokens: Double {
            switch self {
            case .gpt4:
                return 0.03
            case .gpt35:
                return 0.0015
            case .claude:
                return 0.008
            case .standard:
                return 0.02  // Average price
            }
        }
        
        /// Description for UI display
        var description: String {
            switch self {
            case .gpt4:
                return "OpenAI GPT-4 ($0.03 per 1K tokens)"
            case .gpt35:
                return "OpenAI GPT-3.5 ($0.0015 per 1K tokens)"
            case .claude:
                return "Anthropic Claude ($0.008 per 1K tokens)"
            case .standard:
                return "Standard Estimate ($0.02 per 1K tokens)"
            }
        }
    }
    
    /**
     * Analyzes the difference in token counts between original and processed text.
     *
     * - Parameters:
     *   - originalText: The original VTT or transcript text
     *   - processedText: The cleaned and formatted text
     *   - modelType: The tokenizer model type to use for pricing
     * - Returns: A TokenAnalysisResult with token counts and reduction metrics
     */
    static func analyzeTokenReduction(
        originalText: String,
        processedText: String,
        modelType: TokenizerModelType = .gpt4
    ) -> TokenAnalysisResult {
        let originalTokenCount = estimateTokenCount(text: originalText)
        let processedTokenCount = estimateTokenCount(text: processedText)
        
        let tokensReduced = originalTokenCount - processedTokenCount
        let percentageReduction = originalTokenCount > 0
            ? (Double(tokensReduced) / Double(originalTokenCount)) * 100
            : 0.0
        
        return TokenAnalysisResult(
            originalTokenCount: originalTokenCount,
            processedTokenCount: processedTokenCount,
            tokensReduced: tokensReduced,
            percentageReduction: percentageReduction,
            modelType: modelType
        )
    }
    
    /**
     * Estimates the number of tokens in the given text, with special handling for VTT files.
     * While still an approximation, this attempts to better account for hexadecimal IDs.
     *
     * - Parameter text: The text to analyze
     * - Returns: Estimated token count
     */
    static func estimateTokenCount(text: String) -> Int {
        // First, handle edge cases
        if text.isEmpty {
            return 0
        }
        
        // Detect if this is a VTT file
        let isVTT = text.contains("<v ") && text.contains("</v>")
        
        // Start with a base token count
        var tokenCount = 0
        
        if isVTT {
            // Find and separately count hexadecimal IDs in the format "3cf19358-ed0f-42d3-a2ac-c5f5c5de4be0/68-0"
            // Pattern to match hex IDs with optional suffixes
            let hexIDPattern = #"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}(/\d+-\d+)?"#
            
            do {
                let regex = try NSRegularExpression(pattern: hexIDPattern, options: [])
                let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
                let matches = regex.matches(in: text, options: [], range: nsRange)
                
                // Create a mutable copy of the original text
                var remainingText = text
                
                // Process each hex ID
                for match in matches.reversed() {
                    if let range = Range(match.range, in: text) {
                        // Extract the hex ID
                        let hexID = String(text[range])
                        
                        // Count tokens for the hex ID based on OpenAI's pattern (approximately 1 token per 2 chars)
                        let hexTokens = max(1, hexID.count / 2)
                        tokenCount += hexTokens
                        
                        // Remove the hex ID from the remaining text to avoid double counting
                        if let matchRange = Range(match.range, in: remainingText) {
                            remainingText.removeSubrange(matchRange)
                        }
                    }
                }
                
                // Count tokens for the remaining text using a standard approach
                tokenCount += remainingText.count / 4
                
            } catch {
                // Fallback if regex fails
                tokenCount = text.count / 4
            }
        } else {
            // Standard token counting for non-VTT files
            tokenCount = text.count / 4
        }
        
        // Ensure at least 1 token
        return max(1, tokenCount)
    }
    
    /**
     * Calculates potential cost savings based on token reduction
     *
     * - Parameters:
     *   - result: The token analysis result
     * - Returns: Estimated cost savings in USD
     */
    static func calculateCostSavings(for result: TokenAnalysisResult) -> Double {
        let tokensSavedInThousands = Double(result.tokensReduced) / 1000.0
        return tokensSavedInThousands * result.modelType.pricePerThousandTokens
    }
}

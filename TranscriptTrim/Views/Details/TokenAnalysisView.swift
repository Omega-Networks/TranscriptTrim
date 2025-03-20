//
//  TokenAnalysisView.swift
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
 * TokenAnalysisView displays token reduction statistics with interactive elements
 *
 * This view uses several advanced SwiftUI patterns:
 * - Collapsible/expandable content with animations
 * - Single source of truth with observational state values
 * - Conditional content rendering for contextual information density
 * - Cross-platform layout adaptations with consistent visual hierarchy
 */
struct TokenAnalysisView: View {
    let result: TokenAnalyzer.TokenAnalysisResult
    let costSavings: Double
    
    @State private var selectedModel: TokenAnalyzer.TokenizerModelType
    @State private var showAllModels: Bool = false
    @State private var isExpanded: Bool = false
    
    init(result: TokenAnalyzer.TokenAnalysisResult, costSavings: Double) {
        self.result = result
        self.costSavings = costSavings
        // Initialize the state property with the result's model type
        _selectedModel = State(initialValue: result.modelType)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header row - always visible
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    // Left side: Icon and title
                    HStack(spacing: 8) {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.green)
                        
                        Text("Token Analysis")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    // Right side: Reduction percentage and expand/collapse icon
                    HStack(spacing: 8) {
                        Text("\(result.formattedPercentageReduction) Reduction")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.secondary)
                            .font(.caption)
                            .animation(.easeInOut, value: isExpanded)
                    }
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .background(Color.gray.opacity(0.15))
            .cornerRadius(10)
            
            // Expandable details section
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    // Model selection
                    HStack {
                        Text("Model:")
                            .foregroundColor(.secondary)
                        
                        Picker("Model", selection: $selectedModel) {
                            ForEach(TokenAnalyzer.TokenizerModelType.allCases) { model in
                                Text(model.description).tag(model)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button(action: {
                            showAllModels.toggle()
                        }) {
                            Image(systemName: showAllModels ? "info.circle.fill" : "info.circle")
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.top, 4)
                    
                    // Model comparison if enabled
                    if showAllModels {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Token Count by Model:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            ForEach(TokenAnalyzer.TokenizerModelType.allCases) { model in
                                HStack {
                                    Text(model.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 80, alignment: .leading)
                                    
                                    Text("≈ \(formatNumber(estimatedTokensForModel(model)))")
                                        .font(.caption)
                                        .foregroundColor(model == selectedModel ? .primary : .secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                    }
                    
                    // Divider
                    Divider()
                        .padding(.vertical, 2)
                    
                    // Detailed metrics
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Original Tokens:")
                                .foregroundColor(.secondary)
                                .frame(width: 140, alignment: .leading)
                            Text(result.formattedOriginalTokenCount)
                                .bold()
                        }
                        
                        HStack {
                            Text("Processed Tokens:")
                                .foregroundColor(.secondary)
                                .frame(width: 140, alignment: .leading)
                            Text(result.formattedProcessedTokenCount)
                                .bold()
                        }
                        
                        HStack {
                            Text("Tokens Reduced:")
                                .foregroundColor(.secondary)
                                .frame(width: 140, alignment: .leading)
                            Text(result.formattedTokensReduced)
                                .bold()
                                .foregroundColor(.green)
                        }
                        
                        HStack {
                            Text("Est. Cost Savings:")
                                .foregroundColor(.secondary)
                                .frame(width: 140, alignment: .leading)
                            Text(String(format: "$%.2f", costSavingsForModel(selectedModel)))
                                .bold()
                                .foregroundColor(.green)
                        }
                    }
                    
                    // Explanatory notes
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Based on \(selectedModel.rawValue) pricing of $\(String(format: "%.5f", selectedModel.pricePerThousandTokens)) per token")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(alignment: .top, spacing: 4) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Token counts are rough estimates only")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("For exact counts, use OpenAI's tokenizer: platform.openai.com/tokenizer")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // Helper methods
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    // Estimate tokens for a different model based on the original count
    private func estimatedTokensForModel(_ model: TokenAnalyzer.TokenizerModelType) -> Int {
        // This is a simplified approximation - in reality, different models tokenize differently
        let adjustmentFactor: Double
        
        switch model {
        case .gpt4:
            adjustmentFactor = 1.0  // Base model
        case .gpt35:
            adjustmentFactor = 1.05  // GPT-3.5 might produce slightly more tokens
        case .claude:
            adjustmentFactor = 0.98  // Claude might be slightly more efficient
        case .standard:
            adjustmentFactor = 1.1   // Standard estimate is more conservative
        }
        
        return Int(Double(result.processedTokenCount) * adjustmentFactor)
    }
    
    // Calculate cost savings for a specific model
    private func costSavingsForModel(_ model: TokenAnalyzer.TokenizerModelType) -> Double {
        let tokensSavedInThousands = Double(result.tokensReduced) / 1000.0
        return tokensSavedInThousands * model.pricePerThousandTokens
    }
}

/**
 * Preview provider for TokenAnalysisView
 */
struct TokenAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        let result = TokenAnalyzer.TokenAnalysisResult(
            originalTokenCount: 230000,
            processedTokenCount: 37000,
            tokensReduced: 193000,
            percentageReduction: 83.9,
            modelType: .gpt4
        )
        TokenAnalysisView(result: result, costSavings: 5.79)
            .previewLayout(.sizeThatFits)
            .padding()
            .environment(\.colorScheme, .light)
        
        TokenAnalysisView(result: result, costSavings: 5.79)
            .previewLayout(.sizeThatFits)
            .padding()
            .environment(\.colorScheme, .dark)
    }
}

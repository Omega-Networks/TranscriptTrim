//
//  TranscriptDetailView.swift
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
 * Detail view for displaying the full content of a transcript entry.
 * Adapts to both iOS and macOS platforms.
 */
struct TranscriptDetailView: View {
    let transcript: Transcript
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        #if os(iOS)
        NavigationView {
            detailContent
                .navigationBarTitle("Transcript Detail", displayMode: .inline)
                .navigationBarItems(trailing: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                })
        }
        #else
        // macOS version
        VStack {
            HStack {
                Spacer()
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
                .padding()
            }
            
            detailContent
        }
        .frame(width: 500, height: 400)
        #endif
    }
    
    /// The main content of the detail view, shared between platforms
    var detailContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Speaker:")
                    .font(.caption)
                    .foregroundColor(.accentColor)
                
                Text(transcript.speaker)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
            }
            .padding(.bottom, 8)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Dialogue:")
                    .font(.caption)
                    .foregroundColor(.accentColor)
                
                Text(transcript.dialogue)
                    .font(.body)
                    .lineSpacing(4)
                    .padding()
                    .background(.secondary)
                    .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/**
 * Preview provider for TranscriptDetailView
 */
struct TranscriptDetailView_Previews: PreviewProvider {
    static var previews: some View {
        TranscriptDetailView(transcript: Transcript(speaker: "Leon Cassidy", dialogue: "Our great love for Wellington drives everything we do."))
    }
}

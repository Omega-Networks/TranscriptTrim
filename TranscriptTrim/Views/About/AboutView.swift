//
//  AboutView.swift
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
 * About view for the application.
 * Displays app information, copyright details, and licensing information.
 */
struct AboutView: View {
    // App information
    private let appName = "TranscriptTrim"
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    private let copyright = "Copyright © 2025 Omega Networks Ltd, New Zealand"
    private let companyDescription = "A SwiftUI application that dramatically reduces token counts in transcript files by intelligently cleaning and formatting VTT transcripts."
    
    // Environment for dismissing the view when used as a sheet
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // App icon and version info
            VStack(spacing: 10) {
                // App icon using AppIconManager
                AppIconManager.getAboutViewIcon()
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 69, height: 69)
                    .cornerRadius(16)
                    .padding(.top, 20)
                
                // App name and version
                Text(appName)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Version \(appVersion) (\(buildNumber))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 5)
            }
            
            // App description
            Text(companyDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 24)
            
            // Divider
            Divider()
                .padding(.horizontal, 20)
                .padding(.vertical, 12  )
            
            // Copyright information
            VStack(spacing: 6) {
                Text(copyright)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                
                Text("Licensed under the MIT License with additional conditions")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
            }
            
            // License details
            VStack(alignment: .leading, spacing: 6) {
                Text("License Details:")
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .top) {
                    Text("•")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Text("If modified, proper attribution to Omega Networks Ltd must be included")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                HStack(alignment: .top) {
                    Text("•")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Text("If sold or monetized, a commercial license must be obtained from Omega Networks Ltd")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 32)
            .padding(.vertical, 4)
            
            Spacer()
            
            // Close button
            Button("Close") {
                presentationMode.wrappedValue.dismiss()
            }
            .background(Color.gray.opacity(0.2))
            .cornerRadius(6)
            .padding(.bottom, 16)
        }
        .frame(width: 380, height: 380)
    }
}

/**
 * Handles loading the app icon with appropriate fallback
 */
extension Image {
    init(appIcon: String) {
        #if os(macOS)
        if let appIcon = NSImage(named: appIcon) {
            self.init(nsImage: appIcon)
        } else {
            self.init(systemName: "text.bubble.fill")
        }
        #else
        if UIImage(named: appIcon) != nil {
            self.init(appIcon)
        } else {
            self.init(systemName: "text.bubble.fill")
        }
        #endif
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}

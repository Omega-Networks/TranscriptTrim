//
//  AppIconManager.swift
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
 * Manages app icon loading and sizing for the About view.
 * Provides a consistent appearance across platforms.
 */
struct AppIconManager {
    /// Standard icon sizes used by Apple
    enum IconSize: Int, CaseIterable {
        case size16 = 16
        case size32 = 32
        case size64 = 64
        case size128 = 128
        case size256 = 256
        case size512 = 512
        case size1024 = 1024
        
        /// Returns the appropriate icon size for the About view
        static var aboutViewSize: IconSize {
            #if os(macOS)
            return .size128
            #else
            return .size64
            #endif
        }
        
        /// Returns the icon name with size
        var iconName: String {
            return "AppIcon-\(self.rawValue)x\(self.rawValue)"
        }
    }
    
    /**
     * Gets the appropriate app icon for the About view.
     * Returns a system icon if app icon is not found.
     */
    static func getAboutViewIcon() -> Image {
        let size = IconSize.aboutViewSize
        
        #if os(macOS)
        if let appIcon = NSImage(named: size.iconName) {
            return Image(nsImage: appIcon)
        } else if let appIcon = NSImage(named: "AppIcon") {
            return Image(nsImage: appIcon)
        } else {
            // Fixed: Removed forced type cast that was causing crashes
            return Image(systemName: "text.bubble.fill")
                .foregroundColor(.blue) as! Image
        }
        #else
        if let _ = UIImage(named: size.iconName) {
            return Image(size.iconName)
        } else if let _ = UIImage(named: "AppIcon") {
            return Image("AppIcon")
        } else {
            // Fixed: Removed forced type cast that was causing crashes
            return Image(systemName: "text.bubble.fill")
                .foregroundColor(.blue) as! Image
        }
        #endif
    }
}

/**
 * Extension to easily get the app icon in views
 */
extension View {
    func withAppIcon(size: CGFloat) -> some View {
        return self.overlay(
            AppIconManager.getAboutViewIcon()
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        )
    }
}

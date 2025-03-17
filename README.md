# Transcript Trim

A Swift application that dramatically reduces token counts in transcript files by intelligently cleaning and formatting VTT transcripts.

## Value Proposition

**Transform your transcripts, slash your costs:** Transcript Trim reduces token counts by 80-85%, potentially saving thousands in AI processing costs while enabling more effective analysis:

- **Massive Token Reduction:** Typically reduces a 2.5-hour transcript from 230,000+ tokens to just 37,000
- **Direct Cost Savings:** Pay as little as 15% of your original AI processing costs
- **Context Window Optimization:** Fit entire long transcripts within AI model context windows
- **More Comprehensive Analysis:** Process 5-6x more content within the same token budget

Perfect for researchers, content creators, and businesses working with AI systems that charge by token or have context limitations.

## Features

- Import VTT files and transcript text files
- Display parsed transcripts with speaker attribution
- Format transcripts by removing duplicate speaker tags
- Export clean transcripts as text files
- Copy formatted transcripts to clipboard
- Cross-platform support for macOS and iOS

## Supported File Formats

- **VTT Files:** Parses WebVTT files with `<v speaker>text</v>` format
- **Text Files:** Parses text files with `Speaker: Text` format

## Usage

1. Click "Select .vtt file" to choose a VTT or text file
2. View the parsed transcript in the list
3. Tap/click any entry to view full details
4. Use "Copy to Clipboard" to copy the formatted transcript
5. Use "Save as TXT" to export the transcript as a text file

## Project Structure

The app is organized into several modular components:

- **Models.swift:** Data models for transcript entries and document handling
- **TranscriptParser.swift:** Logic for parsing VTT and text formats
- **TranscriptDetailView.swift:** UI for detailed transcript view
- **Utilities.swift:** Helper functions for various operations
- **ContentView.swift:** Main app UI and interaction logic
- **TranscriptTrimApp.swift:** App entry point and configuration

## Requirements

- iOS 14.0+ / macOS 11.0+
- Swift 5.3+
- Xcode 12.0+

## Implementation Details

The app uses SwiftUI for the user interface and is designed with cross-platform compatibility in mind. It handles various edge cases including:

- Permission issues with file access
- Different VTT file formats
- Platform-specific clipboard operations
- Proper navigation on both iOS and macOS

The parser intelligently removes duplicate speaker labels in consecutive entries to produce cleaner output with significantly lower token counts, making transcripts more suitable for AI processing and analysis.
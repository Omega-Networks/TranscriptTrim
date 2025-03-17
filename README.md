# Transcript Trim

A Swift application for parsing and cleaning VTT transcript files.

## Features

- Import VTT files and transcript text files
- Display parsed transcripts with speaker attribution
- Format transcripts by removing duplicate speaker tags
- Export clean transcripts as text files
- Copy formatted transcripts to clipboard
- Cross-platform support for macOS and iOS

## Project Structure

The app is organized into several modular components:

- **Models.swift**: Data models for transcript entries and document handling
- **TranscriptParser.swift**: Logic for parsing VTT and text formats
- **TranscriptDetailView.swift**: UI for detailed transcript view
- **Utilities.swift**: Helper functions for various operations
- **ContentView.swift**: Main app UI and interaction logic
- **TranscriptTrimApp.swift**: App entry point and configuration

## Supported File Formats

- **VTT Files**: Parses WebVTT files with `<v speaker>text</v>` format
- **Text Files**: Parses text files with `Speaker: Text` format

## Usage

1. Click "Select .vtt file" to choose a VTT or text file
2. View the parsed transcript in the list
3. Tap/click any entry to view full details
4. Use "Copy to Clipboard" to copy the formatted transcript
5. Use "Save as TXT" to export the transcript as a text file

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

The parser removes duplicate speaker labels in consecutive entries to produce cleaner output with lower token counts.

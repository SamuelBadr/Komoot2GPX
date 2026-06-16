# Komoot2GPX

Download GPX files from Komoot tours on iOS.

## Features

- **Paste & Download**: Copy a Komoot tour link and download the GPX file
- **Share Extension**: Share directly from the Komoot app
- **Tour History**: Keep track of all downloaded tours
- **Smart URL Parsing**: Handles tour URLs, smarttour URLs, and tracking parameters
- **Error Handling**: Clear messages for private tours, network errors, etc.

## Installation

1. Open `Komoot2GPX.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Build and run on your iPhone (⌘R)

### App Groups Setup (Required for Share Extension)

1. Select **Komoot2GPX** target → Signing & Capabilities → + Capability → **App Groups**
2. Add: `group.com.komoot2gpx.app`
3. Select **ShareExtension** target → Signing & Capabilities → + Capability → **App Groups**
4. Check: `group.com.komoot2gpx.app`
5. Rebuild and install

## Usage

### Method 1: Paste & Download

1. Open Komoot app and find a tour
2. Tap **Share** → **Copy Link**
3. Open Komoot2GPX app
4. Paste the link in the text field
5. Tap **Download GPX** or press Go

### Method 2: Share Extension

1. Open Komoot app and find a tour
2. Tap **Share**
3. Select **Komoot2GPX** from the share sheet
4. Wait for download to complete
5. Open Komoot2GPX app → **Downloads** tab to access the file

## Project Structure

```
Komoot2GPX/
├── Komoot2GPX.xcodeproj
├── Komoot2GPX/              # Main app
│   ├── ContentView.swift
│   ├── Komoot2GPXApp.swift
│   ├── KomootDownloader.swift
│   ├── GPXBuilder.swift
│   ├── Models/
│   └── Views/
├── ShareExtension/          # Share extension
│   ├── ShareViewController.swift
│   ├── KomootDownloader.swift
│   └── GPXBuilder.swift
└── Komoot2GPXTests/         # Unit tests
```

## Requirements

- iOS 27.0+
- Xcode 27.0+
- Swift 5.0+

## License

MIT

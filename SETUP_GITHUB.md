# GitHub Repository Setup Instructions

Due to a folder reorganization issue, please follow these steps to properly initialize the repository:

## Option 1: Quick Setup (Recommended)

```bash
cd /Users/samuel/Komoot2GPX

# Initialize git
git init
git branch -m main

# Add all files
git add -A

# Create initial commit
git commit -m "Initial commit: Komoot2GPX v0.1 - iOS 27 Liquid Glass compliant"

# Add your GitHub remote (replace YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/Komoot2GPX.git

# Push to GitHub
git push -u origin main
```

## Option 2: Create via GitHub Website

1. Go to https://github.com/new
2. Repository name: `Komoot2GPX`
3. Description: "Download GPX files from Komoot tours on iOS"
4. Choose: Public or Private
5. DO NOT initialize with README, .gitignore, or license
6. Click "Create repository"
7. Follow the push commands shown on GitHub

## Project Structure

```
Komoot2GPX/
├── Komoot2GPX.xcodeproj/      # Xcode project
├── Komoot2GPX/                 # Main app source
│   ├── ContentView.swift
│   ├── Komoot2GPXApp.swift
│   ├── KomootDownloader.swift
│   ├── GPXBuilder.swift
│   ├── Models/
│   │   ├── TourRecord.swift
│   │   ├── TourHistoryManager.swift
│   │   └── KomootURLNormalizer.swift
│   └── Views/
│       ├── HistoryView.swift
│       └── TourRow.swift
├── Komoot2GPXTests/            # Unit tests
├── ShareExtension/             # Share extension
├── README.md                   # Project documentation
├── ROADMAP.md                  # Future development
├── iOS27_COMPLIANCE.md        # Design compliance
└── .gitignore                  # Git ignore rules
```

## Required Files to Restore

The following files need to be restored from your Xcode build or backups:

- `Komoot2GPX/Komoot2GPXApp.swift`
- `Komoot2GPX/ContentView.swift`
- `Komoot2GPX/KomootDownloader.swift`
- `Komoot2GPX/GPXBuilder.swift`
- `Komoot2GPX/Models/TourRecord.swift`
- `Komoot2GPX/Models/TourHistoryManager.swift`
- `Komoot2GPX/Models/KomootURLNormalizer.swift`
- `Komoot2GPX/Views/HistoryView.swift`
- `Komoot2GPX/Views/TourRow.swift`

These files should be available in your Xcode DerivedData folder or from the app that's currently installed on your device.

## Recommended README Content

See the existing `README.md` file for project documentation.

## License

Consider adding an MIT or Apache 2.0 license file.

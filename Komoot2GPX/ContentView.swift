import SwiftUI

struct ShareableFile: Identifiable {
    let id = UUID()
    let url: URL
}

struct ContentView: View {
    @State private var urlInput = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var shareFile: ShareableFile?
    @State private var tourName: String?
    @FocusState private var isFocused: Bool
    
    var body: some View {
        TabView {
            downloadTab
                .tabItem {
                    Label("Download", systemImage: "arrow.down.circle.fill")
                }
            
            HistoryView()
                .tabItem {
                    Label("Downloads", systemImage: "folder.fill")
                }
        }
        .sheet(item: $shareFile) { file in
            ShareSheet(items: [file.url]) { _ in
                shareFile = nil
            }
        }
        .task {
            await scanForSharedFiles()
        }
    }
    
    private var downloadTab: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    HeroSection()
                    InputSection(urlInput: $urlInput, isFocused: $isFocused, isLoading: isLoading, onDownload: download)
                    ShareHintSection()
                    StatusSection(errorMessage: errorMessage, tourName: tourName)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Komoot2GPX")
            .navigationBarTitleDisplayMode(.inline)
            .contentShape(Rectangle())
            .onTapGesture {
                isFocused = false
            }
        }
    }
    
    private func scanForSharedFiles() async {
        let fileManager = FileManager.default
        
        if let sharedURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.komoot2gpx.app") {
            do {
                let contents = try fileManager.contentsOfDirectory(at: sharedURL, includingPropertiesForKeys: [.isRegularFileKey])
                for fileURL in contents.filter({ $0.pathExtension == "gpx" }) {
                    await addFileToHistory(fileURL)
                }
            } catch {}
        }
    }
    
    private func addFileToHistory(_ fileURL: URL) async {
        let filename = fileURL.lastPathComponent
        if TourHistoryManager.shared.tours.contains(where: { $0.filename == filename }) {
            return
        }
        
        let tourID = filename.components(separatedBy: "_").first ?? "unknown"
        let name = filename
            .replacingOccurrences(of: "\(tourID)_", with: "")
            .replacingOccurrences(of: ".gpx", with: "")
            .replacingOccurrences(of: "_", with: " ")
        
        var coordinateCount = 0
        if let gpxContent = try? String(contentsOf: fileURL, encoding: .utf8),
           let coordinates = parseGPXCoordinates(from: gpxContent) {
            coordinateCount = coordinates.count
        }
        
        let komootURL = KomootURLNormalizer.constructURL(tourID: tourID, shareToken: nil)
        
        await MainActor.run {
            TourHistoryManager.shared.addTour(
                id: tourID,
                name: name,
                coordinateCount: coordinateCount,
                shareToken: nil,
                filename: filename,
                komootURL: komootURL
            )
        }
    }
    
    private func parseGPXCoordinates(from gpxContent: String) -> [Coordinate]? {
        var coordinates: [Coordinate] = []
        for line in gpxContent.components(separatedBy: "\n") {
            if line.contains("<trkpt lat=") {
                if let latRange = line.range(of: #"lat="([^"]+)""#, options: .regularExpression),
                   let lngRange = line.range(of: #"lon="([^"]+)""#, options: .regularExpression) {
                    let latString = String(line[latRange].dropFirst(5).dropLast())
                    let lngString = String(line[lngRange].dropFirst(5).dropLast())
                    if let lat = Double(latString), let lng = Double(lngString) {
                        coordinates.append(Coordinate(lat: lat, lng: lng, alt: 0))
                    }
                }
            }
        }
        return coordinates.isEmpty ? nil : coordinates
    }
    
    private func download() {
        isFocused = false
        haptic(.rigid)
        
        let urlString = urlInput.trimmingCharacters(in: .whitespaces)
        
        guard !urlString.isEmpty else {
            errorMessage = "Please paste a Komoot link"
            hapticNotification(.error)
            return
        }
        
        guard urlString.contains("komoot.com") else {
            errorMessage = "This doesn't look like a Komoot link"
            hapticNotification(.error)
            return
        }
        
        guard let cleanURL = KomootURLNormalizer.normalize(urlString) else {
            errorMessage = "Invalid Komoot URL"
            hapticNotification(.error)
            return
        }
        
        isLoading = true
        errorMessage = nil
        shareFile = nil
        tourName = nil
        
        Task {
            do {
                let tour = try await KomootDownloader.downloadTour(from: cleanURL)
                let gpxContent = GPXBuilder.buildGPX(name: tour.name, coordinates: tour.coordinates)
                
                let sanitizedName = tour.name
                    .components(separatedBy: CharacterSet(charactersIn: "<>:\"/\\|?*"))
                    .joined(separator: "_")
                    .trimmingCharacters(in: .whitespaces)
                let filename = sanitizedName.isEmpty ? "route.gpx" : "\(sanitizedName).gpx"
                let tourID = KomootURLNormalizer.extractTourID(from: cleanURL) ?? UUID().uuidString
                let shareToken = extractShareToken(from: urlString)
                
                let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
                try gpxContent.write(to: fileURL, atomically: true, encoding: .utf8)
                
                await MainActor.run {
                    self.tourName = tour.name
                    self.shareFile = ShareableFile(url: fileURL)
                    self.isLoading = false
                    self.urlInput = ""
                    
                    TourHistoryManager.shared.addTour(
                        id: tourID,
                        name: tour.name,
                        coordinateCount: tour.coordinates.count,
                        shareToken: shareToken,
                        filename: filename,
                        komootURL: cleanURL
                    )
                    
                    self.hapticNotification(.success)
                }
            } catch let error as KomootError {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    self.hapticNotification(.error)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    self.hapticNotification(.error)
                }
            }
        }
    }
    
    private func extractShareToken(from urlString: String) -> String? {
        guard let components = URLComponents(string: urlString),
              let queryItems = components.queryItems else {
            return nil
        }
        return queryItems.first { $0.name == "share_token" }?.value
    }
    
    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    private func hapticNotification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let completion: (Bool) -> Void
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in
            completion(completed)
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ContentView()
}

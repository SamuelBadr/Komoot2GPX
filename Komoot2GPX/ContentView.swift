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
        
        let mainDocsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let contents = try fileManager.contentsOfDirectory(at: mainDocsURL, includingPropertiesForKeys: [.isRegularFileKey])
            for fileURL in contents.filter({ $0.pathExtension == "gpx" }) {
                await addFileToHistory(fileURL)
            }
        } catch {}
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
    
    private var downloadTab: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.down.doc")
                            .font(.system(size: 64, weight: .ultraLight))
                            .foregroundStyle(.green)
                            .accessibilityLabel("Download GPX")
                        
                        Text("Komoot2GPX")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Download GPX files from Komoot tours")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    VStack(spacing: 16) {
                        TextField("Paste Komoot link", text: $urlInput)
                            .focused($isFocused)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.go)
                            .onSubmit { download() }
                            .accessibilityLabel("Komoot URL")
                        
                        Button {
                            download()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: isLoading ? "arrow.triangle.2.circlepath" : "arrow.down.circle")
                                    .symbolEffect(.variableColor.iterative, options: .repeating, value: isLoading)
                                
                                Text(isLoading ? "Downloading..." : "Download GPX")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .disabled(isLoading || urlInput.trimmingCharacters(in: .whitespaces).isEmpty)
                        .accessibilityLabel("Download GPX file")
                        .accessibilityHint(isLoading ? "Download in progress" : "Double tap to download")
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(spacing: 16) {
                        Divider()
                        
                        Text("Or share from Komoot app")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        
                        HStack(spacing: 24) {
                            ShareHintBadge(icon: "square.and.arrow.up", text: "Share")
                            ShareHintBadge(icon: "arrow.right", text: "Komoot2GPX")
                            ShareHintBadge(icon: "checkmark.circle", text: "Done")
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    if let errorMessage = errorMessage {
                        StatusMessage(
                            icon: "exclamationmark.circle.fill",
                            text: errorMessage,
                            color: .red,
                            bgColor: Color.red.opacity(0.1)
                        )
                    }
                    
                    if let tourName = tourName {
                        StatusMessage(
                            icon: "checkmark.circle.fill",
                            text: tourName,
                            color: .green,
                            bgColor: Color.green.opacity(0.1)
                        )
                    }
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

private struct ShareHintBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.green)
            
            Text(text)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct StatusMessage: View {
    let icon: String
    let text: String
    let color: Color
    let bgColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(color)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bgColor)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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

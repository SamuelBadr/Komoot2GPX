import SwiftUI

struct HistoryView: View {
    @ObservedObject private var manager = TourHistoryManager.shared
    @State private var shareFile: ShareableFile?
    @State private var showDeleteConfirmation = false
    @State private var tourToDelete: TourRecord?
    @State private var searchText = ""
    
    private var filteredTours: [TourRecord] {
        if searchText.isEmpty {
            return manager.tours
        }
        return manager.tours.filter { tour in
            tour.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if filteredTours.isEmpty {
                    emptyState
                } else {
                    tourList
                }
            }
            .navigationTitle("Downloads")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search tours")
            .toolbar {
                if !manager.tours.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear All") {
                            tourToDelete = nil
                            showDeleteConfirmation = true
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .sheet(item: $shareFile) { file in
                ShareSheet(items: [file.url]) { _ in
                    shareFile = nil
                }
            }
            .alert("Delete Download", isPresented: $showDeleteConfirmation) {
                if tourToDelete != nil {
                    Button("Cancel", role: .cancel) {}
                    Button("Delete", role: .destructive) {
                        if let tour = tourToDelete {
                            manager.removeTour(tour)
                            tourToDelete = nil
                        }
                    }
                } else {
                    Button("Cancel", role: .cancel) {}
                    Button("Clear All", role: .destructive) {
                        manager.removeAll()
                    }
                }
            } message: {
                if let tour = tourToDelete {
                    Text("Delete \"\(tour.name)\"? This will remove the GPX file from your device.")
                } else {
                    Text("This will remove all \(manager.tours.count) downloaded GPX files.")
                }
            }
        }
    }
    
    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Downloads", systemImage: "arrow.down.doc")
                .foregroundStyle(.green)
        } description: {
            if searchText.isEmpty {
                Text("Downloaded GPX files will appear here.\n\nPaste a Komoot link in the Download tab, or share from the Komoot app.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            } else {
                Text("No tours match \"\(searchText)\"")
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var tourList: some View {
        List {
            ForEach(filteredTours) { tour in
                TourRow(tour: tour)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            tourToDelete = tour
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            if let fileURL = manager.getTourFile(tour) {
                                shareFile = ShareableFile(url: fileURL)
                                haptic(.light)
                            }
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .tint(.green)
                        
                        if let komootURL = tour.komootURL, URL(string: komootURL) != nil {
                            Button {
                                manager.openKomootURL(for: tour)
                                haptic(.light)
                            } label: {
                                Label("Komoot", systemImage: "safari")
                            }
                            .tint(.blue)
                        }
                    }
                    .contextMenu {
                        Button {
                            if let fileURL = manager.getTourFile(tour) {
                                shareFile = ShareableFile(url: fileURL)
                                haptic(.light)
                            }
                        } label: {
                            Label("Share GPX", systemImage: "square.and.arrow.up")
                        }
                        
                        if let komootURL = tour.komootURL, URL(string: komootURL) != nil {
                            Button {
                                manager.openKomootURL(for: tour)
                                haptic(.light)
                            } label: {
                                Label("View on Komoot", systemImage: "safari")
                            }
                        }
                        
                        Button(role: .destructive) {
                            tourToDelete = tour
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

#Preview {
    HistoryView()
}

import Foundation
import SwiftUI

class TourHistoryManager: ObservableObject {
    static let shared = TourHistoryManager()
    
    @Published var tours: [TourRecord] = []
    
    private let userDefaultsKey = "SavedTours"
    private let appGroupURL: URL?
    
    private init() {
        let fileManager = FileManager.default
        appGroupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.komoot2gpx.app")
        loadTours()
        validateFiles()
        migrateExistingTours()
    }
    
    func loadTours() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([TourRecord].self, from: data) else {
            tours = []
            return
        }
        tours = decoded
    }
    
    func saveTours() {
        guard let encoded = try? JSONEncoder().encode(tours) else { return }
        UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
    }
    
    func addTour(id: String, name: String, coordinateCount: Int, shareToken: String?, filename: String, komootURL: String? = nil) {
        if tours.contains(where: { $0.filename == filename }) {
            return
        }
        
        let url = komootURL ?? KomootURLNormalizer.constructURL(tourID: id, shareToken: shareToken)
        
        let tour = TourRecord(
            id: id,
            name: name,
            downloadDate: Date(),
            coordinateCount: coordinateCount,
            shareToken: shareToken,
            filename: filename,
            komootURL: url
        )
        
        tours.append(tour)
        saveTours()
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    func removeTour(_ tour: TourRecord) {
        deleteFile(for: tour)
        tours.removeAll { $0.filename == tour.filename }
        saveTours()
    }
    
    func removeAll() {
        for tour in tours {
            deleteFile(for: tour)
        }
        tours.removeAll()
        saveTours()
    }
    
    func getTourFile(_ tour: TourRecord) -> URL? {
        guard let appGroupURL = appGroupURL else { return nil }
        let fileURL = appGroupURL.appendingPathComponent(tour.filename)
        return FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : nil
    }
    
    func tourExists(_ tour: TourRecord) -> Bool {
        getTourFile(tour) != nil
    }
    
    func validateFiles() {
        let validTours = tours.filter { tourExists($0) }
        if validTours.count != tours.count {
            tours = validTours
            saveTours()
        }
    }
    
    private func deleteFile(for tour: TourRecord) {
        guard let appGroupURL = appGroupURL else { return }
        let fileURL = appGroupURL.appendingPathComponent(tour.filename)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    func refresh() async {
        try? await Task.sleep(nanoseconds: 500_000_000)
        validateFiles()
    }
    
    private func migrateExistingTours() {
        var needsSave = false
        
        for (index, tour) in tours.enumerated() {
            if tour.komootURL == nil {
                tours[index].komootURL = KomootURLNormalizer.constructURL(tourID: tour.id, shareToken: tour.shareToken)
                needsSave = true
            }
        }
        
        if needsSave {
            saveTours()
        }
    }
    
    func openKomootURL(for tour: TourRecord) {
        guard let urlString = tour.komootURL,
              let url = URL(string: urlString) else {
            return
        }
        
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

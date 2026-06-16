import Foundation

struct TourRecord: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let downloadDate: Date
    let coordinateCount: Int
    let shareToken: String?
    let filename: String
    var komootURL: String?
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: downloadDate)
    }
    
    var formattedFileSize: String {
        let estimatedSize = coordinateCount * 50
        if estimatedSize < 1024 {
            return "\(estimatedSize) B"
        } else if estimatedSize < 1024 * 1024 {
            return "\(estimatedSize / 1024) KB"
        } else {
            return String(format: "%.1f MB", Double(estimatedSize) / 1024 / 1024)
        }
    }
}

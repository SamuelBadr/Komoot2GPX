import SwiftUI

struct TourRow: View {
    let tour: TourRecord
    @ObservedObject private var manager = TourHistoryManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                
                Image(systemName: "map.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.blue)
            }
            .frame(width: 44, height: 44)
            .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(tour.name)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 6) {
                    Label(tour.formattedDate, systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    
                    Label("\(tour.coordinateCount)", systemImage: "location.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                if manager.tourExists(tour) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.green)
                        .accessibilityLabel("File available")
                    
                    Text(tour.formattedFileSize)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                } else {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.orange)
                        .accessibilityLabel("File missing")
                }
            }
            .frame(width: 40)
            .accessibilityElement(children: .combine)
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tour.name), downloaded \(tour.formattedDate)")
    }
}

#Preview {
    TourRow(tour: TourRecord(
        id: "123",
        name: "Mountain Adventure Tour",
        downloadDate: Date(),
        coordinateCount: 1234,
        shareToken: nil,
        filename: "123_Mountain_Adventure_Tour.gpx",
        komootURL: "https://www.komoot.com/tour/123"
    ))
}

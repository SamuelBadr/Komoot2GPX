import Foundation

struct Coordinate: Codable {
    let lat: Double
    let lng: Double
    let alt: Double
}

struct TourData {
    let name: String
    let coordinates: [Coordinate]
}

enum GPXBuilder {
    static func buildGPX(name: String, coordinates: [Coordinate]) -> String {
        let escapedName = escapeXML(name)

        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>\n"
        xml += """
<gpx version="1.1" creator="Komoot2GPX" xmlns="http://www.topografix.com/GPX/1/1">
  <metadata>
    <name>\(escapedName)</name>
  </metadata>
  <trk>
    <name>\(escapedName)</name>
    <trkseg>
"""

        for coord in coordinates {
            xml += """
      <trkpt lat="\(coord.lat)" lon="\(coord.lng)">
        <ele>\(coord.alt)</ele>
      </trkpt>
"""
        }

        xml += """
  </trkseg>
</trk>
</gpx>
"""

        return xml
    }

    private static func escapeXML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}

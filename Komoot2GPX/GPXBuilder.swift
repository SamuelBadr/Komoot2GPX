import Foundation

struct Coordinate {
    let lat: Double
    let lng: Double
    let alt: Double
}

struct TourData {
    let name: String
    let coordinates: [Coordinate]
}

enum GPXBuilder {
    static func buildGPX(name: String, coordinates: [Coordinate]) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("route.gpx")
        
        var gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="Komoot2GPX" xmlns="http://www.topografix.com/GPX/1/1">
          <metadata>
            <name>\(escapeXML(name))</name>
            <time>\(ISO8601DateFormatter().string(from: Date()))</time>
          </metadata>
          <trk>
            <name>\(escapeXML(name))</name>
            <trkseg>
        
        """
        
        for coord in coordinates {
            gpx += """
              <trkpt lat="\(coord.lat)" lon="\(coord.lng)">
                <ele>\(coord.alt)</ele>
              </trkpt>
            
            """
        }
        
        gpx += """
            </trkseg>
          </trk>
        </gpx>
        """
        
        try? gpx.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    private static func escapeXML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}

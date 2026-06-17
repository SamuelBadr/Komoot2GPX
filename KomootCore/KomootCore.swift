import Foundation

// MARK: - Models

public struct Coordinate {
    public let lat: Double
    public let lng: Double
    public let alt: Double
    
    public init(lat: Double, lng: Double, alt: Double) {
        self.lat = lat
        self.lng = lng
        self.alt = alt
    }
}

public struct TourData {
    public let name: String
    public let coordinates: [Coordinate]
    
    public init(name: String, coordinates: [Coordinate]) {
        self.name = name
        self.coordinates = coordinates
    }
}

// MARK: - Errors

public enum KomootError: Error, LocalizedError {
    case invalidURL
    case couldNotFindTourData
    case networkError(underlying: Error)
    case invalidResponse(statusCode: Int)
    case invalidTourData
    case tourNotFound
    case timeout

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Komoot URL"
        case .couldNotFindTourData:
            return "Could not find tour data. The tour may be private."
        case .networkError(let err):
            return "Network error: \(err.localizedDescription)"
        case .invalidResponse(let code):
            if code == 403 {
                return "This tour is private (HTTP 403). Only public tours can be downloaded."
            } else if code == 404 {
                return "Tour not found (HTTP 404). Check the URL."
            } else if code >= 500 {
                return "Komoot server error (HTTP \(code)). Please try again."
            } else if code == 429 {
                return "Too many requests. Please wait a moment and try again."
            } else {
                return "Komoot error (HTTP \(code)). The tour may be private."
            }
        case .invalidTourData:
            return "Could not parse tour data"
        case .tourNotFound:
            return "Tour not found. Check the URL and ensure the tour is public."
        case .timeout:
            return "Request timed out. Please check your connection and try again."
        }
    }
}

// MARK: - URL Normalizer

public struct KomootURLNormalizer {
    
    private static let trackingParams = Set(["ref", "query", "t_cid", "t_s", "t_ref_username"])
    private static let essentialParams = Set(["share_token"])
    
    public static func normalize(_ urlString: String) -> String? {
        guard var components = URLComponents(string: urlString),
              let host = components.host,
              host.contains("komoot.com") else {
            return nil
        }
        
        if let queryItems = components.queryItems {
            let filteredItems = queryItems.filter { item in
                essentialParams.contains(item.name)
            }
            components.queryItems = filteredItems.isEmpty ? nil : filteredItems
        }
        
        guard let normalizedURL = components.url else {
            return nil
        }
        
        return normalizedURL.absoluteString
    }
    
    public static func extractTourID(from urlString: String) -> String? {
        let trimmed = urlString.trimmingCharacters(in: .whitespaces)
        
        if trimmed.allSatisfy(\.isNumber) {
            return trimmed
        }
        
        guard let url = URL(string: trimmed),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        
        let path = components.path
        let pattern = #"/(?:tour|smarttour)/e?(\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: path, range: NSRange(path.startIndex..., in: path)),
              let range = Range(match.range(at: 1), in: path) else {
            return nil
        }
        
        return String(path[range])
    }
    
    public static func constructURL(tourID: String, shareToken: String?) -> String {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.komoot.com"
        components.path = "/tour/\(tourID)"
        
        if let shareToken = shareToken {
            components.queryItems = [URLQueryItem(name: "share_token", value: shareToken)]
        }
        
        return components.url?.absoluteString ?? "https://www.komoot.com/tour/\(tourID)"
    }
}

// MARK: - GPX Builder

public enum GPXBuilder {
    public static func buildGPX(name: String, coordinates: [Coordinate]) -> String {
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
        
        return gpx
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

// MARK: - Downloader

public enum KomootDownloader {
    private static let apiBase = URL(string: "https://api.komoot.de/v007/tours")!
    private static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
    private static let timeout: TimeInterval = 30

    public static func downloadTour(from urlString: String) async throws -> TourData {
        let (tourID, shareToken) = try parseInput(urlString)

        if let tourID = tourID {
            return try await fetchFromAPI(tourID: tourID, shareToken: shareToken)
        } else {
            return try await fetchFromPage(url: urlString)
        }
    }

    private static func parseInput(_ input: String) throws -> (tourID: String?, shareToken: String?) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        if let match = trimmed.range(of: "^\\d+$", options: .regularExpression) {
            return (String(trimmed[match]), nil)
        }

        guard let url = URL(string: trimmed), let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw KomootError.invalidURL
        }

        let path = components.path
        
        if let range = path.range(of: #"/tour/(\d+)"#, options: .regularExpression),
           let match = path[range].range(of: #"\d+"#, options: .regularExpression) {
            let id = String(path[match])
            let token = components.queryItems?.first(where: { $0.name == "share_token" })?.value
            return (id, token)
        }
        
        if let range = path.range(of: #"/smarttour/e?(\d+)"#, options: .regularExpression),
           let match = path[range].range(of: #"\d+"#, options: .regularExpression) {
            let id = String(path[match])
            let token = components.queryItems?.first(where: { $0.name == "share_token" })?.value
            return (id, token)
        }

        return (nil, nil)
    }

    private static func fetchFromAPI(tourID: String, shareToken: String?) async throws -> TourData {
        var queryItems = [URLQueryItem]()
        if let shareToken = shareToken {
            queryItems.append(URLQueryItem(name: "share_token", value: shareToken))
        }

        var metaComponents = URLComponents(url: apiBase.appendingPathComponent(tourID), resolvingAgainstBaseURL: false)!
        metaComponents.queryItems = queryItems.isEmpty ? nil : queryItems

        let metaData = try await fetchJSON(url: metaComponents.url!)
        guard let name = metaData["name"] as? String else {
            throw KomootError.invalidTourData
        }

        var coordsComponents = URLComponents(url: apiBase.appendingPathComponent("\(tourID)/coordinates"), resolvingAgainstBaseURL: false)!
        coordsComponents.queryItems = queryItems.isEmpty ? nil : queryItems

        let coordsData = try await fetchJSON(url: coordsComponents.url!)
        guard let items = coordsData["items"] as? [[String: Any]] else {
            throw KomootError.invalidTourData
        }

        let coordinates = try items.map { item -> Coordinate in
            guard let lat = item["lat"] as? Double,
                  let lng = item["lng"] as? Double,
                  let alt = item["alt"] as? Double else {
                throw KomootError.invalidTourData
            }
            return Coordinate(lat: lat, lng: lng, alt: alt)
        }

        return TourData(name: name, coordinates: coordinates)
    }

    private static func fetchJSON(url: URL) async throws -> [String: Any] {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = timeout

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 404 {
                throw KomootError.tourNotFound
            } else if httpResponse.statusCode != 200 {
                throw KomootError.invalidResponse(statusCode: httpResponse.statusCode)
            }
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw KomootError.invalidTourData
        }

        return json
    }

    private static func fetchFromPage(url: String) async throws -> TourData {
        guard let url = URL(string: url) else {
            throw KomootError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = timeout

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 404 {
                throw KomootError.tourNotFound
            } else if httpResponse.statusCode != 200 {
                throw KomootError.invalidResponse(statusCode: httpResponse.statusCode)
            }
        }
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw KomootError.invalidResponse(statusCode: 0)
        }

        let json = try extractJSON(from: html)
        let tour = json["page"]["_embedded"]["tour"]
        let name = tour["name"].stringValue

        let coords = tour["_embedded"]["coordinates"]["items"]
        guard coords.arrayValue != nil else {
            throw KomootError.invalidTourData
        }

        let coordinates: [Coordinate] = try coords.arrayValue!.map { item in
            guard let lat = item["lat"].double,
                  let lng = item["lng"].double,
                  let alt = item["alt"].double else {
                throw KomootError.invalidTourData
            }
            return Coordinate(lat: lat, lng: lng, alt: alt)
        }

        return TourData(name: name, coordinates: coordinates)
    }

    private static func extractJSON(from html: String) throws -> JSONValue {
        let pattern = #"kmtBoot\.setProps\("((?:[^"\\]|\\.)*)"\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)) else {
            throw KomootError.couldNotFindTourData
        }

        let capturedRange = match.range(at: 1)
        guard let swiftRange = Range(capturedRange, in: html) else {
            throw KomootError.couldNotFindTourData
        }

        let captured = String(html[swiftRange])
        let quoted = "\"\(captured)\""
        
        guard let quotedData = quoted.data(using: .utf8),
              let unescaped = try? JSONDecoder().decode(String.self, from: quotedData),
              let jsonData = unescaped.data(using: .utf8) else {
            throw KomootError.couldNotFindTourData
        }

        let obj = try JSONSerialization.jsonObject(with: jsonData)
        return JSONValue(value: obj)
    }
}

// MARK: - JSON Wrapper

private struct JSONValue {
    let value: Any

    subscript(key: String) -> JSONValue {
        if let dict = value as? [String: Any], let v = dict[key] {
            return JSONValue(value: v)
        }
        return JSONValue(value: NSNull())
    }

    var stringValue: String {
        value as? String ?? ""
    }

    var double: Double? {
        value as? Double ?? (value as? NSNumber)?.doubleValue
    }

    var arrayValue: [JSONValue]? {
        (value as? [Any])?.map { JSONValue(value: $0) }
    }
}

import Foundation

enum KomootError: Error, LocalizedError {
    case invalidURL
    case couldNotFindTourData
    case networkError(underlying: Error)
    case invalidResponse(statusCode: Int)
    case invalidTourData
    case tourNotFound
    case timeout

    var errorDescription: String? {
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

enum KomootDownloader {
    private static let apiBase = URL(string: "https://api.komoot.de/v007/tours")!
    private static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
    private static let timeout: TimeInterval = 30

    static func downloadTour(from urlString: String) async throws -> TourData {
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

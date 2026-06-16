import Foundation

struct KomootURLNormalizer {
    
    private static let trackingParams = Set(["ref", "query", "t_cid", "t_s", "t_ref_username"])
    private static let essentialParams = Set(["share_token"])
    
    static func normalize(_ urlString: String) -> String? {
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
    
    static func extractTourID(from urlString: String) -> String? {
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
    
    static func constructURL(tourID: String, shareToken: String?) -> String {
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

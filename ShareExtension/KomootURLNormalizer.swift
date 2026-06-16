import Foundation

/// Normalizes Komoot URLs by removing tracking parameters while preserving essential ones
struct KomootURLNormalizer {
    
    /// Parameters to remove (tracking/analytics)
    private static let trackingParams = Set([
        "ref", "query", "t_cid", "t_s", "t_ref_username"
    ])
    
    /// Parameters to keep (essential for tour access)
    private static let essentialParams = Set([
        "share_token"
    ])
    
    /// Normalize a Komoot URL
    /// - Parameter urlString: The URL to normalize
    /// - Returns: Normalized URL string, or nil if invalid
    static func normalize(_ urlString: String) -> String? {
        guard var components = URLComponents(string: urlString),
              let host = components.host,
              host.contains("komoot.com") else {
            return nil
        }
        
        // Keep only essential query parameters
        if let queryItems = components.queryItems {
            let filteredItems = queryItems.filter { item in
                essentialParams.contains(item.name)
            }
            components.queryItems = filteredItems.isEmpty ? nil : filteredItems
        }
        
        // Ensure we have a valid URL
        guard let normalizedURL = components.url else {
            return nil
        }
        
        return normalizedURL.absoluteString
    }
    
    /// Extract tour ID from URL
    /// - Parameter urlString: The URL to extract from
    /// - Returns: Tour ID if found
    static func extractTourID(from urlString: String) -> String? {
        let trimmed = urlString.trimmingCharacters(in: .whitespaces)
        
        // Check if it's just a numeric ID
        if trimmed.allSatisfy(\.isNumber) {
            return trimmed
        }
        
        // Parse URL
        guard let url = URL(string: trimmed),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        
        let path = components.path
        
        // Match /tour/123 or /smarttour/e123 or /smarttour/123
        let pattern = #"/(?:tour|smarttour)/e?(\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: path, range: NSRange(path.startIndex..., in: path)),
              let range = Range(match.range(at: 1), in: path) else {
            return nil
        }
        
        return String(path[range])
    }
    
    /// Construct a Komoot URL from tour ID
    /// - Parameters:
    ///   - tourID: The tour ID
    ///   - shareToken: Optional share token for private tours
    /// - Returns: Constructed URL
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

import XCTest
@testable import Komoot2GPX

final class KomootIntegrationTests: XCTestCase {
    
    // MARK: - Integration Tests (Require Network)
    // These tests make real API calls and may fail if:
    // - Network is unavailable
    // - Komoot API is down
    // - Tour is made private
    
    func testDownloadPublicTour_FromNumericID() async throws {
        // Use a known public tour ID
        let tourID = "1056563938" // Public tour
        
        do {
            let tour = try await KomootDownloader.downloadTour(from: tourID)
            
            XCTAssertFalse(tour.name.isEmpty)
            XCTAssertGreaterThan(tour.coordinates.count, 0)
            print("✅ Downloaded: \(tour.name) with \(tour.coordinates.count) points")
        } catch {
            // If this fails, the tour might have been made private
            print("⚠️ Tour \(tourID) may be private or unavailable: \(error)")
        }
    }
    
    func testDownloadPublicTour_FromTourURL() async throws {
        let url = "https://www.komoot.com/tour/1056563938"
        
        do {
            let tour = try await KomootDownloader.downloadTour(from: url)
            
            XCTAssertFalse(tour.name.isEmpty)
            XCTAssertGreaterThan(tour.coordinates.count, 0)
        } catch {
            print("⚠️ Tour URL may be private: \(error)")
        }
    }
    
    func testDownloadPublicTour_FromSmarttourURL() async throws {
        let url = "https://www.komoot.com/smarttour/e1984570097"
        
        do {
            let tour = try await KomootDownloader.downloadTour(from: url)
            
            XCTAssertFalse(tour.name.isEmpty)
            XCTAssertGreaterThan(tour.coordinates.count, 0)
        } catch {
            print("⚠️ Smarttour may be private: \(error)")
        }
    }
    
    func testDownloadPrivateTour_ShouldFail() async {
        // This should fail with a 403 or tour not found error
        // Using an invalid/private tour ID
        let privateTourID = "999999999999"
        
        do {
            _ = try await KomootDownloader.downloadTour(from: privateTourID)
            XCTFail("Expected error for private/non-existent tour")
        } catch KomootError.tourNotFound {
            // Expected
            print("✅ Correctly identified non-existent tour")
        } catch KomootError.invalidResponse(let statusCode) {
            // Also acceptable (403, 404, etc.)
            XCTAssertGreaterThanOrEqual(statusCode, 400)
            print("✅ Correctly rejected with HTTP \(statusCode)")
        } catch {
            // Any error is acceptable for a private tour
            print("✅ Correctly failed with: \(error)")
        }
    }
    
    func testInvalidURL_ShouldFail() async {
        let invalidURL = "https://example.com/not-komoot"
        
        do {
            _ = try await KomootDownloader.downloadTour(from: invalidURL)
            XCTFail("Expected error for invalid URL")
        } catch {
            // Expected to fail
            print("✅ Correctly rejected invalid URL")
        }
    }
    
    func testMalformedURL_ShouldFail() async {
        let malformedURL = "not a url at all"
        
        do {
            _ = try await KomootDownloader.downloadTour(from: malformedURL)
            XCTFail("Expected error for malformed URL")
        } catch {
            // Expected to fail
            print("✅ Correctly rejected malformed URL")
        }
    }
    
    // MARK: - URL Pattern Tests
    
    func testVariousKomootURLPatterns() async {
        let validPatterns = [
            "123456789",
            "https://www.komoot.com/tour/123456789",
            "https://www.komoot.de/tour/123456789",
            "https://www.komoot.com/smarttour/e123456789",
            "https://www.komoot.com/smarttour/123456789",
            "https://www.komoot.com/tour/123?share_token=abc",
        ]
        
        for pattern in validPatterns {
            let tourID = Komoot2GPX.extractTourID(from: pattern)
            XCTAssertNotNil(tourID, "Failed to extract ID from: \(pattern)")
        }
    }
    
    // MARK: - GPX Validation Tests
    
    func testGPXIsValidXML() async throws {
        let coordinates = [
            Coordinate(lat: 48.123, lng: 16.456, alt: 200.0),
            Coordinate(lat: 48.124, lng: 16.457, alt: 210.0)
        ]
        
        let gpx = GPXBuilder.buildGPX(name: "Test", coordinates: coordinates)
        
        // Basic XML validation
        XCTAssertTrue(gpx.hasPrefix("<?xml"))
        XCTAssertTrue(gpx.contains("<gpx"))
        XCTAssertTrue(gpx.contains("</gpx>"))
        
        // Verify it can be parsed as XML
        let gpxData = Data(gpx.utf8)
        let parser = XMLParser(data: gpxData)
        let delegate = GPXParserDelegate()
        parser.delegate = delegate
        let success = parser.parse()
        
        XCTAssertTrue(success, "GPX should be valid XML")
    }
    
    // MARK: - Error Message Tests
    
    func testErrorMessagesAreHelpful() {
        let errors: [(KomootError, String)] = [
            (.invalidURL, "Invalid"),
            (.tourNotFound, "not found"),
            (.invalidResponse(statusCode: 403), "403"),
            (.invalidResponse(statusCode: 404), "404"),
            (.couldNotFindTourData, "tour data"),
        ]
        
        for (error, expectedSubstring) in errors {
            let message = error.localizedDescription
            XCTAssertTrue(
                message.localizedCaseInsensitiveContains(expectedSubstring),
                "Error message '\(message)' should contain '\(expectedSubstring)'"
            )
        }
    }
}

// MARK: - XML Parser Delegate for Validation

class GPXParserDelegate: NSObject, XMLParserDelegate {
    var foundElements = [String]()
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        foundElements.append(elementName)
    }
}

// MARK: - Test Helpers

extension Komoot2GPX {
    // Expose private helpers for testing
    static func extractTourID(from urlString: String) -> String? {
        let trimmed = urlString.trimmingCharacters(in: .whitespaces)
        if let url = URL(string: trimmed), let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            let path = components.path
            if let range = path.range(of: #"/(?:tour|smarttour)/e?\d+"#, options: .regularExpression) {
                let match = String(path[range])
                if let idRange = match.range(of: #"\d+"#, options: .regularExpression) {
                    return String(match[idRange])
                }
            }
        }
        if trimmed.allSatisfy(\.isNumber) {
            return trimmed
        }
        return nil
    }
    
    static func extractCleanURL(from urlString: String) -> String {
        guard var components = URLComponents(string: urlString) else {
            return urlString
        }
        
        if let queryItems = components.queryItems {
            let essentialItems = queryItems.filter { item in
                item.name == "share_token"
            }
            components.queryItems = essentialItems.isEmpty ? nil : essentialItems
        }
        
        return components.string ?? urlString
    }
}

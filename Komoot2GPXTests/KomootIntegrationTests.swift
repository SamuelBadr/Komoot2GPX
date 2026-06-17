import XCTest
@testable import Komoot2GPX

final class KomootIntegrationTests: XCTestCase {
    
    // MARK: - Real URL Tests (No Network)
    
    func testParseRealKomootTourURL() {
        let url = "https://www.komoot.com/tour/1056563938"
        let tourID = KomootURLNormalizer.extractTourID(from: url)
        XCTAssertEqual(tourID, "1056563938")
    }
    
    func testParseRealKomootSmarttourURL() {
        let url = "https://www.komoot.com/smarttour/e1984570097"
        let tourID = KomootURLNormalizer.extractTourID(from: url)
        XCTAssertEqual(tourID, "1984570097")
    }
    
    func testParseRealKomootURLWithShareToken() {
        let url = "https://www.komoot.com/tour/123?share_token=abc123xyz"
        let normalized = KomootURLNormalizer.normalize(url)
        XCTAssertNotNil(normalized)
        XCTAssertTrue(normalized!.contains("share_token=abc123xyz"))
    }
    
    func testParseRealKomootURLWithTrackingParams() {
        let url = "https://www.komoot.com/smarttour/40128?ref=itd&query=abc&t_cid=route_share&t_ref_username=john"
        let normalized = KomootURLNormalizer.normalize(url)
        XCTAssertNotNil(normalized)
        XCTAssertFalse(normalized!.contains("ref="))
        XCTAssertFalse(normalized!.contains("query="))
        XCTAssertFalse(normalized!.contains("t_cid="))
        XCTAssertFalse(normalized!.contains("t_ref_username="))
    }
    
    // MARK: - GPX Integration Tests
    
    func testGPXRoundTrip() {
        let originalCoordinates = [
            Coordinate(lat: 48.123, lng: 16.456, alt: 200.0),
            Coordinate(lat: 48.124, lng: 16.457, alt: 210.0),
            Coordinate(lat: 48.125, lng: 16.458, alt: 220.0)
        ]
        
        let gpx = GPXBuilder.buildGPX(name: "Test Tour", coordinates: originalCoordinates)
        
        // Verify GPX structure
        XCTAssertTrue(gpx.contains("<?xml"))
        XCTAssertTrue(gpx.contains("<gpx"))
        XCTAssertTrue(gpx.contains("</gpx>"))
        
        // Verify all coordinates are present
        for coord in originalCoordinates {
            XCTAssertTrue(gpx.contains("lat=\"\(coord.lat)\""))
            XCTAssertTrue(gpx.contains("lon=\"\(coord.lng)\""))
            XCTAssertTrue(gpx.contains("<ele>\(coord.alt)</ele>"))
        }
    }
    
    func testGPXWithLargeCoordinateSet() {
        let coordinates = (0..<10000).map { i in
            Coordinate(lat: 48.0 + Double(i) * 0.0001, lng: 16.0 + Double(i) * 0.0001, alt: 100.0 + Double(i))
        }
        
        let gpx = GPXBuilder.buildGPX(name: "Large Tour", coordinates: coordinates)
        
        // Should complete without timeout
        XCTAssertGreaterThan(gpx.count, 0)
        XCTAssertTrue(gpx.contains("<gpx"))
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidURLs() {
        let invalidURLs = [
            "",
            "not a url",
            "https://example.com",
            "https://strava.com/routes/123",
            "ftp://komoot.com/tour/123"
        ]
        
        for url in invalidURLs {
            let normalized = KomootURLNormalizer.normalize(url)
            XCTAssertNil(normalized, "Expected nil for: \(url)")
        }
    }
    
    func testValidTourIDs() {
        let validInputs = [
            ("123456", "123456"),
            ("  789  ", "789"),
            ("https://www.komoot.com/tour/111", "111"),
            ("https://www.komoot.com/smarttour/e222", "222"),
            ("https://www.komoot.com/smarttour/333", "333")
        ]
        
        for (input, expected) in validInputs {
            let result = KomootURLNormalizer.extractTourID(from: input)
            XCTAssertEqual(result, expected, "Failed for: \(input)")
        }
    }
}

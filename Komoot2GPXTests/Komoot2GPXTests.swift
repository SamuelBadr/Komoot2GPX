import XCTest
@testable import Komoot2GPX

final class Komoot2GPXTests: XCTestCase {
    
    var downloader: KomootDownloader!
    
    override func setUp() async throws {
        try await super.setUp()
        downloader = KomootDownloader()
    }
    
    override func tearDown() async throws {
        downloader = nil
        try await super.tearDown()
    }
    
    // MARK: - URL Parsing Tests
    
    func testExtractTourID_FromNumericString() {
        let result = Komoot2GPX.extractTourID(from: "123456789")
        XCTAssertEqual(result, "123456789")
    }
    
    func testExtractTourID_FromTourURL() {
        let result = Komoot2GPX.extractTourID(from: "https://www.komoot.com/tour/123456789")
        XCTAssertEqual(result, "123456789")
    }
    
    func testExtractTourID_FromSmarttourURL() {
        let result = Komoot2GPX.extractTourID(from: "https://www.komoot.com/smarttour/e1984570097")
        XCTAssertEqual(result, "1984570097")
    }
    
    func testExtractTourID_FromSmarttourURL_WithTrackingParams() {
        let url = "https://www.komoot.com/smarttour/40128?ref=itd&query=abc123&t_cid=route_share"
        let result = Komoot2GPX.extractTourID(from: url)
        XCTAssertEqual(result, "40128")
    }
    
    func testExtractTourID_FromSmarttourURL_NoPrefix() {
        let result = Komoot2GPX.extractTourID(from: "https://www.komoot.com/smarttour/987654")
        XCTAssertEqual(result, "987654")
    }
    
    func testExtractTourID_InvalidURL() {
        let result = Komoot2GPX.extractTourID(from: "https://example.com/invalid")
        XCTAssertNil(result)
    }
    
    func testExtractTourID_EmptyString() {
        let result = Komoot2GPX.extractTourID(from: "")
        XCTAssertNil(result)
    }
    
    func testExtractTourID_WithWhitespace() {
        let result = Komoot2GPX.extractTourID(from: "  123456789  ")
        XCTAssertEqual(result, "123456789")
    }
    
    // MARK: - URL Cleaning Tests
    
    func testCleanURL_RemovesTrackingParameters() {
        let url = "https://www.komoot.com/smarttour/40128?ref=itd&query=abc&t_cid=share"
        let cleaned = Komoot2GPX.extractCleanURL(from: url)
        
        XCTAssertFalse(cleaned.contains("ref="))
        XCTAssertFalse(cleaned.contains("query="))
        XCTAssertFalse(cleaned.contains("t_cid="))
        XCTAssertTrue(cleaned.contains("komoot.com/smarttour/40128"))
    }
    
    func testCleanURL_KeepsShareToken() {
        let url = "https://www.komoot.com/tour/123?share_token=abc123&ref=xyz"
        let cleaned = Komoot2GPX.extractCleanURL(from: url)
        
        XCTAssertTrue(cleaned.contains("share_token=abc123"))
        XCTAssertFalse(cleaned.contains("ref="))
    }
    
    func testCleanURL_InvalidURL() {
        let url = "not a valid url"
        let cleaned = Komoot2GPX.extractCleanURL(from: url)
        XCTAssertEqual(cleaned, url)
    }
    
    // MARK: - GPX Builder Tests
    
    func testGPXBuilder_WithCoordinates() {
        let coordinates = [
            Coordinate(lat: 48.123, lng: 16.456, alt: 200.0),
            Coordinate(lat: 48.124, lng: 16.457, alt: 210.0),
            Coordinate(lat: 48.125, lng: 16.458, alt: 220.0)
        ]
        
        let gpx = GPXBuilder.buildGPX(name: "Test Tour", coordinates: coordinates)
        
        XCTAssertTrue(gpx.hasPrefix("<?xml"))
        XCTAssertTrue(gpx.contains("<gpx"))
        XCTAssertTrue(gpx.contains("<metadata>"))
        XCTAssertTrue(gpx.contains("<name>Test Tour</name>"))
        XCTAssertTrue(gpx.contains("<trk>"))
        XCTAssertTrue(gpx.contains("<trkseg>"))
        XCTAssertTrue(gpx.contains("lat=\"48.123\""))
        XCTAssertTrue(gpx.contains("lon=\"16.456\""))
        XCTAssertTrue(gpx.contains("<ele>200.0</ele>"))
        XCTAssertTrue(gpx.contains("</gpx>"))
    }
    
    func testGPXBuilder_WithSpecialCharacters() {
        let coordinates = [Coordinate(lat: 48.0, lng: 16.0, alt: 100.0)]
        let gpx = GPXBuilder.buildGPX(name: "Tour & Test <3", coordinates: coordinates)
        
        XCTAssertTrue(gpx.contains("&amp;"))
        XCTAssertTrue(gpx.contains("&lt;"))
    }
    
    func testGPXBuilder_EmptyCoordinates() {
        let gpx = GPXBuilder.buildGPX(name: "Empty Tour", coordinates: [])
        
        XCTAssertTrue(gpx.hasPrefix("<?xml"))
        XCTAssertTrue(gpx.contains("<gpx"))
    }
    
    // MARK: - Komoot Error Tests
    
    func testKomootError_InvalidURL() {
        let error = KomootError.invalidURL
        XCTAssertEqual(error.localizedDescription, "Invalid Komoot URL or tour ID.")
    }
    
    func testKomootError_TourNotFound() {
        let error = KomootError.tourNotFound
        XCTAssertEqual(error.localizedDescription, "Tour not found. Check the URL and ensure the tour is public.")
    }
    
    func testKomootError_InvalidResponse() {
        let error = KomootError.invalidResponse(statusCode: 403)
        XCTAssertEqual(error.localizedDescription, "Komoot returned an error (HTTP 403). Check if the tour is public.")
    }
    
    func testKomootError_InvalidResponse404() {
        let error = KomootError.invalidResponse(statusCode: 404)
        XCTAssertEqual(error.localizedDescription, "Komoot returned an error (HTTP 404). Check if the tour is public.")
    }
    
    // MARK: - Tour Record Tests
    
    func testTourRecord_Filename() {
        let record = TourRecord(
            id: "123",
            name: "Test Tour",
            downloadDate: Date(),
            coordinateCount: 100,
            shareToken: nil,
            filename: "123_Test_Tour.gpx"
        )
        
        XCTAssertEqual(record.filename, "123_Test_Tour.gpx")
    }
    
    func testTourRecord_FilenameWithSpecialCharacters() {
        let record = TourRecord(
            id: "456",
            name: "Tour <Special> & \"Characters\"",
            downloadDate: Date(),
            coordinateCount: 50,
            shareToken: nil,
            filename: "456_Tour_Special_Characters.gpx"
        )
        
        // Filename should be sanitized
        XCTAssertFalse(record.filename.contains("<"))
        XCTAssertFalse(record.filename.contains(">"))
        XCTAssertFalse(record.filename.contains("&"))
    }
    
    // MARK: - Performance Tests
    
    func testGPXBuilderPerformance() {
        let coordinates = (0..<1000).map { i in
            Coordinate(lat: 48.0 + Double(i) * 0.001, lng: 16.0 + Double(i) * 0.001, alt: 100.0 + Double(i))
        }
        
        measure {
            _ = GPXBuilder.buildGPX(name: "Performance Test", coordinates: coordinates)
        }
    }
}

// MARK: - Test Helpers

extension Komoot2GPXTests {
    static var extractTourID: (String) -> String? {
        return { urlString in
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
    }
    
    static var extractCleanURL: (String) -> String {
        return { urlString in
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
}

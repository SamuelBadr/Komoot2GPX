import XCTest
@testable import Komoot2GPX

final class Komoot2GPXTests: XCTestCase {
    
    // MARK: - URL Normalization Tests
    
    func testNormalizeURL_RemovesTrackingParameters() {
        let url = "https://www.komoot.com/smarttour/40128?ref=itd&query=abc&t_cid=share"
        let normalized = KomootURLNormalizer.normalize(url)
        
        XCTAssertNotNil(normalized)
        XCTAssertFalse(normalized!.contains("ref="))
        XCTAssertFalse(normalized!.contains("query="))
        XCTAssertFalse(normalized!.contains("t_cid="))
        XCTAssertTrue(normalized!.contains("komoot.com/smarttour/40128"))
    }
    
    func testNormalizeURL_KeepsShareToken() {
        let url = "https://www.komoot.com/tour/123?share_token=abc123&ref=xyz"
        let normalized = KomootURLNormalizer.normalize(url)
        
        XCTAssertNotNil(normalized)
        XCTAssertTrue(normalized!.contains("share_token=abc123"))
        XCTAssertFalse(normalized!.contains("ref="))
    }
    
    func testNormalizeURL_InvalidURL() {
        let url = "not a valid url"
        let normalized = KomootURLNormalizer.normalize(url)
        XCTAssertNil(normalized)
    }
    
    func testNormalizeURL_NonKomootURL() {
        let url = "https://example.com/tour/123"
        let normalized = KomootURLNormalizer.normalize(url)
        XCTAssertNil(normalized)
    }
    
    // MARK: - Tour ID Extraction Tests
    
    func testExtractTourID_FromNumericString() {
        let result = KomootURLNormalizer.extractTourID(from: "123456789")
        XCTAssertEqual(result, "123456789")
    }
    
    func testExtractTourID_FromTourURL() {
        let result = KomootURLNormalizer.extractTourID(from: "https://www.komoot.com/tour/123456789")
        XCTAssertEqual(result, "123456789")
    }
    
    func testExtractTourID_FromSmarttourURL() {
        let result = KomootURLNormalizer.extractTourID(from: "https://www.komoot.com/smarttour/e1984570097")
        XCTAssertEqual(result, "1984570097")
    }
    
    func testExtractTourID_FromSmarttourURL_WithTrackingParams() {
        let url = "https://www.komoot.com/smarttour/40128?ref=itd&query=abc123&t_cid=route_share"
        let result = KomootURLNormalizer.extractTourID(from: url)
        XCTAssertEqual(result, "40128")
    }
    
    func testExtractTourID_FromSmarttourURL_NoPrefix() {
        let result = KomootURLNormalizer.extractTourID(from: "https://www.komoot.com/smarttour/987654")
        XCTAssertEqual(result, "987654")
    }
    
    func testExtractTourID_InvalidURL() {
        let result = KomootURLNormalizer.extractTourID(from: "https://example.com/invalid")
        XCTAssertNil(result)
    }
    
    func testExtractTourID_EmptyString() {
        let result = KomootURLNormalizer.extractTourID(from: "")
        XCTAssertNil(result)
    }
    
    func testExtractTourID_WithWhitespace() {
        let result = KomootURLNormalizer.extractTourID(from: "  123456789  ")
        XCTAssertEqual(result, "123456789")
    }
    
    // MARK: - URL Construction Tests
    
    func testConstructURL_WithoutShareToken() {
        let url = KomootURLNormalizer.constructURL(tourID: "123", shareToken: nil)
        XCTAssertEqual(url, "https://www.komoot.com/tour/123")
    }
    
    func testConstructURL_WithShareToken() {
        let url = KomootURLNormalizer.constructURL(tourID: "456", shareToken: "abc123")
        XCTAssertEqual(url, "https://www.komoot.com/tour/456?share_token=abc123")
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
        XCTAssertEqual(error.localizedDescription, "Invalid Komoot URL")
    }
    
    func testKomootError_TourNotFound() {
        let error = KomootError.tourNotFound
        XCTAssertEqual(error.localizedDescription, "Tour not found. Check the URL and ensure the tour is public.")
    }
    
    func testKomootError_InvalidResponse403() {
        let error = KomootError.invalidResponse(statusCode: 403)
        XCTAssertEqual(error.localizedDescription, "This tour is private (HTTP 403). Only public tours can be downloaded.")
    }
    
    func testKomootError_InvalidResponse404() {
        let error = KomootError.invalidResponse(statusCode: 404)
        XCTAssertEqual(error.localizedDescription, "Tour not found (HTTP 404). Check the URL.")
    }
    
    func testKomootError_InvalidResponse500() {
        let error = KomootError.invalidResponse(statusCode: 500)
        XCTAssertEqual(error.localizedDescription, "Komoot server error (HTTP 500). Please try again.")
    }
    
    func testKomootError_InvalidResponse429() {
        let error = KomootError.invalidResponse(statusCode: 429)
        XCTAssertEqual(error.localizedDescription, "Too many requests. Please wait a moment and try again.")
    }
    
    // MARK: - Tour Record Tests
    
    func testTourRecord_FormattedDate() {
        let date = Date(timeIntervalSince1970: 0)
        let record = TourRecord(
            id: "123",
            name: "Test Tour",
            downloadDate: date,
            coordinateCount: 100,
            shareToken: nil,
            filename: "123_Test_Tour.gpx",
            komootURL: nil
        )
        
        XCTAssertFalse(record.formattedDate.isEmpty)
    }
    
    func testTourRecord_FormattedFileSize() {
        let record = TourRecord(
            id: "123",
            name: "Test Tour",
            downloadDate: Date(),
            coordinateCount: 100,
            shareToken: nil,
            filename: "123_Test_Tour.gpx",
            komootURL: nil
        )
        
        XCTAssertEqual(record.formattedFileSize, "5 KB")
    }
    
    func testTourRecord_Equatable() {
        let record1 = TourRecord(
            id: "123",
            name: "Test Tour",
            downloadDate: Date(),
            coordinateCount: 100,
            shareToken: nil,
            filename: "123_Test_Tour.gpx",
            komootURL: nil
        )
        
        let record2 = TourRecord(
            id: "123",
            name: "Test Tour",
            downloadDate: record1.downloadDate,
            coordinateCount: 100,
            shareToken: nil,
            filename: "123_Test_Tour.gpx",
            komootURL: nil
        )
        
        XCTAssertEqual(record1, record2)
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

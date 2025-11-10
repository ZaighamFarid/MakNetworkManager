//
//  RequestBuilderTests.swift
//  MakNetworkManagerTests
//
//  Tests for RequestBuilder implementation
//

import XCTest
@testable import MakNetworkManager

final class RequestBuilderTests: XCTestCase {
    var builder: RequestBuilder!
    var configuration: NetworkConfiguration!
    
    override func setUp() {
        super.setUp()
        builder = RequestBuilder()
        configuration = NetworkConfiguration(
            baseURL: URL(string: "https://api.example.com")!,
            clientID: "test_client",
            clientSecret: "test_secret"
        )
    }
    
    override func tearDown() {
        builder = nil
        configuration = nil
        super.tearDown()
    }
    
    func testBuildGETRequest() throws {
        let request = ConferenceAPI.getConferences
        let urlRequest = try builder.buildRequest(from: request, configuration: configuration)
        
        XCTAssertEqual(urlRequest.httpMethod, "GET")
        XCTAssertNil(urlRequest.httpBody)
        XCTAssertNotNil(urlRequest.url)
    }
    
    func testBuildPOSTRequest() throws {
        let request = ConferenceAPI.createConference(name: "Test Conference", date: "2025-01-01")
        let urlRequest = try builder.buildRequest(from: request, configuration: configuration)
        
        XCTAssertEqual(urlRequest.httpMethod, "POST")
        XCTAssertNotNil(urlRequest.httpBody)
        
        // Verify parameters are in body
        let body = try XCTUnwrap(urlRequest.httpBody)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        XCTAssertEqual(json?["name"] as? String, "Test Conference")
        XCTAssertEqual(json?["date"] as? String, "2025-01-01")
    }
    
    func testBuildGETRequestWithParameters() throws {
        struct TestRequest: APIRequest {
            var baseURL: URL { URL(string: "https://api.example.com")! }
            var path: String { "test" }
            var method: HTTPMethod { .get }
            var parameters: [String : Any]? { ["query": "test", "page": 1] }
        }
        
        let request = TestRequest()
        let urlRequest = try builder.buildRequest(from: request, configuration: configuration)
        
        XCTAssertNotNil(urlRequest.url)
        let urlString = urlRequest.url?.absoluteString
        XCTAssertTrue(urlString?.contains("query=test") ?? false)
        XCTAssertTrue(urlString?.contains("page=1") ?? false)
    }
    
    func testDefaultHeadersAreApplied() throws {
        let request = ConferenceAPI.getConferences
        let urlRequest = try builder.buildRequest(from: request, configuration: configuration)
        
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Accept"), "application/json")
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }
    
    func testCustomTimeoutIsApplied() throws {
        struct CustomTimeoutRequest: APIRequest {
            var baseURL: URL { URL(string: "https://api.example.com")! }
            var path: String { "test" }
            var method: HTTPMethod { .get }
            var timeout: TimeInterval? { 60 }
        }
        
        let request = CustomTimeoutRequest()
        let urlRequest = try builder.buildRequest(from: request, configuration: configuration)
        
        XCTAssertEqual(urlRequest.timeoutInterval, 60)
    }
}

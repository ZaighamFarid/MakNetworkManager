//
//  APIServiceTests.swift
//  MakNetworkManagerTests
//
//  Tests for APIService with token refresh logic
//

import XCTest
@testable import MakNetworkManager

final class APIServiceTests: XCTestCase {
    var apiService: APIService!
    var configuration: NetworkConfiguration!
    var mockSession: URLSession!
    
    override func setUp() {
        super.setUp()
        
        configuration = NetworkConfiguration(
            baseURL: URL(string: "https://api.example.com")!,
            clientID: "test_client",
            clientSecret: "test_secret"
        )
        
        // Configure URLSession with mock protocol
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMock.self]
        mockSession = URLSession(configuration: config)
        
        let executor = RequestExecutor(session: mockSession)
        apiService = APIService(
            configuration: configuration,
            requestExecutor: executor
        )
    }
    
    override func tearDown() {
        URLProtocolMock.reset()
        apiService = nil
        mockSession = nil
        super.tearDown()
    }
    
    func testSuccessfulRequest() async throws {
        // Setup mock response
        let mockData = """
        {
            "conferences": [],
            "total": 0
        }
        """.data(using: .utf8)!
        
        URLProtocolMock.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (mockData, response, nil)
        }
        
        // Execute request
        let response = try await apiService.perform(ConferenceAPI.getConferences)
        
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.data, mockData)
    }
    
    func testUnauthorizedError() async throws {
        // Setup 401 response
        URLProtocolMock.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            return (Data(), response, nil)
        }
        
        do {
            _ = try await apiService.perform(ConferenceAPI.getConferences)
            XCTFail("Should have thrown unauthorized error")
        } catch NetworkError.unauthorized {
            // Expected error
        } catch {
            XCTFail("Wrong error type: \\(error)")
        }
    }
    
    func testServerError() async throws {
        let errorMessage = "Internal Server Error"
        let mockData = """
        {
            "message": "\\(errorMessage)"
        }
        """.data(using: .utf8)!
        
        URLProtocolMock.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (mockData, response, nil)
        }
        
        do {
            _ = try await apiService.perform(ConferenceAPI.getConferences)
            XCTFail("Should have thrown server error")
        } catch NetworkError.server(let status, let message) {
            XCTAssertEqual(status, 500)
            XCTAssertEqual(message, errorMessage)
        } catch {
            XCTFail("Wrong error type: \\(error)")
        }
    }
    
    func testDecodingResponse() async throws {
        let mockData = """
        {
            "conferences": [
                {"id": 1, "name": "Test Conference", "date": "2025-01-01", "location": "Test Location"}
            ],
            "total": 1
        }
        """.data(using: .utf8)!
        
        URLProtocolMock.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (mockData, response, nil)
        }
        
        let result = try await apiService.perform(
            ConferenceAPI.getConferences,
            decoding: ConferenceListResponse.self
        )
        
        XCTAssertEqual(result.total, 1)
        XCTAssertEqual(result.conferences.count, 1)
        XCTAssertEqual(result.conferences.first?.name, "Test Conference")
    }
}

// MARK: - Mock Auth Provider for Testing

class MockAuthProvider: AuthProviderProtocol {
    var token: String?
    var shouldRefreshSucceed = true
    var refreshCallCount = 0
    
    func getBearerToken() -> String? {
        return token.map { "Bearer \\($0)" }
    }
    
    func refreshToken() async throws -> String {
        refreshCallCount += 1
        if shouldRefreshSucceed {
            token = "new_token_\\(refreshCallCount)"
            return token!
        } else {
            throw NetworkError.tokenRefreshFailed
        }
    }
    
    var isRefreshing: Bool = false
}

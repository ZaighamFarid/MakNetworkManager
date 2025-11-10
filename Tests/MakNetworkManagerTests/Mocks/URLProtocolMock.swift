//
//  URLProtocolMock.swift
//  MakNetworkManagerTests
//
//  Mock URLProtocol for intercepting network requests in tests
//

import Foundation

class URLProtocolMock: URLProtocol {
    static var mockResponses: [URL: (data: Data?, response: HTTPURLResponse?, error: Error?)] = [:]
    static var requestHandler: ((URLRequest) throws -> (Data?, HTTPURLResponse?, Error?))?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        if let handler = URLProtocolMock.requestHandler {
            do {
                let (data, response, error) = try handler(request)
                
                if let error = error {
                    client?.urlProtocol(self, didFailWithError: error)
                } else {
                    if let response = response {
                        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    }
                    if let data = data {
                        client?.urlProtocol(self, didLoad: data)
                    }
                    client?.urlProtocolDidFinishLoading(self)
                }
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        } else if let url = request.url, let mock = URLProtocolMock.mockResponses[url] {
            if let error = mock.error {
                client?.urlProtocol(self, didFailWithError: error)
            } else {
                if let response = mock.response {
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                }
                if let data = mock.data {
                    client?.urlProtocol(self, didLoad: data)
                }
                client?.urlProtocolDidFinishLoading(self)
            }
        }
    }
    
    override func stopLoading() {
        // Nothing to do here
    }
    
    static func reset() {
        mockResponses = [:]
        requestHandler = nil
    }
}

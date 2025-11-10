//
//  ConferenceAPI.swift
//  MakNetworkManager
//
//  Example API endpoint definitions
//  Replace with your own API endpoints in your project
//

import Foundation

/// Example API endpoints for Conference operations
/// This demonstrates how to implement APIRequest protocol
public enum ConferenceAPI: APIRequest {
    case getConferences
    case getConference(id: Int)
    case createConference(name: String, date: String)
    case updateConference(id: Int, name: String)
    case deleteConference(id: Int)
    
    public var baseURL: URL {
        // This should come from NetworkConfiguration in real usage
        // For demonstration purposes, we'll use a placeholder
        return URL(string: "https://api.example.com/v1/")!
    }
    
    public var path: String {
        switch self {
        case .getConferences:
            return "conferences"
        case .getConference(let id):
            return "conferences/\(id)"
        case .createConference:
            return "conferences"
        case .updateConference(let id, _):
            return "conferences/\(id)"
        case .deleteConference(let id):
            return "conferences/\(id)"
        }
    }
    
    public var method: HTTPMethod {
        switch self {
        case .getConferences, .getConference:
            return .get
        case .createConference:
            return .post
        case .updateConference:
            return .put
        case .deleteConference:
            return .delete
        }
    }
    
    public var parameters: [String: Any]? {
        switch self {
        case .createConference(let name, let date):
            return ["name": name, "date": date]
        case .updateConference(_, let name):
            return ["name": name]
        default:
            return nil
        }
    }
    
    public var requiresAuthToken: Bool {
        switch self {
        case .getConferences, .getConference:
            return false // Public endpoints
        case .createConference, .updateConference, .deleteConference:
            return true // Requires authentication
        }
    }
}

/// Example response model
public struct Conference: Codable {
    public let id: Int
    public let name: String
    public let date: String
    public let location: String?
    
    public init(id: Int, name: String, date: String, location: String? = nil) {
        self.id = id
        self.name = name
        self.date = date
        self.location = location
    }
}

/// Example list response
public struct ConferenceListResponse: Codable {
    public let conferences: [Conference]
    public let total: Int
    
    public init(conferences: [Conference], total: Int) {
        self.conferences = conferences
        self.total = total
    }
}

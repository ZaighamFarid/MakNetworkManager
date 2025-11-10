//
//  ConferenceService.swift
//  MakNetworkManager
//
//  Example service layer demonstrating how to use the SDK
//

import Foundation

/// Example service layer for Conference operations
/// This demonstrates best practices for using MakNetworkManager SDK
public class ConferenceService {
    private let apiService: APIService
    
    public init(apiService: APIService) {
        self.apiService = apiService
    }
    
    /// Fetch all conferences
    /// - Returns: Array of conferences
    /// - Throws: NetworkError if request fails
    public func getConferences() async throws -> [Conference] {
        let response = try await apiService.perform(
            ConferenceAPI.getConferences,
            decoding: ConferenceListResponse.self
        )
        return response.conferences
    }
    
    /// Fetch a specific conference by ID
    /// - Parameter id: Conference ID
    /// - Returns: Conference object
    /// - Throws: NetworkError if request fails
    public func getConference(id: Int) async throws -> Conference {
        return try await apiService.perform(
            ConferenceAPI.getConference(id: id),
            decoding: Conference.self
        )
    }
    
    /// Create a new conference
    /// - Parameters:
    ///   - name: Conference name
    ///   - date: Conference date
    /// - Returns: Created conference
    /// - Throws: NetworkError if request fails
    public func createConference(name: String, date: String) async throws -> Conference {
        return try await apiService.perform(
            ConferenceAPI.createConference(name: name, date: date),
            decoding: Conference.self
        )
    }
    
    /// Update an existing conference
    /// - Parameters:
    ///   - id: Conference ID
    ///   - name: New conference name
    /// - Returns: Updated conference
    /// - Throws: NetworkError if request fails
    public func updateConference(id: Int, name: String) async throws -> Conference {
        return try await apiService.perform(
            ConferenceAPI.updateConference(id: id, name: name),
            decoding: Conference.self
        )
    }
    
    /// Delete a conference
    /// - Parameter id: Conference ID
    /// - Throws: NetworkError if request fails
    public func deleteConference(id: Int) async throws {
        _ = try await apiService.perform(ConferenceAPI.deleteConference(id: id))
    }
}

// MARK: - Closure-based API (for backward compatibility)

public extension ConferenceService {
    /// Fetch all conferences (closure-based)
    /// - Parameters:
    ///   - success: Success handler with conferences array
    ///   - failure: Failure handler with error
    func getConferences(
        success: @escaping ([Conference]) -> Void,
        failure: @escaping (NetworkError) -> Void
    ) {
        Task {
            do {
                let conferences = try await getConferences()
                await MainActor.run {
                    success(conferences)
                }
            } catch let error as NetworkError {
                await MainActor.run {
                    failure(error)
                }
            } catch {
                await MainActor.run {
                    failure(.unknown(error.localizedDescription))
                }
            }
        }
    }
}

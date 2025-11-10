//
//  ReachabilityProtocol.swift
//  MakNetworkManager
//
//  Protocol for network reachability monitoring
//

import Foundation

/// Network connection status
public enum NetworkStatus {
    case unavailable
    case wifi
    case cellular
}

/// Protocol for monitoring network reachability
public protocol ReachabilityProtocol {
    /// Current network status
    var status: NetworkStatus { get }
    
    /// Check if network is reachable
    var isReachable: Bool { get }
    
    /// Start monitoring network status
    func startMonitoring()
    
    /// Stop monitoring network status
    func stopMonitoring()
}

//
//  Reachability.swift
//  MakNetworkManager
//
//  Network reachability monitoring using NWPathMonitor
//

import Foundation
import Network

/// Default implementation of ReachabilityProtocol using NWPathMonitor
public class Reachability: ReachabilityProtocol {
    private let monitor: NWPathMonitor
    private let queue: DispatchQueue
    private var currentStatus: NetworkStatus = .unavailable
    
    public var status: NetworkStatus {
        return currentStatus
    }
    
    public var isReachable: Bool {
        return currentStatus != .unavailable
    }
    
    public init(queue: DispatchQueue = DispatchQueue(label: "com.networkcore.reachability")) {
        self.monitor = NWPathMonitor()
        self.queue = queue
    }
    
    public func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            if path.status == .satisfied {
                if path.usesInterfaceType(.wifi) {
                    self.currentStatus = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self.currentStatus = .cellular
                } else {
                    self.currentStatus = .wifi // Default to wifi for other connection types
                }
            } else {
                self.currentStatus = .unavailable
            }
            
            // Post notification for status change
            NotificationCenter.default.post(
                name: .networkStatusChanged,
                object: nil,
                userInfo: ["status": self.currentStatus]
            )
        }
        
        monitor.start(queue: queue)
    }
    
    public func stopMonitoring() {
        monitor.cancel()
    }
}

/// Notification name for network status changes
public extension Notification.Name {
    static let networkStatusChanged = Notification.Name("com.networkcore.networkStatusChanged")
}

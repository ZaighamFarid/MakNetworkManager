//
//  LoggerProtocol.swift
//  MakNetworkManager
//
//  Protocol for abstracting logging and analytics
//

import Foundation

/// Protocol for logging and analytics abstraction
/// Implement this protocol to provide custom logging behavior
public protocol LoggerProtocol {
    /// Log a debug message
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: Source file (default: #file)
    ///   - function: Function name (default: #function)
    ///   - line: Line number (default: #line)
    func debug(_ message: String, file: String, function: String, line: Int)
    
    /// Log an info message
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: Source file (default: #file)
    ///   - function: Function name (default: #function)
    ///   - line: Line number (default: #line)
    func info(_ message: String, file: String, function: String, line: Int)
    
    /// Log an error message
    /// - Parameters:
    ///   - message: The message to log
    ///   - error: Optional associated error
    ///   - file: Source file (default: #file)
    ///   - function: Function name (default: #function)
    ///   - line: Line number (default: #line)
    func error(_ message: String, error: Error?, file: String, function: String, line: Int)
    
    /// Log a network event
    /// - Parameters:
    ///   - event: Event name
    ///   - parameters: Additional parameters
    func logNetworkEvent(_ event: String, parameters: [String: Any])
}

/// Default implementation of LoggerProtocol using print statements
public class DefaultLogger: LoggerProtocol {
    private let isEnabled: Bool
    
    public init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }
    
    public func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard isEnabled else { return }
        let fileName = (file as NSString).lastPathComponent
        print("🔍 DEBUG [\(fileName):\(line)] \(function) - \(message)")
    }
    
    public func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard isEnabled else { return }
        let fileName = (file as NSString).lastPathComponent
        print("ℹ️ INFO [\(fileName):\(line)] \(function) - \(message)")
    }
    
    public func error(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        guard isEnabled else { return }
        let fileName = (file as NSString).lastPathComponent
        var errorMessage = "❌ ERROR [\(fileName):\(line)] \(function) - \(message)"
        if let error = error {
            errorMessage += " | Error: \(error.localizedDescription)"
        }
        print(errorMessage)
    }
    
    public func logNetworkEvent(_ event: String, parameters: [String: Any]) {
        guard isEnabled else { return }
        print("📡 NETWORK EVENT: \(event) - \(parameters)")
    }
}

//
//  VouchedLogger.swift
//  Vouched
//
//  Created by Marcus Oliver on 8/7/20.
//

import Foundation
import os

public enum LogDestination {
    case xcode
    case console
    case none
}

public enum LogLevel : Int {
    case debug = 0
    case info = 1
    case error = 2
}

// Singleton used to log any information that pertains to Vouched
public class VouchedLogger {
    
    public static let shared: VouchedLogger = VouchedLogger(destination: .none, level: .error)

    private static let VOUCHED_LOG = OSLog(subsystem: "id.vouched.logger", category: "Vouched SDK")
    private static let DEBUG: String = "DEBUG"
    private static let INFO: String = "INFO"
    private static let ERROR: String = "ERROR"

    private var destination: LogDestination
    private var level: LogLevel
    private var configured: Bool = false
    private let formatter = DateFormatter()
    
    private init(destination: LogDestination, level: LogLevel) {
        self.destination = destination
        self.level = level
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    }
    
    // MARK: - public methods
    public func configure(destination: LogDestination, level: LogLevel) {
        if self.configured {
            return
        }
        self.destination = destination
        self.level = level
        self.configured = true
        
        VouchedLogger.shared.info(configureMessage())
    }
    
    // MARK: - internal methods
    func debug(_ message: String) {
        return logIt(message, .debug, .debug, VouchedLogger.DEBUG)
    }
    
    func info(_ message: String) {
        return logIt(message, .info, .info, VouchedLogger.INFO)
    }
    
    func error(_ message: String) {
        return logIt(message, .error, .error, VouchedLogger.ERROR)
    }
    
    // MARK: - private methods
    private func logIt(_ message: String, _ level: LogLevel, _ osLogLevel: OSLogType, _ levelStr: String) {
        if !shouldLogIt(level: level) {
            return
        }
        
        if self.destination == .xcode {
            let timestamp = formatter.string(from: Date())
            print("\(timestamp) \(levelStr) - \(message)")
        }
        else if self.destination == .console {
            os_log("%@", log: VouchedLogger.VOUCHED_LOG, type: osLogLevel, message)
        }
    }
    
    private func shouldLogIt(level: LogLevel) -> Bool {
        return self.destination != .none && self.level.rawValue <= level.rawValue
    }
    
    private func configureMessage() -> String {
        if self.destination == .none {
            return "VouchedLogger configured to not log anything."
        }
        let levels:[LogLevel: String] = [
            .debug: "error, info and debug",
            .info: "error and info",
            .error: "error"
        ]
        let dests:[LogDestination: String] = [
            .xcode: "Xcode Output",
            .console: "Console Application"
        ]
        
        return "VouchedLogger configured to write \(levels[self.level]!) logs to \(dests[self.destination]!)"
    }
}

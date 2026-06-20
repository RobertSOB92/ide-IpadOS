//
//  Logger.swift
//  IDEApp
//
//  Created by IDEApp Team
//

import Foundation
import os.log

/// App-wide logger
class Logger {
    static let shared = Logger()
    
    private let osLog: OSLog
    
    private init() {
        self.osLog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.ideapp", category: "general")
    }
    
    // MARK: - Logging Methods
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        os_log(.debug, log: osLog, "[DEBUG] [%{public}@:%d %{public}@] %{public}@",
               fileName, line, function, message)
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        os_log(.info, log: osLog, "[INFO] [%{public}@:%d %{public}@] %{public}@",
               fileName, line, function, message)
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        os_log(.default, log: osLog, "[WARNING] [%{public}@:%d %{public}@] %{public}@",
               fileName, line, function, message)
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        os_log(.error, log: osLog, "[ERROR] [%{public}@:%d %{public}@] %{public}@",
               fileName, line, function, message)
    }
    
    func fault(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        os_log(.fault, log: osLog, "[FAULT] [%{public}@:%d %{public}@] %{public}@",
               fileName, line, function, message)
    }
    
    // MARK: - Error Logging
    
    func error(_ error: Error, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        os_log(.error, log: osLog, "[ERROR] [%{public}@:%d %{public}@] %{public}@",
               fileName, line, function, error.localizedDescription)
    }
    
    // MARK: - Convenience Methods
    
    func logFileOperation(_ operation: String, path: String, success: Bool) {
        if success {
            info("File operation '\(operation)' succeeded: \(path)")
        } else {
            error("File operation '\(operation)' failed: \(path)")
        }
    }
    
    func logGitOperation(_ operation: String, repository: String, success: Bool) {
        if success {
            info("Git operation '\(operation)' succeeded in: \(repository)")
        } else {
            error("Git operation '\(operation)' failed in: \(repository)")
        }
    }
    
    func logNetworkRequest(_ endpoint: String, statusCode: Int?) {
        if let code = statusCode {
            info("Network request to '\(endpoint)' returned status: \(code)")
        } else {
            info("Network request to '\(endpoint)' initiated")
        }
    }
}

// MARK: - Global Functions

/// Global debug logging function
func logDebug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.debug(message, file: file, function: function, line: line)
}

/// Global info logging function
func logInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.info(message, file: file, function: function, line: line)
}

/// Global warning logging function
func logWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.warning(message, file: file, function: function, line: line)
}

/// Global error logging function
func logError(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.error(message, file: file, function: function, line: line)
}

/// Global error object logging function
func logError(_ error: Error, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.error(error, file: file, function: function, line: line)
}

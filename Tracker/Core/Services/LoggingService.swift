import Foundation
import Logging

enum LoggingService {
    private static let lock = NSLock()
    private static var isConfigured = false
    
    static func bootstrapIfNeeded(logLevel: Logger.Level = .info) {
        lock.lock()
        defer { lock.unlock() }
        
        guard isConfigured == false else { return }
        
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = logLevel
            return handler
        }
        
        isConfigured = true
    }
    
    static func makeLogger(label: String, logLevel: Logger.Level = .info) -> Logger {
        bootstrapIfNeeded(logLevel: logLevel)
        var logger = Logger(label: label)
        logger.logLevel = logLevel
        return logger
    }
}


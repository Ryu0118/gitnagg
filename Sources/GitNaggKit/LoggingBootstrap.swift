import Logging

/// Configures the global logging system with a stderr handler at the given level.
package func bootstrapLogging(level: Logger.Level = .info) {
    LoggingSystem.bootstrap { label in
        var handler = StreamLogHandler.standardError(label: label)
        handler.logLevel = level
        return handler
    }
}

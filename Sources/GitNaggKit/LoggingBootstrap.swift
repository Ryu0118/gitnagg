import Logging

package func bootstrapLogging(level: Logger.Level = .info) {
    LoggingSystem.bootstrap { label in
        var handler = GitNaggLogHandler(label: label, metadataProvider: nil)
        handler.logLevel = level
        return handler
    }
}

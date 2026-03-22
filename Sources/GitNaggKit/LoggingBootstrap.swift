import Logging

/// Configures the global logging system with a stderr handler at the given level.
package func bootstrapLogging(level: Logger.Level = .info) {
    LoggingSystem.bootstrap(
        { label, metadataProvider in
            var handler = GitNaggLogHandler(label: label, metadataProvider: metadataProvider)
            handler.logLevel = level
            return handler
        },
        metadataProvider: nil
    )
}

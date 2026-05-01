import Logging

/// Namespace for logging bootstrap utilities.
package enum LoggingBootstrap {
    /// Bootstraps the logging system with a ``GitNaggLogHandler`` at the given level.
    package static func bootstrap(level: Logger.Level = .info) {
        LoggingSystem.bootstrap { label in
            var handler = GitNaggLogHandler(label: label, metadataProvider: nil)
            handler.logLevel = level
            return handler
        }
    }
}

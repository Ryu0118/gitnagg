import Foundation
import Logging

/// A `LogHandler` that routes plain and stdout-targeted messages without log-level prefixes.
package struct GitNaggLogHandler: LogHandler {
    /// Metadata key used to request plain (no prefix) stderr output.
    package static let plainOutputMetadataKey = "gitnagg_output"
    /// Metadata value paired with ``plainOutputMetadataKey`` to request plain stderr output.
    package static let plainOutputMetadataValue = "plain"
    /// Metadata key used to route a message to stdout instead of stderr.
    package static let stdoutOutputMetadataKey = "gitnagg_stdout"
    /// Metadata value paired with ``stdoutOutputMetadataKey`` to route output to stdout.
    package static let stdoutOutputMetadataValue = "stdout"

    private var handler: StreamLogHandler

    /// Creates a handler that writes to stderr by default.
    package init(label: String, metadataProvider: Logger.MetadataProvider?) {
        handler = StreamLogHandler.standardError(label: label, metadataProvider: metadataProvider)
    }

    /// The minimum log level passed through to the underlying handler.
    package var logLevel: Logger.Level {
        get { handler.logLevel }
        set { handler.logLevel = newValue }
    }

    /// The metadata provider forwarded to the underlying handler.
    package var metadataProvider: Logger.MetadataProvider? {
        get { handler.metadataProvider }
        set { handler.metadataProvider = newValue }
    }

    /// The metadata dictionary forwarded to the underlying handler.
    package var metadata: Logger.Metadata {
        get { handler.metadata }
        set { handler.metadata = newValue }
    }

    /// Accesses metadata values by key, forwarded to the underlying handler.
    package subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get { handler[metadataKey: metadataKey] }
        set { handler[metadataKey: metadataKey] = newValue }
    }

    /// Handles a log event, routing plain or stdout messages before falling through to the default handler.
    package func log(event: LogEvent) {
        if Self.shouldEmitStdoutMessage(event.metadata) {
            Self.writeStdoutMessage(event.message.description)
            return
        }

        if Self.shouldEmitPlainMessage(event.metadata) {
            Self.writePlainMessage(event.message.description)
            return
        }

        handler.log(event: event)
    }

    private static func shouldEmitPlainMessage(_ metadata: Logger.Metadata?) -> Bool {
        matches(metadata, key: plainOutputMetadataKey, value: plainOutputMetadataValue)
    }

    private static func shouldEmitStdoutMessage(_ metadata: Logger.Metadata?) -> Bool {
        matches(metadata, key: stdoutOutputMetadataKey, value: stdoutOutputMetadataValue)
    }

    private static func matches(_ metadata: Logger.Metadata?, key: String, value: String) -> Bool {
        guard let entry = metadata?[key] else { return false }
        switch entry {
        case let .string(string): return string == value
        case let .stringConvertible(stringConvertible): return stringConvertible.description == value
        default: return false
        }
    }

    private static func writePlainMessage(_ message: String) {
        FileHandle.standardError.write(Data("\(message)\n".utf8))
    }

    private static func writeStdoutMessage(_ message: String) {
        FileHandle.standardOutput.write(Data("\(message)\n".utf8))
    }
}

package extension Logger.Metadata {
    static let plainOutput: Self = [
        GitNaggLogHandler.plainOutputMetadataKey: .string(GitNaggLogHandler.plainOutputMetadataValue),
    ]

    static let stdoutOutput: Self = [
        GitNaggLogHandler.stdoutOutputMetadataKey: .string(GitNaggLogHandler.stdoutOutputMetadataValue),
    ]
}

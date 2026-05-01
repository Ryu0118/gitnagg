import Foundation
import Logging

/// A log handler that routes plain user-facing nags to stderr and hook JSON to stdout.
package struct GitNaggLogHandler: LogHandler {
    package static let plainOutputMetadataKey = "gitnagg_output"
    package static let plainOutputMetadataValue = "plain"
    package static let stdoutOutputMetadataKey = "gitnagg_stdout"
    package static let stdoutOutputMetadataValue = "stdout"

    private var handler: StreamLogHandler

    package init(label: String, metadataProvider: Logger.MetadataProvider?) {
        handler = StreamLogHandler.standardError(label: label, metadataProvider: metadataProvider)
    }

    package var logLevel: Logger.Level {
        get { handler.logLevel }
        set { handler.logLevel = newValue }
    }

    package var metadataProvider: Logger.MetadataProvider? {
        get { handler.metadataProvider }
        set { handler.metadataProvider = newValue }
    }

    package var metadata: Logger.Metadata {
        get { handler.metadata }
        set { handler.metadata = newValue }
    }

    package subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get { handler[metadataKey: metadataKey] }
        set { handler[metadataKey: metadataKey] = newValue }
    }

    // swiftlint:disable:next function_parameter_count
    package func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        if Self.shouldEmitStdoutMessage(metadata) {
            Self.writeStdoutMessage(message.description)
            return
        }

        if Self.shouldEmitPlainMessage(metadata) {
            Self.writePlainMessage(message.description)
            return
        }

        handler.log(
            level: level,
            message: message,
            metadata: metadata,
            source: source,
            file: file,
            function: function,
            line: line
        )
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

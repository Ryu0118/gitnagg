import Foundation
import Logging

/// A stderr log handler that can emit plain message-only output for user-facing nags.
package struct GitNaggLogHandler: LogHandler {
    package static let plainOutputMetadataKey = "gitnagg_output"
    package static let plainOutputMetadataValue = "plain"

    private var handler: StreamLogHandler

    package init(label: String, metadataProvider: Logger.MetadataProvider?) {
        self.handler = StreamLogHandler.standardError(label: label, metadataProvider: metadataProvider)
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

    package func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
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
        guard let value = metadata?[plainOutputMetadataKey] else {
            return false
        }

        switch value {
        case .string(let string):
            return string == plainOutputMetadataValue
        case .stringConvertible(let stringConvertible):
            return stringConvertible.description == plainOutputMetadataValue
        default:
            return false
        }
    }

    private static func writePlainMessage(_ message: String) {
        guard let data = "\(message)\n".data(using: .utf8) else {
            return
        }
        FileHandle.standardError.write(data)
    }
}

package extension Logger.Metadata {
    static let plainOutput: Self = [
        GitNaggLogHandler.plainOutputMetadataKey: .string(GitNaggLogHandler.plainOutputMetadataValue),
    ]
}

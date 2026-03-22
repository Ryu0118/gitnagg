import Logging

/// Shared logger for gitnagg. Bootstrap must be called before use.
package nonisolated(unsafe) var logger = Logger(label: "gitnagg")

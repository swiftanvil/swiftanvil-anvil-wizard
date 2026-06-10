import Foundation

/// Errors that can occur during wizard execution.
public enum WizardError: Error, Sendable, Equatable {
    /// The user cancelled the wizard (e.g. Ctrl+C).
    case cancelled
    /// A required answer was not provided.
    case missingAnswer(key: String)
    /// The stored answer could not be cast to the requested type.
    case typeMismatch(key: String, expected: String, actual: String)
    /// Terminal I/O failed.
    case ioError
    /// Validation failed for a prompt.
    case validationFailed(message: String)
}

/// An error produced by prompt validation.
public struct ValidationError: Error, Sendable {
    public let message: String
    public init(_ message: String) {
        self.message = message
    }
}

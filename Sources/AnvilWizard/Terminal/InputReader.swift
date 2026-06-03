import Foundation

/// Reads input from the user.
public protocol InputReader: Sendable {
    /// Reads a single keypress and returns its character code.
    func readKey() async throws -> KeyPress
    /// Reads a line of text (for non-interactive mode).
    func readLine() async throws -> String?
}

/// Represents a keypress from the user.
public enum KeyPress: Sendable {
    case character(Character)
    case up
    case down
    case enter
    case space
    case escape
    case backspace
    case ctrlC
    case ctrlD
    case unknown
}

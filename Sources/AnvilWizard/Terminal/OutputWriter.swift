import Foundation

/// Writes output to the terminal.
public protocol OutputWriter: Sendable {
    /// Writes a string without a newline.
    func write(_ string: String) async
    /// Writes a string followed by a newline.
    func writeLine(_ string: String) async
    /// Clears the current line.
    func clearLine() async
    /// Moves the cursor up one line.
    func moveUp() async
}

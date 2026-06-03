import Foundation

/// A prompt that asks the user a question and returns a typed answer.
public protocol Prompt<T>: Sendable {
    associatedtype T: Sendable
    /// Asks the prompt using the given I/O channels.
    func ask(reader: any InputReader, writer: any OutputWriter) async throws -> T
}

import Foundation

/// A prompt that asks for a yes/no confirmation.
public struct ConfirmPrompt: Prompt {
    public let question: String
    public let defaultValue: Bool
    
    /// Creates a confirmation prompt.
    /// - Parameters:
    ///   - question: The question to display.
    ///   - default: The default value if user presses Enter.
    public init(_ question: String, default defaultValue: Bool = false) {
        self.question = question
        self.defaultValue = defaultValue
    }
    
    public func ask(reader: any InputReader, writer: any OutputWriter) async throws -> Bool {
        let defaultHint = defaultValue ? "Y/n" : "y/N"
        await writer.write("\(question) [\(defaultHint)]: ")
        
        guard let line = try await reader.readLine() else {
            throw WizardError.cancelled
        }
        
        let input = line.trimmingCharacters(in: .whitespaces).lowercased()
        
        if input.isEmpty {
            return defaultValue
        }
        
        switch input {
        case "y", "yes": return true
        case "n", "no": return false
        default:
            await writer.writeLine("Please answer yes or no.")
            return try await ask(reader: reader, writer: writer)
        }
    }
}

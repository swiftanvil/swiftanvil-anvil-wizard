import Foundation

/// A prompt that asks for free-text input with optional validation.
public struct TextPrompt: Prompt {
    public let question: String
    public let defaultValue: String?
    private let validator: (@Sendable (String) -> Result<String, ValidationError>)?

    /// Creates a text prompt.
    /// - Parameters:
    ///   - question: The question to display.
    ///   - defaultValue: Optional default value if user presses Enter without typing.
    ///   - validator: Optional validation closure.
    public init(
        _ question: String,
        default defaultValue: String? = nil,
        validator: (@Sendable (String) -> Result<String, ValidationError>)? = nil
    ) {
        self.question = question
        self.defaultValue = defaultValue
        self.validator = validator
    }

    /// Adds a validation rule to this prompt.
    public func validate(_ closure: @escaping @Sendable (String) -> Result<String, ValidationError>) -> TextPrompt {
        TextPrompt(question, default: defaultValue, validator: closure)
    }

    /// Adds a simple boolean validation rule.
    public func validate(_ closure: @escaping @Sendable (String) -> Bool) -> TextPrompt {
        validate { input in
            closure(input) ? .success(input) : .failure(ValidationError("Invalid input"))
        }
    }

    public func ask(reader: any InputReader, writer: any OutputWriter) async throws -> String {
        while true {
            await writer.write(question)
            if let defaultValue {
                await writer.write(" [\(defaultValue)]")
            }
            await writer.write(": ")

            guard let line = try await reader.readLine() else {
                throw WizardError.cancelled
            }

            let input = line.isEmpty ? (defaultValue ?? "") : line

            if let validator {
                switch validator(input) {
                case let .success(validated):
                    return validated
                case let .failure(error):
                    await writer.writeLine("Error: \(error.message)")
                    continue
                }
            }

            return input
        }
    }
}

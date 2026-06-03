import Foundation

/// A prompt that asks the user to choose one option from a list.
public struct ChoicePrompt<T: Sendable & CustomStringConvertible>: Prompt {
    public let question: String
    public let options: [T]
    
    /// Creates a choice prompt.
    /// - Parameters:
    ///   - question: The question to display.
    ///   - options: The list of options to choose from.
    public init(_ question: String, options: [T]) {
        self.question = question
        self.options = options
    }
    
    public func ask(reader: any InputReader, writer: any OutputWriter) async throws -> T {
        guard !options.isEmpty else {
            throw WizardError.validationFailed(message: "No options provided")
        }
        
        var selectedIndex = 0
        
        // Render initial state
        await render(writer: writer, selectedIndex: selectedIndex)
        
        while true {
            let key = try await reader.readKey()
            
            switch key {
            case .up:
                selectedIndex = max(0, selectedIndex - 1)
                await rerender(writer: writer, selectedIndex: selectedIndex)
            case .down:
                selectedIndex = min(options.count - 1, selectedIndex + 1)
                await rerender(writer: writer, selectedIndex: selectedIndex)
            case .enter:
                await clearOptions(writer: writer)
                return options[selectedIndex]
            case .ctrlC, .ctrlD:
                throw WizardError.cancelled
            default:
                break
            }
        }
    }
    
    private func render(writer: any OutputWriter, selectedIndex: Int) async {
        await writer.writeLine(question)
        for (index, option) in options.enumerated() {
            let prefix = index == selectedIndex ? "> " : "  "
            await writer.writeLine("\(prefix)\(option)")
        }
    }
    
    private func rerender(writer: any OutputWriter, selectedIndex: Int) async {
        // Move cursor up to the question line
        for _ in 0..<options.count {
            await writer.moveUp()
            await writer.clearLine()
        }
        await writer.moveUp()
        await writer.clearLine()
        
        // Re-render
        await render(writer: writer, selectedIndex: selectedIndex)
    }
    
    private func clearOptions(writer: any OutputWriter) async {
        for _ in 0..<options.count {
            await writer.moveUp()
            await writer.clearLine()
        }
        await writer.moveUp()
        await writer.clearLine()
    }
}

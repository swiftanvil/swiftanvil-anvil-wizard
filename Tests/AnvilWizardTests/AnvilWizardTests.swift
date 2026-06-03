import Foundation
import Testing
@testable import AnvilWizard

// MARK: - Mock I/O

actor MockInputReader: InputReader {
    private var inputs: [String]
    private var keys: [KeyPress]
    private var keyIndex = 0
    private var lineIndex = 0
    
    init(inputs: [String] = [], keys: [KeyPress] = []) {
        self.inputs = inputs
        self.keys = keys
    }
    
    func readKey() async throws -> KeyPress {
        guard keyIndex < keys.count else { return .ctrlD }
        let key = keys[keyIndex]
        keyIndex += 1
        return key
    }
    
    func readLine() async throws -> String? {
        guard lineIndex < inputs.count else { return nil }
        let line = inputs[lineIndex]
        lineIndex += 1
        return line
    }
}

actor MockOutputWriter: OutputWriter {
    var lines: [String] = []
    var rawOutput: String = ""
    
    func write(_ string: String) async {
        rawOutput += string
    }
    
    func writeLine(_ string: String) async {
        lines.append(string)
        rawOutput += string + "\n"
    }
    
    func clearLine() async {}
    func moveUp() async {}
}

// MARK: - WizardAnswers Tests

@Suite("WizardAnswers")
struct WizardAnswersTests {
    @Test("stores and retrieves typed value")
    func storeRetrieve() throws {
        var answers = WizardAnswers()
        answers.set("name", value: "SwiftAnvil")
        let name: String = try answers.get("name")
        #expect(name == "SwiftAnvil")
    }
    
    @Test("throws missingAnswer for unknown key")
    func missingAnswer() {
        let answers = WizardAnswers()
        #expect(throws: WizardError.missingAnswer(key: "unknown")) {
            let _: String = try answers.get("unknown")
        }
    }
    
    @Test("throws typeMismatch for wrong type")
    func typeMismatch() {
        var answers = WizardAnswers()
        answers.set("count", value: 42)
        #expect(throws: WizardError.typeMismatch(key: "count", expected: "String", actual: "Int")) {
            let _: String = try answers.get("count")
        }
    }
    
    @Test("has returns true for existing key")
    func hasExisting() {
        var answers = WizardAnswers()
        answers.set("key", value: true)
        #expect(answers.has("key") == true)
    }
    
    @Test("has returns false for missing key")
    func hasMissing() {
        let answers = WizardAnswers()
        #expect(answers.has("missing") == false)
    }
}

// MARK: - TextPrompt Tests

@Suite("TextPrompt")
struct TextPromptTests {
    @Test("returns user input")
    func basicInput() async throws {
        let reader = MockInputReader(inputs: ["hello"])
        let writer = MockOutputWriter()
        let prompt = TextPrompt("Your name")
        let result = try await prompt.ask(reader: reader, writer: writer)
        #expect(result == "hello")
    }
    
    @Test("uses default when input is empty")
    func defaultValue() async throws {
        let reader = MockInputReader(inputs: [""])
        let writer = MockOutputWriter()
        let prompt = TextPrompt("Your name", default: "Anonymous")
        let result = try await prompt.ask(reader: reader, writer: writer)
        #expect(result == "Anonymous")
    }
    
    @Test("validates input and retries")
    func validationRetry() async throws {
        let reader = MockInputReader(inputs: ["", "valid"])
        let writer = MockOutputWriter()
        let prompt = TextPrompt("Your name").validate { !$0.isEmpty }
        let result = try await prompt.ask(reader: reader, writer: writer)
        #expect(result == "valid")
        let outputLines = await writer.lines
        #expect(outputLines.contains("Error: Invalid input"))
    }
    
    @Test("throws cancelled on EOF")
    func cancelled() async {
        let reader = MockInputReader(inputs: [])
        let writer = MockOutputWriter()
        let prompt = TextPrompt("Your name")
        await #expect(throws: WizardError.cancelled) {
            _ = try await prompt.ask(reader: reader, writer: writer)
        }
    }
}

// MARK: - ConfirmPrompt Tests

@Suite("ConfirmPrompt")
struct ConfirmPromptTests {
    @Test("returns true for yes")
    func yes() async throws {
        let reader = MockInputReader(inputs: ["y"])
        let writer = MockOutputWriter()
        let prompt = ConfirmPrompt("Continue?")
        let result = try await prompt.ask(reader: reader, writer: writer)
        #expect(result == true)
    }
    
    @Test("returns false for no")
    func no() async throws {
        let reader = MockInputReader(inputs: ["n"])
        let writer = MockOutputWriter()
        let prompt = ConfirmPrompt("Continue?")
        let result = try await prompt.ask(reader: reader, writer: writer)
        #expect(result == false)
    }
    
    @Test("uses default when empty")
    func defaultValue() async throws {
        let reader = MockInputReader(inputs: [""])
        let writer = MockOutputWriter()
        let prompt = ConfirmPrompt("Continue?", default: true)
        let result = try await prompt.ask(reader: reader, writer: writer)
        #expect(result == true)
    }
    
    @Test("repeats on invalid input")
    func invalidRetry() async throws {
        let reader = MockInputReader(inputs: ["maybe", "yes"])
        let writer = MockOutputWriter()
        let prompt = ConfirmPrompt("Continue?")
        let result = try await prompt.ask(reader: reader, writer: writer)
        #expect(result == true)
        let outputLines2 = await writer.lines
        #expect(outputLines2.contains("Please answer yes or no."))
    }
}

// MARK: - ChoicePrompt Tests

@Suite("ChoicePrompt")
struct ChoicePromptTests {
    @Test("selects first option with enter")
    func selectFirst() async throws {
        let reader = MockInputReader(keys: [.enter])
        let writer = MockOutputWriter()
        let prompt = ChoicePrompt("Pick one", options: ["A", "B", "C"])
        let result = try await prompt.ask(reader: reader, writer: writer)
        #expect(result == "A")
    }
    
    @Test("navigates down and selects")
    func navigateDown() async throws {
        let reader = MockInputReader(keys: [.down, .enter])
        let writer = MockOutputWriter()
        let prompt = ChoicePrompt("Pick one", options: ["A", "B", "C"])
        let result = try await prompt.ask(reader: reader, writer: writer)
        #expect(result == "B")
    }
    
    @Test("throws cancelled on ctrlC")
    func cancelled() async {
        let reader = MockInputReader(keys: [.ctrlC])
        let writer = MockOutputWriter()
        let prompt = ChoicePrompt("Pick one", options: ["A", "B"])
        await #expect(throws: WizardError.cancelled) {
            _ = try await prompt.ask(reader: reader, writer: writer)
        }
    }
    
    @Test("throws validationFailed for empty options")
    func emptyOptions() async {
        let reader = MockInputReader(keys: [])
        let writer = MockOutputWriter()
        let prompt = ChoicePrompt("Pick one", options: [String]())
        await #expect(throws: WizardError.validationFailed(message: "No options provided")) {
            _ = try await prompt.ask(reader: reader, writer: writer)
        }
    }
}

// MARK: - Wizard Tests

@Suite("Wizard")
struct WizardTests {

    
    @Test("runs non-interactive wizard with all answers")
    func nonInteractive() async throws {
        let wizard = Wizard<ProjectConfig> { answers in
            ProjectConfig(
                name: try answers.get("name"),
                platform: try answers.get("platform"),
                useSwiftUI: try answers.get("useSwiftUI")
            )
        }
        .step(key: "name", prompt: TextPrompt("Name"))
        .step(key: "platform", prompt: ChoicePrompt("Platform", options: ["iOS", "macOS"]))
        .step(key: "useSwiftUI", prompt: ConfirmPrompt("SwiftUI?"))
        
        var answers = WizardAnswers()
        answers.set("name", value: "MyApp")
        answers.set("platform", value: "iOS")
        answers.set("useSwiftUI", value: true)
        
        let config = try await wizard.run(mode: .nonInteractive(answers: answers))
        #expect(config.name == "MyApp")
        #expect(config.platform == "iOS")
        #expect(config.useSwiftUI == true)
    }
    
    @Test("non-interactive throws missingAnswer")
    func nonInteractiveMissing() async {
        let wizard = Wizard<ProjectConfig> { answers in
            ProjectConfig(
                name: try answers.get("name"),
                platform: try answers.get("platform"),
                useSwiftUI: try answers.get("useSwiftUI")
            )
        }
        .step(key: "name", prompt: TextPrompt("Name"))
        .step(key: "platform", prompt: ChoicePrompt("Platform", options: ["iOS"]))
        
        var answers = WizardAnswers()
        answers.set("name", value: "MyApp")
        // Missing "platform"
        
        await #expect(throws: WizardError.missingAnswer(key: "platform")) {
            _ = try await wizard.run(mode: .nonInteractive(answers: answers))
        }
    }
    
    @Test("non-interactive throws typeMismatch")
    func nonInteractiveTypeMismatch() async {
        let wizard = Wizard<ProjectConfig> { answers in
            ProjectConfig(
                name: try answers.get("name"),
                platform: try answers.get("platform"),
                useSwiftUI: try answers.get("useSwiftUI")
            )
        }
        .step(key: "name", prompt: TextPrompt("Name"))
        .step(key: "platform", prompt: ChoicePrompt("Platform", options: ["iOS"]))
        .step(key: "useSwiftUI", prompt: ConfirmPrompt("SwiftUI?"))
        
        var answers = WizardAnswers()
        answers.set("name", value: "MyApp")
        answers.set("platform", value: "iOS")
        answers.set("useSwiftUI", value: "yes") // Wrong type: String instead of Bool
        
        await #expect(throws: WizardError.typeMismatch(key: "useSwiftUI", expected: "Bool", actual: "String")) {
            _ = try await wizard.run(mode: .nonInteractive(answers: answers))
        }
    }
}

// MARK: - Test Helpers

private struct ProjectConfig: Sendable {
    let name: String
    let platform: String
    let useSwiftUI: Bool
}

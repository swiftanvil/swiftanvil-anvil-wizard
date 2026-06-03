import Foundation

/// The mode in which to run a wizard.
public enum WizardRunMode: Sendable {
    /// Interactive mode: prompts the user via terminal.
    case interactive
    /// Non-interactive mode: answers provided programmatically.
    /// Missing answers throw `WizardError.missingAnswer`.
    case nonInteractive(answers: WizardAnswers)
}

/// An interactive wizard that collects typed answers and produces a result.
public struct Wizard<Result: Sendable>: Sendable {
    private let steps: [(key: String, prompt: any Prompt)]
    private let buildResult: @Sendable (WizardAnswers) throws -> Result
    
    /// Creates a new wizard with a result-building closure.
    /// - Parameter buildResult: Closure that constructs the final result from collected answers.
    public init(_ buildResult: @escaping @Sendable (WizardAnswers) throws -> Result) {
        self.steps = []
        self.buildResult = buildResult
    }
    
    private init(
        steps: [(key: String, prompt: any Prompt)],
        buildResult: @escaping @Sendable (WizardAnswers) throws -> Result
    ) {
        self.steps = steps
        self.buildResult = buildResult
    }
    
    /// Adds a step to the wizard.
    /// - Parameters:
    ///   - key: The answer key used to retrieve the result later.
    ///   - prompt: The prompt to display for this step.
    /// - Returns: A new wizard with the step appended.
    public func step<T: Sendable>(key: String, prompt: any Prompt<T>) -> Wizard<Result> {
        var newSteps = steps
        newSteps.append((key, prompt))
        return Wizard(steps: newSteps, buildResult: buildResult)
    }
    
    /// Runs the wizard in the given mode.
    /// - Parameter mode: The run mode (interactive or non-interactive).
    /// - Returns: The constructed result.
    public func run(mode: WizardRunMode = .interactive) async throws -> Result {
        switch mode {
        case .interactive:
            return try await runInteractive()
        case .nonInteractive(let provided):
            return try await runNonInteractive(provided: provided)
        }
    }
    
    private func runInteractive() async throws -> Result {
        let reader = TerminalInputReader()
        let writer = TerminalOutputWriter()
        var answers = WizardAnswers()
        
        for (key, prompt) in steps {
            // Use existential opening to call the typed ask method
            let value = try await prompt.ask(reader: reader, writer: writer)
            answers.set(key, value: value)
        }
        
        return try buildResult(answers)
    }
    
    private func runNonInteractive(provided: WizardAnswers) async throws -> Result {
        for (key, _) in steps {
            if provided.has(key) { continue }
            throw WizardError.missingAnswer(key: key)
        }
        
        return try buildResult(provided)
    }
}

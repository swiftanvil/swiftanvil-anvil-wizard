# AnvilWizard

Interactive CLI wizard engine for `swiftanvil`. Collect user input through typed prompts and produce structured results.

## Installation

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/swiftanvil/swiftanvil-anvil-wizard", from: "1.0.0"),
]
```

## Quick Start

```swift
import AnvilWizard

struct ProjectConfig: Sendable {
    let name: String
    let platform: String
    let useSwiftUI: Bool
}

let wizard = Wizard<ProjectConfig> { answers in
    ProjectConfig(
        name: try answers.get("name"),
        platform: try answers.get("platform"),
        useSwiftUI: try answers.get("useSwiftUI")
    )
}
.step(key: "name", prompt: TextPrompt("Project name").validate { !$0.isEmpty })
.step(key: "platform", prompt: ChoicePrompt("Platform", options: ["iOS", "macOS", "tvOS"]))
.step(key: "useSwiftUI", prompt: ConfirmPrompt("Use SwiftUI?", default: true))

// Interactive mode
let config = try await wizard.run()

// Non-interactive mode (CI, automation)
var answers = WizardAnswers()
answers.set("name", value: "MyApp")
answers.set("platform", value: "iOS")
answers.set("useSwiftUI", value: true)
let config2 = try await wizard.run(mode: .nonInteractive(answers: answers))
```

## Prompts

| Prompt | Description |
|--------|-------------|
| `TextPrompt` | Free text with optional validation |
| `ConfirmPrompt` | Yes/no with default |
| `ChoicePrompt` | Single selection from list (arrow navigation) |

## Testability

All prompts depend on `InputReader` and `OutputWriter` protocols. Inject mocks for testing:

```swift
let reader = MockInputReader(inputs: ["hello"])
let writer = MockOutputWriter()
let prompt = TextPrompt("Your name")
let result = try await prompt.ask(reader: reader, writer: writer)
```

## Requirements

- macOS 13+
- Swift 6.0+

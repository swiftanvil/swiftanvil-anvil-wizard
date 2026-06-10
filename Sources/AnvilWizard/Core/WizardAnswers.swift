import Foundation

/// Collected answers from a wizard run, with type-safe access.
public struct WizardAnswers: Sendable {
    private var storage: [String: any Sendable] = [:]

    /// Stores an answer for the given key.
    public mutating func set(_ key: String, value: some Sendable) {
        storage[key] = value
    }

    /// Retrieves a typed answer for the given key.
    /// - Throws: `WizardError.missingAnswer` if the key was not collected.
    /// - Throws: `WizardError.typeMismatch` if the stored value cannot be cast to `T`.
    public func get<T: Sendable>(_ key: String) throws -> T {
        guard let raw = storage[key] else {
            throw WizardError.missingAnswer(key: key)
        }
        guard let typed = raw as? T else {
            throw WizardError.typeMismatch(
                key: key,
                expected: String(describing: T.self),
                actual: String(describing: type(of: raw))
            )
        }
        return typed
    }

    /// Returns true if an answer exists for the given key.
    public func has(_ key: String) -> Bool {
        storage[key] != nil
    }
}

import Darwin
import Foundation

/// Reads input from the terminal, supporting raw mode for interactive keypresses.
public struct TerminalInputReader: InputReader {
    private let isTTY: Bool

    public init() {
        isTTY = isatty(STDIN_FILENO) != 0
    }

    public func readKey() async throws -> KeyPress {
        guard isTTY else {
            // Non-TTY: read a line and treat as character or command
            if let line = try await readLine(), let first = line.first {
                return .character(first)
            }
            return .ctrlD
        }

        enableRawMode()
        defer { disableRawMode() }

        var buffer: [UInt8] = [0]
        let count = read(STDIN_FILENO, &buffer, 1)

        guard count > 0 else {
            return .ctrlD
        }

        let byte = buffer[0]

        // Check for escape sequences
        if byte == 0x1B {
            var seq: [UInt8] = [0, 0]
            let seqCount = read(STDIN_FILENO, &seq, 2)
            if seqCount == 2 {
                if seq[0] == 0x5B { // [
                    switch seq[1] {
                    case 0x41: return .up
                    case 0x42: return .down
                    default: return .unknown
                    }
                }
            }
            return .escape
        }

        // Control characters
        if byte == 0x03 { return .ctrlC }
        if byte == 0x04 { return .ctrlD }
        if byte == 0x0D || byte == 0x0A { return .enter }
        if byte == 0x20 { return .space }
        if byte == 0x7F { return .backspace }

        // Regular character
        let scalar = UnicodeScalar(byte)
        return .character(Character(scalar))
    }

    public func readLine() async throws -> String? {
        Swift.readLine()
    }

    // MARK: - Raw Mode

    private func enableRawMode() {
        var raw = termios()
        tcgetattr(STDIN_FILENO, &raw)
        var new = raw
        // Disable echo, canonical mode, and signal generation (ISIG)
        // ISIG must be disabled so Ctrl-C returns byte 0x03 instead of SIGINT
        new.c_lflag &= ~UInt(ECHO | ICANON | ISIG)
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &new)
    }

    private func disableRawMode() {
        var raw = termios()
        tcgetattr(STDIN_FILENO, &raw)
        raw.c_lflag |= UInt(ECHO | ICANON | ISIG)
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
    }
}

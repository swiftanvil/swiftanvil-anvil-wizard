import Foundation

/// Writes ANSI-formatted output to the terminal.
public struct TerminalOutputWriter: OutputWriter {
    public init() {}
    
    public func write(_ string: String) async {
        print(string, terminator: "")
        fflush(stdout)
    }
    
    public func writeLine(_ string: String) async {
        print(string)
    }
    
    public func clearLine() async {
        print("\u{001B}[2K\r", terminator: "")
        fflush(stdout)
    }
    
    public func moveUp() async {
        print("\u{001B}[1A", terminator: "")
        fflush(stdout)
    }
}

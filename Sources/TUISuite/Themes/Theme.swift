import Foundation

public protocol Theme {

    var background: TerminalColor { get }
    var textPrimary: TerminalColor { get }
    var textSecondary: TerminalColor { get }
    var accent: TerminalColor { get }
    var error: TerminalColor { get }
    var border: TerminalColor { get }
}


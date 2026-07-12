import Foundation


enum TerminalControl {
    static func enter() {
        let setupSequence =
        "\u{001B}[?1049h" + // Switch to Alternate Screen Buffer
        "\u{001B}[?25l"   + // Hide the text cursor
        "\u{001B}[2J"     + // Clear the entire screen
        "\u{001B}[H"        // Move cursor to top-left (0,0)
        
        print(setupSequence, terminator: "")
        fflush(stdout)
    }
    static func exit() {
        let restoreSequence =
            "\u{001B}[?25h"   + // Show the text cursor again
            "\u{001B}[?1049l"   // Switch back to Main Screen Buffer (restores history)
        
        print(restoreSequence, terminator: "")
        fflush(stdout)
    }
}

import Foundation

public enum KeyInput : Equatable, CustomStringConvertible {
    case char(Character)
    case fn(Int)
    
    case up,down,left,right
    case home,end,pageUp,pageDown
    case insert,delete
    case escape, enter, backspace, tab
    
    public var description : String {
        switch self {
        case .char(let c):
            return "'\(c)'"
        case .fn(let n):
            return "F\(n)"
        case .up:
            return "↑"
        case .down:
            return "↓"
        case .left:
            return "←"
        case .right:
            return "→"
        default: return String(describing: self).capitalized
        }
    }
    
}

public struct KeyModifiers : OptionSet, CustomStringConvertible, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    
    public static let shift = KeyModifiers(rawValue: 1 << 0)
    public static let alt = KeyModifiers(rawValue: 1 << 1)
    public static let ctrl = KeyModifiers(rawValue: 1 << 2)
    public static let cmd = KeyModifiers(rawValue: 1 << 3)
    
    public var description: String {
        var parts: [String] = []
        if contains(.shift) { parts.append("Shift") }
        if contains(.alt) { parts.append("Alt") }
        if contains(.ctrl) { parts.append("Ctrl") }
        if contains(.cmd) { parts.append("Cmd") }
        return parts.joined(separator: "+")
    }

}

public struct KeyEvent : CustomStringConvertible {
    public let key: KeyInput
    public let modifiers : KeyModifiers
    
    public var description: String {
        return "Key: \(key) [Mods: \(modifiers)]"
    }
}

public enum MouseButton {
    case left,middle,right,scrollUp,scrollDown,none
}

public enum MouseAction {
    case press, release, drag, move
}

public struct MouseEvent : CustomStringConvertible {
    public let button: MouseButton
    public let action: MouseAction
    public let x: Int
    public let y: Int
    public let modifiers: KeyModifiers
    
    public var description: String {
        return "[Mouse \(action) \(button) at (\(x),\(y)) Modifiers \(modifiers)]"
    }
}

public enum InputEvent : CustomStringConvertible  {
    case key(KeyEvent)
    case mouse(MouseEvent)
    case unknown([UInt8])
    
    public var description : String {
        switch self {
        case .key(let e): return e.description
        case .mouse(let e): return e.description
        case .unknown(let data): return "Unknown Bytes: \(data)"
        }
    }
}

extension KeyInput {
    static func from(kittyCode: Int) -> KeyInput {
        switch kittyCode {
        case 13: return .enter
        case 27: return .escape
        case 9: return .tab
        case 127: return .backspace
        case 57356: return .up
        case 57357: return .down
        case 57358: return .left
        case 57359: return .right
        case 57360: return .pageUp
        case 57361: return .pageDown
        case 57362: return .home
        case 57363: return .end
        case 57364: return .insert
        case 57365: return .delete
        case 57376...57387: return .fn(kittyCode - 57376 + 1)
        default:
            if let scalar = UnicodeScalar(kittyCode) {
                return .char(Character(scalar))
            }
            return .char("?")
        }
    }
}

public struct InputParser {
    
    // Handle mouse events
    private static func parseSGRMouse(_ payload: [UInt8]) -> InputEvent? {
        guard let lastByte = payload.last else { return nil }
        let release = (lastByte == 109) // 'm' is button release
        
        guard let data = String(bytes:payload.dropFirst().dropLast(),encoding:.utf8) else { return nil }
        
        let components = data.split(separator: ";").compactMap({ Int($0) })
        guard components.count == 3 else { return nil }
        
        let rawButtonCode = components[0]
        let x = components[1] - 1
        let y = components[2] - 1

        var modifiers = KeyModifiers()
        if (rawButtonCode & 4) != 0 { modifiers.insert(.shift) }
        if (rawButtonCode & 8) != 0 { modifiers.insert(.alt) }
        if (rawButtonCode & 16) != 0 { modifiers.insert(.ctrl) }
        
        let button : MouseButton
        var action : MouseAction = release ? .release : .press
        switch rawButtonCode & 0b11000011 {
        case 0:button = .left
        case 1:button = .middle
        case 2:button = .right
        case 32:button = .left; action = .drag
        case 33:button = .middle; action = .drag
        case 34:button = .right; action = .drag
        case 35:button = .none; action = .move
        case 64:button = .scrollUp;
        case 65:button = .scrollDown;
        default: button = .none
        }
        return .mouse(MouseEvent(button: button, action: action, x: x, y: y, modifiers: modifiers))
                
    }
    
    // Handle Kitty Keyboard (Ghostty etc) for better modifier support
    private static func parseKittyKeyboardEvent(_ payload: [UInt8]) -> InputEvent? {
        guard let data = String(bytes:payload.dropLast(),encoding: .utf8) else { return nil }
        let components = data.split(separator: ";").compactMap({ Int($0) })
        guard !components.isEmpty else { return nil }
        
        let kittyCode = components[0]
        let modCode = components.count > 1 ? components[1] - 1 : 0
        
        var modifiers = KeyModifiers()
        if (modCode & 1) != 0 { modifiers.insert(.shift) }
        if (modCode & 2) != 0 { modifiers.insert(.alt) }
        if (modCode & 4) != 0 { modifiers.insert(.ctrl) }
        if (modCode & 8) != 0 { modifiers.insert(.cmd) }
        
        return .key(KeyEvent(key: .from(kittyCode:kittyCode), modifiers: modifiers))

    }
    
    private static func parseLegacyAnsi(_ payload: [UInt8]) -> InputEvent? {
        guard let data = String(bytes:payload.dropLast(),encoding:.utf8) else { return nil }
        
        var  cleanString = data
        var modifiers = KeyModifiers()
        if data.contains(";") {
            let parts = data.split(separator: ";")
            if parts.count == 2, let lastPart = parts.last {
                let modDigit = lastPart.prefix(1)
                let tailChar = lastPart.suffix(1)
                if let modVal = Int(modDigit) {
                    let modCode = modVal - 1
                    if (modCode & 1) != 0 { modifiers.insert(.shift) }
                    if (modCode & 2) != 0 { modifiers.insert(.alt) }
                    if (modCode & 4) != 0 { modifiers.insert(.ctrl) }
                }
                
                if let firstPartHead = parts.first?.last {
                    cleanString = "\(firstPartHead)\(tailChar)"
                } else {
                    cleanString = String(tailChar)
                }
            }
        }
        
        let key:KeyInput?
        switch cleanString {
        case "A": key = .up
        case "B": key = .down
        case "C": key = .right
        case "D": key = .left
            
        case "1~","H": key = .home
        case "4~","F": key = .end
        case "5~": key = .pageUp
        case "6~": key = .pageDown
            
        case "2~": key = .insert
        case "3~": key = .delete
            
        case "Z": key = .tab;modifiers.insert(.shift)
            
        case "OP","11~": key = .fn(1)
        case "OQ","12~": key = .fn(2)
        case "OR","13~": key = .fn(3)
        case "OS","14~": key = .fn(4)
        case "15~": key = .fn(5)
        case "17~": key = .fn(6)
        case "18~": key = .fn(7)
        case "19~": key = .fn(8)
        case "20~": key = .fn(9)
        case "21~": key = .fn(10)
        case "23~": key = .fn(11)
        case "24~": key = .fn(12)
            
            
        default: key = nil
        }
        if let k = key {
            return .key(KeyEvent(key: k, modifiers: modifiers))
        }
        return nil
    }
    
    private static func parseFallbackAscii(_ buffer: [UInt8]) -> InputEvent? {
        guard !buffer.isEmpty else { return nil }
        switch buffer[0] {
        case 3:return .key(KeyEvent(key: .char("c"), modifiers: [.ctrl]))
        case 9:return .key(KeyEvent(key: .tab, modifiers: []))
        case 10,13:return .key(KeyEvent(key: .enter, modifiers: []))
        case 27:
            if buffer.count == 1 { return .key(KeyEvent(key: .escape, modifiers: [])) }
            let altMap = Character(UnicodeScalar(buffer[1]))
            return .key(KeyEvent(key: .char(altMap), modifiers: [.alt]))
        case 127: return .key(KeyEvent(key: .backspace, modifiers: []))
        case 1...26:
            let char = Character(UnicodeScalar(buffer[0] + 64))
            return  .key(KeyEvent(key: .char(char), modifiers: [.ctrl]))
        default:
            if let str = String(bytes:buffer,encoding: .utf8), let char = str.first {
                var modifiers = KeyModifiers()
                if char.isUppercase { modifiers.insert(.shift) }
                return .key(KeyEvent(key: .char(char), modifiers: modifiers))
            }
        }
        return .unknown(buffer)
    }
    
    public static func parseEvent(from buffer: [UInt8]) -> InputEvent? {
        guard !buffer.isEmpty else { return nil }
        if buffer.count >= 3 && buffer[0] == 27 && buffer[1] == 91 { //ESC[
            let payload = Array(buffer.dropFirst(2))
            
            switch payload.first {
            case 60: return parseSGRMouse(payload)
            case 117: return parseKittyKeyboardEvent(payload)
            default:
                break
            }
            
            if let legacy = parseLegacyAnsi(payload) {
                return legacy
            }
        }
        return parseFallbackAscii(buffer)
    }
}



final class Input {
    private var originalTermios = termios()
    
    func enterRawMode() {
        tcgetattr(STDIN_FILENO, &originalTermios)
        
        var raw = originalTermios
        
        // 2. Flip bits to disable echoing and line-by-line buffering
        raw.c_lflag &= ~tcflag_t(ECHO | ICANON | ISIG | IEXTEN)
        
        // 3. Disable traditional software flow control (Ctrl+S / Ctrl+Q)
        raw.c_iflag &= ~tcflag_t(IXON | ICRNL)
        
        // 3. FIXED: Modify c_cc tuple values safely via memory binding
        // We get a direct pointer to the tuple, bind it as a flat array layout, and write to it.
        withUnsafeMutablePointer(to: &raw.c_cc) { tuplePointer in
            // Bind the tuple pointer to a mutable buffer pointer of raw UInt8 elements
            tuplePointer.withMemoryRebound(to: UInt8.self, capacity: Int(NCCS)) { arrayBuffer in
                // Now you can use standard array subscripts with C constants safely!
                arrayBuffer[Int(VMIN)] = 0
                arrayBuffer[Int(VTIME)] = 0
            }
        }
        
        // Apply configuration instantly
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
        
        // 5. Make STDIN non-blocking
        var flags = fcntl(STDIN_FILENO, F_GETFL, 0)
        flags |= O_NONBLOCK
        _ = fcntl(STDIN_FILENO, F_SETFL, flags)
        
        // 6. Optional: Send ANSI codes to track mouse clicks and movement and also try to enable Kitty Keyboard Protocol and XTerm modifyOtherKeys
        print("\u{001B}[?1000h\u{001B}[?1003h\u{001B}[?1002h\u{001B}[?1006h\u{001B}[>1u\u{001B}[>4;2m", terminator: "")
        fflush(stdout)
    }
    
    func exitRawMode() {
        // Turn off mouse tracking and key modifiers
        print("\u{001B}[<4;2m\u{001B}[<1u\u{001B}[?1006l\u{001B}[?1002l\u{001B}[?1003l\u{001B}[?1000l", terminator: "")
        fflush(stdout)
        
        // Restore original cook configuration
        var t = originalTermios
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &t)
    }
    
    
    public func poll() -> InputEvent? {
        let bufferSize = 256
        var buffer: [UInt8] = .init(repeating: 0, count: bufferSize)
        
        let readCount = read(STDIN_FILENO, &buffer, bufferSize)
        
        guard readCount > 0 else { return nil }
        let activeData = Array(buffer.prefix(readCount))
        return InputParser.parseEvent(from:activeData)
    }
    
    public func waitForInput(timeout:TimeInterval) -> Bool {
        var readfds = fd_set()
               
       // 1. Clear out the fd_set memory block completely by setting it to zero
       readfds = fd_set() // Re-initializing clears the structure cleanly in Swift
       
       // 2. FIXED: Grab the raw mutable pointer of the struct to bind its underlying integers
       withUnsafeMutablePointer(to: &readfds) { structPointer in
           // Bind the struct memory space directly to a mutable pointer of 32-bit integers
           structPointer.withMemoryRebound(to: Int32.self, capacity: MemoryLayout<fd_set>.size / 4) { integerArray in
               let fd = STDIN_FILENO
               
               // Calculate exactly which 32-bit block and which bit position tracks STDIN
               let bitsPerInt: Int32 = 32
               let index = Int(fd / bitsPerInt)
               let bitPosition = fd % bitsPerInt
               
               // Flip the bit to 1 (Equivalent to the C macro FD_SET)
               integerArray[index] |= (1 << bitPosition)
           }
       }
       
       // 3. Convert our Swift TimeInterval into the POSIX timeval structure
       let seconds = Int(floor(timeout))
       let microseconds = Int((timeout - Double(seconds)) * 1_000_000)
       var tv = timeval(tv_sec: seconds, tv_usec: Int32(microseconds))
       
       // 4. select() halts the thread efficiently until data arrives or the timeout expires.
       let result = select(STDIN_FILENO + 1, &readfds, nil, nil, &tv)
       
       return result > 0
    }
}

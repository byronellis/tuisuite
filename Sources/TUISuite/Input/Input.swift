import Foundation

enum InputEvent : Equatable {
    case key(Character)
    case controlKey(ControlKey)
    case mouse(MouseEvent)
    case unknown
}

enum MouseEvent : Equatable {
    case press(button:Int,x:Int,y:Int)
    case release(button:Int,x:Int,y:Int)
    case drag(button:Int,x:Int,y:Int)
}

enum ControlKey : Equatable {
    case up, down, left, right
    case escape, enter, backspace, tab
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
        
        // 6. Optional: Send ANSI codes to track mouse clicks and movement
        print("\u{001B}[?1000h\u{001B}[?1003h\u{001B}[?1002h\u{001B}[?1006h", terminator: "")
        fflush(stdout)
    }
    
    func exitRawMode() {
        // Turn off mouse tracking
        print("\u{001B}[?1006l\u{001B}[?1002l\u{001B}[?1003l\u{001B}[?1000l", terminator: "")
        fflush(stdout)
        
        // Restore original cook configuration
        var t = originalTermios
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &t)
    }
    
    private func parsedEscapeSequence(buffer: [UInt8]) -> InputEvent? {
        if(buffer.count >= 3 && buffer[1] == 91) {
            switch buffer[2] {
            case 68: return .controlKey(.left)
            case 67: return .controlKey(.right)
            case 65: return .controlKey(.up)
            case 66: return .controlKey(.down)
            default: break
            }
        }
        
        if(buffer.count >= 6 && buffer[1] == 91 && buffer[2] == 60) {
            guard let payload = String(bytes:buffer.dropFirst(3),encoding: .ascii) else { return .unknown }
            
            
            let actionChar = payload.last
            let components = payload.split(separator: ";")
            
            if components.count == 3,
               let rawButton = Int(components[0]),
               let x = Int(components[1]),
               let y = Int(components[2]) {
                
                let moving = (rawButton & 32) != 0
                let button = rawButton & ~32
                
                if moving {
                    return .mouse(.drag(button: button, x: x, y: y))
                } else if actionChar == "m" {
                    return .mouse(.release(button: button, x: x, y: y))
                } else {
                    return .mouse(.press(button: button, x: x, y: y))
                }
            }
        }

        return .unknown

    }
    
    public func poll() -> InputEvent? {
        let bufferSize = 128
        var buffer: [UInt8] = .init(repeating: 0, count: bufferSize)
        
        let readCount = read(STDIN_FILENO, &buffer, bufferSize)
        
        guard readCount > 0 else { return nil }
        
        let first = buffer[0]
        if first >= 32 && first <= 126 && readCount == 1{
            return .key(Character(UnicodeScalar(first)))
        }
        switch first {
        case 10, 13: return .controlKey(.enter)
        case 127: return .controlKey(.backspace)
        case 9: return .controlKey(.tab)
        case 27: // Escape Sequence
            if readCount == 1 { return .controlKey(.escape) }
            return parsedEscapeSequence(buffer: Array(buffer[0..<readCount]))
        default:
            return nil
        }
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

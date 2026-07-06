import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

private func appendString(_ stream: inout [UInt8],_ string: String) {
    stream.append(contentsOf: string.utf8)
}


public struct Rect {
    public let x:Int
    public let y:Int
    public let width:Int
    public let height:Int
}

public enum Color : Equatable {
    case ansi16(UInt8)
    case xterm256(UInt8)
    case truecolor(r:UInt8,g:UInt8,b:UInt8)
    case transparent
    
    func append(to stream: inout [UInt8],foreground:Bool = true) {
        switch self {
        case .ansi16(let code):
            let colorIndex = Int(code & 15)
            let ansiValue:Int
            if foreground {
                ansiValue = colorIndex < 8 ? (30 + colorIndex) : (90 + colorIndex - 8)
            } else {
                ansiValue = colorIndex < 8 ? (40 + colorIndex) : (100 + colorIndex - 8)
            }
            appendString(&stream,"\u{001B}[\(ansiValue)m")
        case .xterm256(let code):
            let type = foreground ? "38" : "48"
            appendString(&stream,"\u{001B}[\(type);5;\(code)m")
        case .truecolor(let r,let g,let b):
            let type = foreground ? "38" : "48"
            appendString(&stream,"\u{001B}[\(type);2;\(r);\(g);\(b)m")
        case .transparent:
            // Fall back to default terminal color masks
            appendString(&stream,foreground ? "\u{001B}[39m" : "\u{001B}[49m")
        }
    }
    
    func append(to stream: inout String,foreground:Bool = true) {
        switch self {
        case .ansi16(let code):
            let base = foreground ? (code < 8 ? 30 : 82) : (code < 8 ? 40 : 92)
            stream.append("\u{001B}[\(Int(base) + Int(code & 7))m")
        case .xterm256(let code):
            let type = foreground ? "38" : "48"
            stream.append("\u{001B}[\(type);5;\(code)m")
        case .truecolor(let r,let g,let b):
            let type = foreground ? "38" : "48"
            stream.append("\u{001B}[\(type);2;\(r);\(g);\(b)m")
        case .transparent:
            // Fall back to default terminal color masks
            stream.append(foreground ? "\u{001B}[39m" : "\u{001B}[49m")
        }
    }
}

struct Cell : Equatable {
    var char: UInt32 = 32
    var fg: Color = .ansi16(15)
    var bg: Color = .ansi16(0)
    var modifiers: UInt8 = 0
}

struct TerminalSize {
    let width: Int
    let height: Int
}

func getTerminalSize() -> TerminalSize {
    var w = winsize()
    if ioctl(STDOUT_FILENO,UInt(TIOCGWINSZ),&w) == 0 && w.ws_col > 0 && w.ws_row > 0 {
        return TerminalSize(width: Int(w.ws_col), height: Int(w.ws_row))
    }
    if ioctl(STDIN_FILENO,UInt(TIOCGWINSZ),&w) == 0 && w.ws_col > 0 && w.ws_row > 0 {
        return TerminalSize(width: Int(w.ws_col), height: Int(w.ws_row))
    }
    if ioctl(STDERR_FILENO,UInt(TIOCGWINSZ),&w) == 0 && w.ws_col > 0 && w.ws_row > 0 {
        return TerminalSize(width: Int(w.ws_col), height: Int(w.ws_row))
    }
    
    if let envCols = ProcessInfo.processInfo.environment["COLUMNS"],let cols = Int(envCols),
       let envRows = ProcessInfo.processInfo.environment["LINES"],let rows = Int(envRows),
       cols > 0,rows > 0 {
        return TerminalSize(width: cols, height: rows)
    }

    return TerminalSize(width: 80, height: 24)
}


public final class Renderer {
    private var width: Int
    private var height: Int
    
    private var frontBuffer: [Cell] = []
    private var backBuffer: [Cell] = []
    
    
    private var resizeSource: DispatchSourceSignal?
    private let bufferLock = NSLock()
    
    private func setupBuffer() {
        let size = width*height
        frontBuffer = [Cell](repeating: Cell(char:0), count: size)
        backBuffer = [Cell](repeating: Cell(), count: size)
    }
    
    private func setupResizeHandler() {
        //Ignore the default signal handler
        signal(SIGWINCH, SIG_IGN)
        
        let source = DispatchSource.makeSignalSource(signal: SIGWINCH, queue: .global(qos:.userInteractive))
        source.setEventHandler { [weak self] in
            self?.handleResizeEvent()
        }
        self.resizeSource = source
        source.resume()
    }
    
    private func handleResizeEvent() {
        bufferLock.lock()
        defer { bufferLock.unlock() }
        let newSize = getTerminalSize()
        guard newSize.width != width || newSize.height != height else { return }
        
        width = newSize.width
        height = newSize.height
        setupBuffer()
        
        print("\u{001B}[2J\u{001B}[H", terminator: "")
        fflush(stdout)
    }
    
    init() {
        let size = getTerminalSize()
        self.width = size.width
        self.height = size.height
        setupBuffer()
        setupResizeHandler()
        TerminalControl.enter()
    }
    deinit {
        TerminalControl.exit()
    }
    func clearBackBuffer() {
        let emptyCell = Cell(
            char: 32,                 // ASCII Space
            fg: .ansi16(15),     // Default white
            bg: .ansi16(0),      // Default black
            modifiers: 0              // No styles active
        )
            
        // Use standard contiguous assignment optimization to overwrite memory arrays safely
        backBuffer.withUnsafeMutableBufferPointer { buffer in
            buffer.update(repeating: emptyCell)
        }
    }
    
    
    func render(_ body: (Renderer)-> Void)  {
        bufferLock.lock()
        defer { bufferLock.unlock() }
        body(self)
        
        var output : [UInt8] = []
        output.reserveCapacity(128*1024)
        
        var lastX = -1
        var lastY = -1
        
        var activeFg : Color? = nil
        var activeBg : Color? = nil
        var activeMod: UInt8? = nil
        
        for y in 0..<height {
            let offset = y*width
            for x in 0..<width {
                let index = offset + x
                let cell = backBuffer[index]
                if cell == frontBuffer[index] {
                    continue
                }
                
                if x != lastX+1 || lastY != y {
                    appendString(&output,"\u{1B}[\(y+1);\(x+1)H")
                    
                }
                
                if cell.modifiers != activeMod {
                    appendString(&output,"\u{001B}[0m");
                    activeFg = nil
                    activeBg = nil
                    activeMod = cell.modifiers
                    
                    if((cell.modifiers & 1) != 0) { appendString(&output,"\u{001B}[1m"); }
                    if((cell.modifiers & 2) != 0) { appendString(&output,"\u{001B}[4m") }
                }
                
                if activeFg != cell.fg {
                    cell.fg.append(to: &output,foreground: true)
                    activeFg = cell.fg

                }
                if activeBg != cell.bg {
                    cell.bg.append(to: &output,foreground: false)
                    activeBg = cell.bg
                }
                if let scalar = UnicodeScalar(cell.char) {
                    if scalar.isASCII {
                        output.append(UInt8(scalar.value))
                    } else {
                        let utf8View = String(scalar).utf8
                        output.append(contentsOf: utf8View)
                    }
                }
                lastX = x
                lastY = y
                frontBuffer[index] = cell
            }
        }
        if !output.isEmpty {
            output.withUnsafeBufferPointer { buffer in
                guard let baseAddress = buffer.baseAddress else { return }
                
                var bytesWritten = 0
                let totalBytes = buffer.count
                
                while bytesWritten < totalBytes {
                    let nextPointer = baseAddress + bytesWritten
                    let remainingBytes = totalBytes - bytesWritten
                    let result = write(STDOUT_FILENO, nextPointer, remainingBytes)
                    if(result > 0) {
                        bytesWritten += result
                    } else if(result < 0) {
                        if errno == EAGAIN || errno == EWOULDBLOCK {
                            usleep(1)
                            continue
                        }
                        break
                    } else {
                        break
                    }
                }
            }
        }
    }
}

extension Renderer {
    public var bounds:Rect { get {
        Rect(x: 0, y: 0, width: width, height: height)
    }}
    
    public func fill(_ scalar: UnicodeScalar, x:Int,y:Int,width:Int,height:Int,fg:Color,bg:Color,modifiers:UInt8 = 0) {
        guard x >= 0 && y >= 0 && x < width && y < height else { return }
        for j in y..<y+height {
            let offset = j*self.width
            for i in x..<x+width {
                let index = offset + i
                backBuffer[index].char = scalar.value
                backBuffer[index].fg = fg
                backBuffer[index].bg = bg
                backBuffer[index].modifiers = modifiers
            }
        }
    }
    
    
    public func drawChar(_ scalar: UnicodeScalar,x:Int,y:Int,fg:Color = .transparent,bg:Color = .transparent,modifiers:UInt8 = 0) {
        guard x >= 0 && y >= 0 && x < width && y < height else {
            return
        }
        let index = y*width + x
        backBuffer[index].char = scalar.value
        if(fg != .transparent) {
            backBuffer[index].fg = fg
        }
        if(bg != .transparent) {
            backBuffer[index].bg = bg
        }
        backBuffer[index].modifiers = modifiers
    }
    
    public func drawString(_ text: String,x:Int,y:Int,fg:Color = .transparent,bg:Color = .transparent,modifiers:UInt8 = 0) {
        guard y >= 0 && y < height else { return }
        let offset = y*width
        let scalars = text.unicodeScalars
        for (i,scalar) in scalars.enumerated() where x+i < width {
            let index = offset + x + i
            backBuffer[index].char = scalar.value
            if(fg != .transparent) {
                backBuffer[index].fg = fg
            }
            if(bg != .transparent) {
                backBuffer[index].bg = bg
            }
            backBuffer[index].modifiers = modifiers
        }
    }
}

import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

public struct Rect {
    public let x:Int
    public let y:Int
    public let width:Int
    public let height:Int
}

public enum SemanticColor {
    case background, textPrimary, textSecondary, accent, error, border
    
    public var terminal: TerminalColor {
        let activeTheme = ApplicationContext.shared.currentTheme
        switch self {
        case .background: return activeTheme.background
        case .textPrimary: return activeTheme.textPrimary
        case .textSecondary: return activeTheme.textSecondary
        case .accent: return activeTheme.accent
        case .error: return activeTheme.error
        case .border: return activeTheme.border
        }
    }
}

public struct Color  {
    private enum Storage {
        case concrete(TerminalColor)
        case semantic(SemanticColor)
    }
    
    private let storage: Storage

    public var terminal : TerminalColor {
        switch storage {
        case .concrete(let color): return color
        case .semantic(let color): return color.terminal
        }
    }
    
    public static func ansi(_ color: TerminalColor) -> Color {
        return Color(storage:.concrete(color))
    }
    public static func theme(_ color: SemanticColor) -> Color {
        return Color(storage:.semantic(color))
    }
    
}

public extension Color {
    static func ansi16(_ color:UInt8) -> Color { Color.ansi(.ansi16(color)) }
    static func xterm256(_ color:UInt8) -> Color { Color.ansi(.xterm256(color)) }
    static var  transparent:Color { Color.ansi(.transparent) }
    static var  background:Color { Color.theme(.background) }
    static var  textPrimary:Color { Color.theme(.textPrimary) }
    static var  textSecondary:Color { Color.theme(.textSecondary) }
    static var  accent:Color { Color.theme(.accent) }
    static var  error:Color { Color.theme(.error) }
    static var  border:Color { Color.theme(.border) }
    
}

public struct Modifier : OptionSet, Equatable, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }

    public static let none = Modifier([])
    public static let bold = Modifier(rawValue:1 << 0)
    public static let dim = Modifier(rawValue:1 << 1)
    public static let italic = Modifier(rawValue:1 << 2)
    public static let underline = Modifier(rawValue:1 << 3)
    public static let blink = Modifier(rawValue:1 << 4)
    public static let reverse = Modifier(rawValue:1 << 5)
    public static let strikethrough = Modifier(rawValue:1 << 6)

}

struct Cell : Equatable {
    var char: UInt32 = 32
    var fg: TerminalColor = .ansi16(15)
    var bg: TerminalColor = .ansi16(0)
    var modifiers: Modifier = .none
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

struct ByteKeyCache : Hashable {
    private let storage: UInt32
    public init(color:TerminalColor,isForeground:Bool) {
        let dir : UInt32 = isForeground ? (1 << 29) : 0
        switch color {
        case .ansi16(let val):
            storage = (0 << 30) | dir | UInt32(val)
        case .xterm256(let val):
            storage = (1 << 30) | dir | UInt32(val)
        case .truecolor(let r,let g,let b):
            storage = (2 << 30) | dir | (UInt32(r) << 16) | (UInt32(g) << 8) | UInt32(b)
        case .transparent:
            storage = (3 << 30) | dir
        }
    }
}

final class ColorCache {
    private let capability: TerminalCapability
    private var byteSequenceCache: [ByteKeyCache:[UInt8]] = [:]
    private var modifierCache: [Modifier:[UInt8]] = [:]
    
    public init(capability:TerminalCapability) {
        self.capability = capability
    }
    
    public func invalidate() {
        byteSequenceCache.removeAll(keepingCapacity: true)
        modifierCache.removeAll(keepingCapacity: true)
    }
    
    
    @inline(__always)
    public func getBytes(for color:TerminalColor,isForeground:Bool) -> [UInt8] {
        let key = ByteKeyCache(color: color, isForeground: isForeground)
        if let result = byteSequenceCache[key] {
            return result
        }
        let str = color.ansiSequence(isForeground: isForeground, capability: capability)
        let result = Array(str.utf8)
        byteSequenceCache[key] = result
        return result
    }
    
    public func getModifierBytes(for mods:Modifier) -> [UInt8] {
        if let cachedBytes = modifierCache[mods] {
            return cachedBytes
        }
        if mods.isEmpty {
            modifierCache[mods] = []
            return []
        }
        var codes = [String]()
        if mods.contains(.bold)          { codes.append("1") }
        if mods.contains(.dim)           { codes.append("2") }
        if mods.contains(.italic)        { codes.append("3") }
        if mods.contains(.underline)     { codes.append("4") }
        if mods.contains(.blink)         { codes.append("5") }
        if mods.contains(.reverse)       { codes.append("7") }
        if mods.contains(.strikethrough) { codes.append("9") }
 
        let str = "\u{001B}[\(codes.joined(separator: ";"))m"
        let bytes = Array(str.utf8)
        modifierCache[mods] = bytes
        return bytes
    }
    
    
}


public final class Renderer {
    private var width: Int
    private var height: Int
    
    private var frontBuffer: [Cell] = []
    private var backBuffer: [Cell] = []
    private var coordinates: [[[UInt8]]] = []
    
    
    private var resizeSource: DispatchSourceSignal?
    private let bufferLock = NSLock()
    
    private let capability: TerminalCapability
    private let colorCache: ColorCache
    private let escResetBytes: [UInt8] = [0x1B, 0x5B, 0x30, 0x6D]

    private func setupBuffer() {
        let size = width*height
        frontBuffer = [Cell](repeating: Cell(char:0), count: size)
        backBuffer = [Cell](repeating: Cell(), count: size)
        
        coordinates = Array(repeating:Array(repeating:[],count:width),count:height)
        for y in 0..<height {
            for x in 0..<width {
                let seq = "\u{1B}[\(y+1);\(x+1)H"
                self.coordinates[y][x] = Array(seq.utf8)

            }
        }
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
        self.capability = TerminalCapability.detect()
        self.colorCache = ColorCache(capability: capability)
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
            modifiers: .none              // No styles active
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
        
        var activeFg : TerminalColor? = nil
        var activeBg : TerminalColor? = nil
        var activeMod: Modifier? = nil
        
        for y in 0..<height {
            let offset = y*width
            for x in 0..<width {
                let index = offset + x
                let cell = backBuffer[index]
                if cell == frontBuffer[index] {
                    continue
                }
                
                if x != lastX+1 || lastY != y {
                    output.append(contentsOf: coordinates[y][x])
                }
                
                if cell.modifiers != activeMod {
                    output.append(contentsOf: escResetBytes)
                    activeFg = nil
                    activeBg = nil
                    activeMod = cell.modifiers
                    let bytes = colorCache.getModifierBytes(for: cell.modifiers)
                    if !bytes.isEmpty {
                        output.append(contentsOf: bytes)
                    }
                    
                    
                }
                
                if activeFg != cell.fg {
                    let fgBytes = colorCache.getBytes(for: cell.fg, isForeground: true)
                    output.append(contentsOf: fgBytes)
                    activeFg = cell.fg

                }
                if activeBg != cell.bg {
                    let bgBytes = colorCache.getBytes(for: cell.bg, isForeground: false)
                    output.append(contentsOf: bgBytes)
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
    
    public func fill(_ scalar: UnicodeScalar, x:Int,y:Int,width:Int,height:Int,fg:TerminalColor,bg:TerminalColor,modifiers:Modifier = .none) {
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
    
    
    public func drawChar(_ scalar: UnicodeScalar,x:Int,y:Int,fg:TerminalColor = .transparent,bg:TerminalColor = .transparent,modifiers:Modifier = .none) {
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
    
    public func drawString(_ text: String,x:Int,y:Int,fg:TerminalColor = .transparent,bg:TerminalColor = .transparent,modifiers:Modifier = .none) {
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

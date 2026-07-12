import Foundation

public struct ColorDownsampler {
    
    private static func quantize(_ n : UInt8) -> Int {
        switch n {
        case 0..<48: return 0
        case 48..<115: return 1
        case 115..<155: return 2
        case 155..<195: return 3
        case 194..<235: return 4
        default: return 5
        }
    }
    
    public static func closesXterm256(r:UInt8,g:UInt8,b:UInt8) -> UInt8 {
        //Greyscale mapping
        if r == g && g == b {
            if r > 3 && r < 243 {
                return UInt8(232 + (((Int(r)-8)*24) / 234))
            }
        }
        return UInt8( 16 + (quantize(r)*36) + (quantize(g)*6) + quantize(b) )
    }
}

public enum TerminalCapability {
    case truecolor,xterm256,ansi16
    public static func detect() -> TerminalCapability {
        let env = ProcessInfo.processInfo.environment
        
        if let colorTerm = env["COLORTERM"], (colorTerm == "truecolor" || colorTerm=="24bit") {
            return .truecolor
        }
        if let term = env["TERM"],term.contains("256color") {
            return .xterm256
        }
        return .ansi16
    }
}

public enum TerminalColor : Equatable {
    case ansi16(UInt8)
    case xterm256(UInt8)
    case truecolor(r:UInt8,g:UInt8,b:UInt8)
    case transparent


}

public extension TerminalColor {
    private func ansi16Fallback() -> Int {
        switch self {
        case .ansi16(let code): return Int(code % 16)
        case .xterm256(let code): return Int(code % 16)
        case .truecolor(let r,let g,let b):
            let bright = (Int(r) + Int(g) + Int(b))/2
            if bright < 50 { return 0}
            if bright > 200 { return 15}
            return (r > g) ? 1 : 2
        case .transparent: return 8
        }
    }
    
    func ansiSequence(isForeground: Bool, capability: TerminalCapability) -> String {
        let mode = isForeground ? "38" : "48"
        switch(self,capability) {
        
        case (.truecolor(let r,let g,let b),.truecolor):
            return "\u{001B}[\(mode);2;\(r);\(g);\(b)m"
            
        case (.truecolor(let r,let g,let b),.xterm256):
            let index = ColorDownsampler.closesXterm256(r: r, g: g, b: b)
            return "\u{001B}[\(mode);5;\(index)m"
            
        case (.xterm256(let code),.truecolor), (.xterm256(let code), .xterm256):
            return "\u{001B}[\(mode);5;\(code)m"
            
        default:
            let basicIndex = ansi16Fallback()
            let basicCode  = isForeground ? (basicIndex < 8 ? 30+basicIndex  : 90+(basicIndex-8))
                                          : (basicIndex < 8 ? 40+basicIndex : 100+(basicIndex-8))
            return "\u{001B}[\(basicCode)m"
        }
    }
    
    
}




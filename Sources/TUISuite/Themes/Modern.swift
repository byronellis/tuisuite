import Foundation
public struct Modern {
    public struct Light : Theme {
        public let background: TerminalColor =  .truecolor(r: 255, g: 255, b: 255)
        
        public let textPrimary: TerminalColor =  .truecolor(r: 20, g: 20, b: 25)
        
        public let textSecondary: TerminalColor = .truecolor(r: 100, g: 110, b: 120)
        
        public let accent: TerminalColor = .truecolor(r: 0, g: 102, b: 204)
        
        public let error: TerminalColor = .truecolor(r: 214, g: 40, b: 40)
        
        public let border: TerminalColor = .truecolor(r: 255, g: 228, b: 232)
    }
    public struct Dark : Theme {
        public let background: TerminalColor =  .truecolor(r: 18, g: 18, b: 18)
        
        public let textPrimary: TerminalColor = .truecolor(r: 245, g: 245, b: 245)
        
        public let textSecondary: TerminalColor = .truecolor(r: 140, g: 146, b: 153)
        
        public let accent: TerminalColor = .truecolor(r: 10, g: 132, b: 255)
        
        public let error: TerminalColor = .truecolor(r: 255, g: 69, b: 58)
        
        public let border: TerminalColor = .truecolor(r: 45, g: 45, b: 48)
    }

    
    
}

extension Theme  {
}

public struct Anders {
    public struct Light : Theme {
        public let background: TerminalColor =  .truecolor(r: 0, g: 0, b: 0xaa)
        public let textPrimary: TerminalColor =  .truecolor(r: 0xaa, g: 0xaa, b: 0xaa)
        public let textSecondary: TerminalColor = .truecolor(r: 255, g: 255, b: 255)
        public let accent: TerminalColor = .truecolor(r: 0, g: 255, b: 255)
        public let error: TerminalColor = .truecolor(r: 214, g: 40, b: 40)
        public let border: TerminalColor = .truecolor(r: 255, g: 255, b: 255)
    }
    
    public struct Dark : Theme {
        public let background: TerminalColor =  .truecolor(r: 0, g: 0, b: 0xaa)
        public let textPrimary: TerminalColor =  .truecolor(r: 0xaa, g: 0xaa, b: 0xaa)
        public let textSecondary: TerminalColor = .truecolor(r: 255, g: 255, b: 255)
        public let accent: TerminalColor = .truecolor(r: 0, g: 255, b: 255)
        public let error: TerminalColor = .truecolor(r: 214, g: 40, b: 40)
        public let border: TerminalColor = .truecolor(r: 255, g: 255, b: 255)
    }
}

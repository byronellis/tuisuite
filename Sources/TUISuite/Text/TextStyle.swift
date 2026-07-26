public struct TextStyle : Sendable {
    public let foreground: Color
    public let background: Color
    public let modifier: Modifier?
    
    public func foreground(_ color: Color) -> TextStyle {
        .init(foreground: color, background: background, modifier: modifier)
    }
    
    public func background(_ color: Color) -> TextStyle {
        .init(foreground: foreground, background: color, modifier: modifier)
    }
    
    public func modifier(_ modifier: Modifier) -> TextStyle {
        .init(foreground: foreground, background: background, modifier: modifier)
    }
    
}

public extension TextStyle {
    static let plain = TextStyle(foreground: .ansi16(0), background: .transparent, modifier: nil)
    
}

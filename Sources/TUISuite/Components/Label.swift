public struct Label : Component {
    let text: String
    let alignment: Alignment
    let position: Position
    public init(_ text: String,alignment: Alignment = .left,position: Position = .top) {
        self.text = text
        self.alignment = alignment
        self.position = position
    }
    
    public func render(renderer:Renderer,bounds:Rect,context:Context) {
        let cleanText = text.count > bounds.width ? String(text.prefix(bounds.width)) : text
        
        let y:Int =
        switch position {
        case .top:
            bounds.y
        case .bottom:
            bounds.y+bounds.height-1
        case .middle:
            bounds.height > 3 ? bounds.y+Int(bounds.height/2) : 0
        }
        
        let x:Int =
        switch alignment {
        case .left:
            bounds.x
        case .right:
            bounds.x+bounds.width-cleanText.count
        case .center:
            bounds.x+max(0,(bounds.width-cleanText.count) / 2)
        }        
        renderer.drawString(cleanText,x:x,y:y,fg: context.fg, bg: context.bg)
    }
}

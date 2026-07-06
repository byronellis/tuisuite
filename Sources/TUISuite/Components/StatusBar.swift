public struct StatusBar : Component {
    let text: String
    public init(_ text: String) {
        self.text = text
    }
    
    public func render(renderer: Renderer, bounds: Rect, context: Context) {
        let clear = text.padding(toLength: bounds.width, withPad: " ", startingAt: 0)
        renderer.drawString(clear,x:bounds.x,y:bounds.y+bounds.height-1,fg:context.fg,bg:context.bg,modifiers:context.modifier)
    }
    
    
}

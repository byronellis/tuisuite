public struct Panel: Component {
    let title: Label?
    let child: Component
    let style: BorderStyle
    
    public init(_ title: Label? = nil,style:BorderStyle = .single,@ComponentBuilder _ child: ()->Component) {
        self.title = title
        self.style = style
        self.child = child()
    }
    
    public func render(renderer: Renderer,bounds:Rect,context:Context) {
        let maxX = bounds.x + bounds.width - 1
        let maxY = bounds.y + bounds.height - 1
        
        for x in bounds.x...maxX {
            renderer.drawString(style.horizontal, x:x,y:bounds.y, fg: context.fg, bg: context.bg,modifiers:context.modifier)
            renderer.drawString(style.horizontal, x:x,y:maxY, fg: context.fg, bg: context.bg,modifiers:context.modifier)
        }
        for y in bounds.y...maxY {
            renderer.drawString(style.vertical, x:bounds.x,y:y, fg: context.fg, bg: context.bg,modifiers:context.modifier)
            renderer.drawString(style.vertical, x:maxX,y:y, fg: context.fg, bg: context.bg,modifiers:context.modifier)
        }
        renderer.drawString(style.topLeft,x:bounds.x,y:bounds.y,fg:context.fg,bg:context.bg,modifiers:context.modifier)
        renderer.drawString(style.topRight,x:maxX,y:bounds.y,fg:context.fg,bg:context.bg,modifiers:context.modifier)
        renderer.drawString(style.bottomLeft,x:bounds.x,y:maxY,fg:context.fg,bg:context.bg,modifiers:context.modifier)
        renderer.drawString(style.bottomRight,x:maxX,y:maxY,fg:context.fg,bg:context.bg,modifiers:context.modifier)

        if let t = title {
            t.render(renderer: renderer, bounds: Rect(x:bounds.x+1,y:bounds.y,width:bounds.width-2,height:bounds.height), context: context)
        }

        child.render(renderer: renderer, bounds: Rect(x:bounds.x+1,y:bounds.y+1,width:bounds.width-2,height:bounds.height-2), context: context)
    }
    
    
}

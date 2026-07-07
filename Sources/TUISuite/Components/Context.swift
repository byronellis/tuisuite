public final class Context {
    public var fg: Color
    public var bg: Color
    public var modifier: Modifier
    public let event: InputEvent?
    
    private var ids: [String] = ["root"]
    private var id: String? = nil
    
    
    public init(fg: Color = .transparent, bg: Color = .transparent, modifier: Modifier = .none,event: InputEvent? = nil) {
        self.fg = fg
        self.bg = bg
        self.modifier = modifier
        self.event = event
    }
    
    public func push(_ id:String) {
        ids.append(id)
    }
    public func pop() {
        if(ids.count > 1) {
            ids.removeLast()
        }
    }
    
    public func override(_ id:String) {
        self.id = id
    }
    
    public var currentId: String {
        if let override = self.id {
            self.id = nil
            return override
        }
        return ids.joined(separator: "/")
    }
    
    public func override(fg:Color? = nil,bg:Color? = nil,modifier:Modifier? = nil) -> (Color,Color,Modifier) {
        let original = (self.fg,self.bg,self.modifier)
        self.fg = fg ?? self.fg
        self.bg = bg ?? self.bg
        self.modifier = modifier ?? self.modifier
        return original
    }
    public func restore(_ original:(Color,Color,Modifier)) {
        self.fg = original.0
        self.bg = original.1
        self.modifier = original.2
    }
}

public struct ContextModifierComponent : Component {
    let fg: Color?
    let bg: Color?
    let modifier: Modifier?
    let id: String?
    
    let content: Component
    
    public init(fg:Color? = nil,bg:Color? = nil,modifier: Modifier? = nil,id: String? = nil,content:Component) {
        self.fg = fg
        self.bg = bg
        self.modifier = modifier
        self.content = content
        self.id = id
    }
    
    public func sizeThatFits(proposal:ProposedSize, context: Context) -> Size {
        content.sizeThatFits(proposal:proposal,context:context)
    }
    
    public func render(renderer: Renderer,bounds:Rect,context:Context) {
        let original = context.override(fg:fg,bg:bg == .transparent ? nil : bg,modifier:modifier)
        if bg != nil {
            for y in bounds.y..<bounds.y+bounds.height {
                for x in bounds.x..<bounds.x+bounds.width {
                    renderer.drawChar(" ", x: x, y: y, fg:context.fg, bg: context.bg,modifiers:context.modifier)
                }
            }
        }
        content.render(renderer: renderer,bounds:bounds,context:context)
        context.restore(original)
    }
}


public extension Component {
    func attribute(fg:Color? = nil,bg:Color? = nil,modifier:Modifier? = nil) -> ContextModifierComponent {
        let base: ContextModifierComponent
        if let contextModifier = self as? ContextModifierComponent {
            base = contextModifier
        } else {
            base = ContextModifierComponent(content:self)
        }
        return ContextModifierComponent(fg: fg ?? base.fg,bg: bg ?? base.bg,modifier: modifier ?? base.modifier,content: base.content)
    }
    
    func foreground(_ color: Color) -> ContextModifierComponent {
        attribute(fg:color)
    }
    func background(_ color: Color = .transparent) -> ContextModifierComponent {
        attribute(bg:color)
    }
    func modifier(_ modifier: Modifier) -> ContextModifierComponent {
        attribute(modifier: modifier)
    }
}

public struct ReverseModifierComponent : Component {
    
    let content: Component
    public init(content:Component) {
        self.content = content
    }

    public func sizeThatFits(proposal: ProposedSize, context: Context) -> Size {
        content.sizeThatFits(proposal: proposal, context: context)
    }
    
    public func render(renderer: Renderer, bounds: Rect, context: Context) {
        let original = context.override(fg:context.bg,bg:context.fg,modifier:context.modifier)
        content.render(renderer: renderer,bounds:bounds,context:context)
        context.restore(original)
    }

}

public extension Component {
    func reverse() -> Component {
        if let reverse = self as? ContextModifierComponent {
            return reverse.content
        } else {
            return ReverseModifierComponent(content:self)
        }
    }
}

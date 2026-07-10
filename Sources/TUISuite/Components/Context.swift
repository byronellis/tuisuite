public final class Context {
    public var fg: TerminalColor
    public var bg: TerminalColor
    public var modifier: Modifier

    public let event: InputEvent?
    private var isConsumed : Bool = false
    
    private var ids: [String] = ["root"]
    private var id: String? = nil
    
    
    public init(fg: TerminalColor = .transparent, bg: TerminalColor = .transparent, modifier: Modifier = .none,event: InputEvent? = nil) {
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
    
    public func onEvent(_ consumer: (InputEvent) -> Bool) {
        guard !isConsumed && event != nil else { return }
        if let e = event {
            isConsumed = consumer(e)
        }
    }
    
    public func override(fg:TerminalColor? = nil,bg:TerminalColor? = nil,modifier:Modifier? = nil) -> (TerminalColor,TerminalColor,Modifier) {
        let original = (self.fg,self.bg,self.modifier)
        self.fg = fg ?? self.fg
        self.bg = bg ?? self.bg
        self.modifier = modifier ?? self.modifier
        return original
    }
    public func restore(_ original:(TerminalColor,TerminalColor,Modifier)) {
        self.fg = original.0
        self.bg = original.1
        self.modifier = original.2
    }
}

public struct ContextModifierComponent<Content:Component> : Component {
    public typealias Body = Never
    
    let fg: Color?
    let bg: Color?
    let modifier: Modifier?
    let id: String?
    
    let content: Content
    
    public init(fg:Color? = nil,bg:Color? = nil,modifier: Modifier? = nil,id: String? = nil,content:Content) {
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
        let resolvedFg:TerminalColor? = fg?.terminal
        let resolvedBg:TerminalColor? = bg?.terminal
        
        
        let original = context.override(fg:resolvedFg == .transparent ? nil : resolvedFg,bg:resolvedBg == .transparent ? nil : resolvedBg,modifier:modifier)
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
    func attribute(fg:Color? = nil,bg:Color? = nil,modifier:Modifier? = nil) -> ContextModifierComponent<Self> {
        let base: ContextModifierComponent<Self>
        if let contextModifier = self as? ContextModifierComponent<Self> {
            base = contextModifier
        } else {
            base = ContextModifierComponent(content:self)
        }
        return ContextModifierComponent(fg: fg ?? base.fg,bg: bg ?? base.bg,modifier: modifier ?? base.modifier,content: base.content)
    }
    
    func foreground(_ color: Color) -> ContextModifierComponent<Self> {
        attribute(fg:color)
    }
    func background(_ color: Color = .transparent) -> ContextModifierComponent<Self> {
        attribute(bg:color)
    }
    func modifier(_ modifier: Modifier) -> ContextModifierComponent<Self> {
        attribute(modifier: modifier)
    }
}

public struct ReverseModifierComponent<Content:Component> : Component {
    public typealias Body = Never

    
    let content: Content
    public init(content:Content) {
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
    func reverse() -> ReverseModifierComponent<Self> {
            return ReverseModifierComponent(content:self)
    }
}


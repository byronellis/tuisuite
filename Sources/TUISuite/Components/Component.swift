public enum Alignment {
    case left,center,right
}

public enum Position {
    case top,middle,bottom
}

public struct BorderStyle : Sendable {
    let topLeft: String
    let topRight: String
    let bottomLeft: String
    let bottomRight: String
    let horizontal: String
    let vertical: String

    public static let ascii = BorderStyle(
        topLeft: "+", topRight: "+",
        bottomLeft: "+", bottomRight: "+",
        horizontal: "-", vertical: "|"
    )
    
    public static let single = BorderStyle(
        topLeft: "┌", topRight: "┐",
        bottomLeft: "└", bottomRight: "┘",
        horizontal: "─", vertical: "│"
    )
    public static let double = BorderStyle(
        topLeft: "╔", topRight: "╗",
        bottomLeft: "╚", bottomRight: "╝",
        horizontal: "═", vertical: "║"
    )

}

public struct Context {
    public let fg: Color
    public let bg: Color
    public let modifier: Modifier
    public let event: InputEvent?
    
    public init(fg: Color = .transparent, bg: Color = .transparent, modifier: Modifier = .none, event: InputEvent? = nil) {
        self.fg = fg
        self.bg = bg
        self.modifier = modifier
        self.event = event
    }
    
    func stop() -> Context {
        Context(fg: fg, bg: bg, modifier: modifier)
    }
}

public protocol Component {
    func render(renderer: Renderer, bounds: Rect, context: Context)
}


public struct ContextModifierComponent : Component {
    let fg: Color?
    let bg: Color?
    let modifier: Modifier?
    let content: Component
    
    public init(fg:Color? = nil,bg:Color? = nil,modifier: Modifier? = nil,content:Component) {
        self.fg = fg
        self.bg = bg
        self.modifier = modifier
        self.content = content
    }
    
    public func render(renderer: Renderer,bounds:Rect,context:Context) {
        content.render(renderer: renderer,bounds:bounds,context:Context(fg:fg ?? context.fg,bg:bg ?? context.bg,modifier:modifier ?? context.modifier,event:context.event))
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
    func background(_ color: Color) -> ContextModifierComponent {
        attribute(bg:color)
    }
    func modifier(_ modifier: Modifier) -> ContextModifierComponent {
        attribute(modifier: modifier)
    }
}

public struct ReverseModifierComponent : Component {
    let content : Component
    public init(content:Component) {
        self.content = content
    }
    public func render(renderer: Renderer,bounds:Rect,context:Context) {
        content.render(renderer: renderer,bounds:bounds,context:Context(fg:context.bg,bg:context.fg,modifier:context.modifier,event:context.event))
    }
}

public extension Component {
    func reverse() -> Component {
        if let reverse = self as? ReverseModifierComponent {
            return reverse.content
        } else {
            return ReverseModifierComponent(content:self)
        }
    }
}

@resultBuilder
public struct ComponentBuilder {
    public static func buildBlock(_ components: Component...) -> [Component] {
        return components
    }
    public static func buildBlock(_ component: Component) -> Component {
        return component
    }
}

public struct Empty : Component {
    
    public init() { }
    public func render(renderer: Renderer, bounds: Rect, context: Context) {
    }
}

public struct Group : Component {
    let children: [Component]
    
    public init(@ComponentBuilder _ children: () -> [Component]) {
        self.children = children()
    }
    public func render(renderer: Renderer, bounds: Rect, context: Context) {
        for child in children {
            child.render(renderer: renderer, bounds: bounds, context: context)
        }
    }
}

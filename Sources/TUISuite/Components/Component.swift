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
    public let fg: Color = .transparent
    public let bg: Color = .transparent
    public let modifier:UInt8 = 0
}

public protocol Component {
    func render(renderer: Renderer, bounds: Rect, context: Context)
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

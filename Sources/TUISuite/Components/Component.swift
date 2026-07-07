
public struct Size : Equatable, Sendable {
    public var minWidth: Int
    public var idealWidth: Int
    public var maxWidth: Int?
    
    public var minHeight: Int
    public var idealHeight: Int
    public var maxHeight: Int?
    
    public static func fixed(width:Int,height:Int) -> Size {
        Size(minWidth:width,idealWidth:width,maxWidth:width,
             minHeight:height,idealHeight:height,maxHeight:height)
    }
}

public struct ProposedSize : Equatable,Sendable {
    public var width: Int?
    public var height: Int?
    
    public static let unspecified = ProposedSize(width:nil,height:nil)
}

public protocol Component {
    func sizeThatFits(proposal:ProposedSize, context: Context) -> Size
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
    
    public func sizeThatFits(proposal:ProposedSize, context: Context) -> Size {
        .fixed(width:0,height:0)
    }

    public func render(renderer: Renderer, bounds: Rect, context: Context) {
    }
}


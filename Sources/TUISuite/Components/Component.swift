
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
    associatedtype Body: Component
    
    var body : Self.Body { get }
    func sizeThatFits(proposal:ProposedSize, context: Context) -> Size
    func render(renderer: Renderer, bounds: Rect, context: Context)
}

public extension Component {
    func sizeThatFits(proposal:ProposedSize, context: Context) -> Size {
        self.body.sizeThatFits(proposal: proposal, context: context)
    }
    func render(renderer: Renderer, bounds: Rect, context: Context) {
        self.body.render(renderer:renderer,bounds:bounds,context:context)
    }
}

extension Never : Component {
    public typealias Body = Never
    
    public var body : Never {
        fatalError("Primitive components have no body.")
    }
    public func sizeThatFits(proposal:ProposedSize, context: Context) -> Size {
        return .fixed(width:0,height:0)
    }
    public func render(renderer: Renderer, bounds: Rect, context: Context) {
    }

}

extension Component where Self.Body == Never {
    public var body : Never {
        fatalError("Primitive components have no body.")
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


@resultBuilder
public struct ComponentBuilder {
    public static func buildBlock() -> Empty {
        Empty()
    }
    public static func buildBlock<C:Component>(_ component: C) -> C {
        return component
    }
    
    public static func buildExpression(_ component :()) -> Empty {
        Empty()
    }
    public static func buildExpression<C:Component>(_ component: C) -> C {
        return component
    }
    
    public static func buildBlock<each C:Component>(_ components: repeat each C) -> TupleComponent<repeat each C> {
        return TupleComponent((repeat each components))
    }
    
    public static func buildOptional<C:Component>(_ component: C?) -> ConditionalComponent<C,Empty> {
        if let c = component {
            return ConditionalComponent(.trueComponent(c))
        }
        return ConditionalComponent(.falseComponent(Empty()))
    }
    public static func buildEither<C1:Component,C2:Component>(first component: C1) -> ConditionalComponent<C1,C2> {
        return ConditionalComponent(.trueComponent(component))
    }
    public static func buildEither<C1:Component,C2:Component>(second component: C2) -> ConditionalComponent<C1,C2> {
        return ConditionalComponent(.falseComponent(component))
    }

}

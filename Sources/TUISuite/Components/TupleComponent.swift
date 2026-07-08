protocol ComponentContainer {
    var children: [AnyComponent] { get }
}

public struct TupleComponent<each Child:Component>: Component {
    public typealias Body = Never
    
    public let child: (repeat each Child)
    public init(_ children: (repeat each Child)) {
        self.child = children
    }
    public func sizeThatFits(proposal:ProposedSize, context: Context) -> Size {
        for c in repeat each child {
            _ = c.sizeThatFits(proposal: proposal, context: context)
        }
        return .fixed(width:0,height:0)
    }
    public func render(renderer: Renderer, bounds: Rect, context: Context) {
        for c in repeat each child {
            c.render(renderer: renderer, bounds: bounds, context: context)
        }
    }
}
 
extension TupleComponent : ComponentContainer {
    var children: [AnyComponent] {
        var children: [AnyComponent] = []
        for c in repeat each child {
            children.append(AnyComponent(c))
        }
        return children
    }
}

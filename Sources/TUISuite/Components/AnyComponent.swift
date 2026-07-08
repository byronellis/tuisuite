public struct AnyComponent : Component {
    public typealias Body = Never
    
    private let _sizeThatFits : (ProposedSize,Context) -> Size
    private let _render: (Renderer,Rect,Context) -> Void
    
    public init<C:Component>(_ component: C) {
        self._sizeThatFits = { component.sizeThatFits(proposal:$0,context:$1) }
        self._render = { component.render(renderer:$0,bounds:$1,context:$2) }
    }
    
    public func sizeThatFits(proposal: ProposedSize, context: Context) -> Size {
        _sizeThatFits(proposal,context)
    }
    
    public func render(renderer: Renderer, bounds: Rect, context: Context) {
        _render(renderer,bounds,context)
    }
    
}

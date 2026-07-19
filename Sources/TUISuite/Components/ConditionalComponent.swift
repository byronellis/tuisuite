public struct ConditionalComponent<TrueComponent: Component, FalseComponent: Component>: Component {
    public typealias Body = Never
    
    public enum ConditionalStorage {
        case trueComponent(TrueComponent)
        case falseComponent(FalseComponent)
    }
    
    private let storage :ConditionalStorage
    
    public init(_ storage:  ConditionalStorage) {
        self.storage = storage
    }
    
    public func sizeThatFits(proposal: ProposedSize, context: Context) -> Size {
        switch storage {
        case .trueComponent(let component):
            context.push("t_")
            defer { context.pop() }
//            StateRegistry.shared.log("ConditionalComponent \(context.currentId) \(proposal) true:\(component)\n")
            return Context.SharedActivePathTracker.withPath(context.currentId) {
                component.sizeThatFits(proposal: proposal, context: context)
            }
        case .falseComponent(let component):
            context.push("f_")
            defer { context.pop() }
//            StateRegistry.shared.log("ConditionalComponent \(context.currentId) \(proposal) false:\(component)\n")
            return Context.SharedActivePathTracker.withPath(context.currentId) {
                component.sizeThatFits(proposal: proposal, context: context)
            }
        }
    }
    
    public func render(renderer: Renderer, bounds: Rect, context: Context) {
        switch storage {
        case .trueComponent(let component):
            context.push("t_")
            defer { context.pop() }
            return Context.SharedActivePathTracker.withPath(context.currentId) {
                component.render(renderer: renderer, bounds: bounds, context: context)
            }
        case .falseComponent(let component):
            context.push("f_")
            defer { context.pop() }
            return Context.SharedActivePathTracker.withPath(context.currentId) {
                component.render(renderer: renderer, bounds: bounds, context: context)
            }
        }
    }
}

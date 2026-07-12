public struct InputModifierComponent<Content:Component> : Component {
    public typealias Body = Never
    
    let content : Content
    let activeKey: String
    let handler : (InputEvent) -> (Bool)
    
    public init(_ content: Content,activeKey:String,_ handler: @escaping (InputEvent) -> (Bool)) {
        self.content = content
        self.activeKey = activeKey
        self.handler = handler
    }
    
    public func sizeThatFits(proposal: ProposedSize, context: Context) -> Size {
        content.sizeThatFits(proposal: proposal, context: context)
    }
    
    public func render(renderer: Renderer, bounds: Rect, context: Context) {
        // We want the event handler to execute at the path where it is defined
        context.onEvent { input in
            Context.SharedActivePathTracker.withPath(activeKey) {
                handler(input)
            }
        }
        content.render(renderer: renderer, bounds: bounds, context: context)
    }
}

public extension Component {
    func input(_ handler: @escaping (InputEvent) -> (Bool)) -> InputModifierComponent<Self> {
        let activeKey = Context.SharedActivePathTracker.currentPath
        return .init(self, activeKey: activeKey, handler)
    }
    
    func onKey(_ handler: @escaping (KeyEvent) -> (Bool)) -> InputModifierComponent<Self> {
        return self.input {
            if case .key(let key) = $0 {
                return handler(key)
            }
            return false
        }
    }
}

public final class Application {
    
    private let rootBuilder: () -> Component
    
    public init(@ComponentBuilder _ builder: @escaping ()->Component) {
        rootBuilder = builder
    }
    
    public func run() {
        RunLoop.run { renderer in
            let rootComponent = rootBuilder()
            rootComponent.render(renderer: renderer, bounds: renderer.bounds, context: .init())
        }
    }
}

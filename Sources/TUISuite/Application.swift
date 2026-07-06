public final class Application {
    
    private let rootBuilder: () -> Component
    
    public init(@ComponentBuilder _ builder: @escaping ()->Component) {
        rootBuilder = builder
    }
    
    public func run() {
        RunLoop.run { renderer,event in
            let rootComponent = rootBuilder()
            rootComponent.render(renderer: renderer, bounds: renderer.bounds, context: .init(event:event))
        }
    }
}

@MainActor
public final class StateRegistry : Sendable {
    public static let shared = StateRegistry()
    private var storage:[String:Any] = [:]
    private init() {}
    public func get<T>(_ type: T.Type, id:String,defaultValue:T) -> T  {
        return storage[id] as? T ?? defaultValue
    }
    public func set<T>(id:String,value: T) {
        storage[id] = value
    }
}


@propertyWrapper
public struct Binding<Value> {
    public let get: () -> Value
    public let set: (Value) -> Void
    
    public init(get: @escaping () -> Value,set: @escaping (Value) -> Void) {
        self.get = get
        self.set = set
    }
    
    public var wrappedValue:Value {
        get { get() }
        set { set(newValue) }
    }
    
    public var projectedValue: Binding<Value> { self }
}

@propertyWrapper
public struct State<Value> {
    private let key: String
    private let defaultValue: Value
    
    public init(wrappedValue: Value, id:String) {
        self.key = id
        self.defaultValue = wrappedValue
    }
    
    @MainActor
    public var wrappedValue : Value {
        get { StateRegistry.shared.get(Value.self,id:key,defaultValue:defaultValue) }
        set { StateRegistry.shared.set(id: key,value: newValue) }
    }
    
    @MainActor
    public var projectedValue: Binding<Value> {
        return Binding(get: { StateRegistry.shared.get(Value.self,id:key,defaultValue:defaultValue) },set: {newValue in StateRegistry.shared.set(id: key,value: newValue) })
    }
}

import Foundation
import os

public final class Application {
    
    private let rootBuilder: () -> Component
    
    public init(@ComponentBuilder _ builder: @escaping ()->Component) {
        rootBuilder = builder
    }
    
    public func run() {
        RunLoop.run { renderer,event in
            let fullScreenBounds = renderer.bounds
            let rootComponent = rootBuilder()
            let context = Context(event:event)
            
            _ = rootComponent.sizeThatFits(proposal: .init(width: fullScreenBounds.width, height:fullScreenBounds.height), context: context)            
            rootComponent.render(renderer: renderer, bounds: renderer.bounds, context: .init(event:event))
        }
    }
}

public final class StateRegistry : @unchecked Sendable {
    public static let shared = StateRegistry()
    private var storage:[String:Any] = [:]
    private var lock = os_unfair_lock()
    
    private init() {}
    public func get<T>(_ type: T.Type, id:String,defaultValue:T) -> T  {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        return storage[id] as? T ?? defaultValue
    }
    public func set<T>(id:String,value: T) {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
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
        nonmutating set { set(newValue) }
    }
    
    public var projectedValue: Binding<Value> { self }
    
    
    public static func constant<T>(value: T) -> Binding<T> {
        .init(get:{ value },set:{ _ in })
    }
}

@propertyWrapper
public struct State<Value>  {
    private let key: String
    private let defaultValue: Value
    
    public init(wrappedValue: Value, id:String) {
        self.key = id
        self.defaultValue = wrappedValue
    }
    
    public var wrappedValue : Value {
        get { StateRegistry.shared.get(Value.self,id:key,defaultValue:defaultValue) }
        set { StateRegistry.shared.set(id: key,value: newValue) }
    }
    
    public var projectedValue: Binding<Value> {
        return Binding(get: { StateRegistry.shared.get(Value.self,id:key,defaultValue:defaultValue) },set: {newValue in StateRegistry.shared.set(id: key,value: newValue) })
    }
}

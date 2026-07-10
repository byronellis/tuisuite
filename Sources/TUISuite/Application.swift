import Foundation
import os

public final class Application<Content:Component> {
    
    private let rootBuilder: () -> Content
    
    public init(@ComponentBuilder _ builder: @escaping ()->Content) {
        rootBuilder = builder
    }
    
    public func run() {
        RunLoop.run { renderer,event in
            let fullScreenBounds = renderer.bounds
            let rootComponent = rootBuilder().attribute(fg:.textPrimary,bg:.background)
            let context = Context(event:event)
            
            _ = rootComponent.sizeThatFits(proposal: .init(width: fullScreenBounds.width, height:fullScreenBounds.height), context: context)            
            rootComponent.render(renderer: renderer, bounds: renderer.bounds, context: context)
            // If we arrive at the end of the event loop without consuming the input check for the default ctrl-c. This can be consumed upstream
            // to disable ctrl-c shutdowns.
            context.onEvent({event in
                switch event {
                case .key(let key):
                    if key.key == .char("c") && key.modifiers.contains(.ctrl) {
                        ApplicationContext.shared.signalShutdown()
                    }
                default:
                    break
                }
                return true
            })
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

extension Context {
    public enum SharedActivePathTracker {
        @TaskLocal public static var currentID:String = ""
        
        @inline(__always)
        public static func withPath<R>(_ id:String,operation: () throws -> R) rethrows -> R {
            return try $currentID.withValue(id, operation: operation)
        }
    }
}

@propertyWrapper
public struct State<Value>  {
    private let defaultValue: Value
    
    public init(wrappedValue: Value) {
        self.defaultValue = wrappedValue
    }
    public var wrappedValue : Value {
        get {
            let currentPath = Context.SharedActivePathTracker.currentID
            return StateRegistry.shared.get(Value.self,id:currentPath,defaultValue:defaultValue)
        }
        set {
            let currentPath = Context.SharedActivePathTracker.currentID
            StateRegistry.shared.set(id: currentPath, value: newValue)
        }
    }

    public var projectedValue: Binding<Value> {
        let fallback = self.defaultValue
        return Binding(
            get: {
                let currentPath = Context.SharedActivePathTracker.currentID
                return StateRegistry.shared.get(Value.self,id:currentPath,defaultValue:fallback)

            }, set: { newValue in 
                let currentPath = Context.SharedActivePathTracker.currentID
                StateRegistry.shared.set(id: currentPath, value: newValue)
            })
    }
    
    
}

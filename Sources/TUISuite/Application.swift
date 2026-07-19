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
                if case .key(let key,let modifiers) = event, key == .char("C") || key == .char("c"), modifiers.contains(.ctrl) {
                    ApplicationContext.shared.signalShutdown()
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
    
    public func log(_ message:String) {
        guard let data = message.data(using: .utf8) else { return }
        if let handle = try? FileHandle(forWritingTo: URL(fileURLWithPath: "./state.log")) {
            do {
                handle.seekToEndOfFile()
                handle.write(data)
                try handle.close()
            } catch {
            }
        } else {
            try? data.write(to: URL(fileURLWithPath: "./state.log"))
        }
    }

    
    private init() { }
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
        @TaskLocal public static var currentPath: String = "root"
        
        @inline(__always)
        public static func withPath<R>(_ path:String,operation: () throws -> R) rethrows -> R {
            return try $currentPath.withValue(path, operation: operation)
        }
    }
}

@propertyWrapper
public struct State<Value>  {
    private let defaultValue: Value
    private let line: Int
    private let column: Int

    
    
    public init(wrappedValue: Value,line:Int=#line,column:Int=#column) {
        self.defaultValue = wrappedValue
        self.line = line
        self.column = column
    }
    
    public var wrappedValue : Value {
        get {
            let activeKey = "\(Context.SharedActivePathTracker.currentPath)#L\(line)C\(column)"
            return StateRegistry.shared.get(Value.self,id:activeKey,defaultValue:defaultValue)
        }
        set {
            let activeKey = "\(Context.SharedActivePathTracker.currentPath)#L\(line)C\(column)"
            StateRegistry.shared.set(id: activeKey, value: newValue)
        }
    }

    public var projectedValue: Binding<Value> {
        let fallback = self.defaultValue
        
        
        return Binding(
            get: {
                let activeKey = "\(Context.SharedActivePathTracker.currentPath)#L\(line)C\(column)"
                return StateRegistry.shared.get(Value.self,id:activeKey,defaultValue:fallback)

            }, set: { newValue in
                let activeKey = "\(Context.SharedActivePathTracker.currentPath)#L\(line)C\(column)"
                StateRegistry.shared.set(id: activeKey, value: newValue)
            })
    }
    
    
}

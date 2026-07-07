import os

public final class FocusManager : @unchecked Sendable {
    public static let shared = FocusManager()
    
    private var focused: String? = nil
    private var lock = os_unfair_lock()
    
    private init() {
    }
    
    public var currentFocus : String? {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        return focused
    }
    
    public func request(id: String) {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        focused = id
    }
    
    public func clear() {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        focused = nil
    }
    
    public func isFocused(id:String) -> Bool {
        return currentFocus == focused
    }
    
}

@propertyWrapper
public struct Focus {
    private let id: String
    public init(id:String) {
        self.id = id
    }
    public var wrappedValue : Bool {
        get {
            FocusManager.shared.isFocused(id:id)
        }
        nonmutating set {
            if newValue {
                FocusManager.shared.request(id:id)
            } else if FocusManager.shared.isFocused(id:id) {
                FocusManager.shared.clear()
            }
        }
    }
}

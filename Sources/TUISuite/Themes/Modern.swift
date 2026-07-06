import Foundation
public struct Modern : Theme {
    
}

extension Theme where Self == Modern {
    static var modern: Modern { .init() }
}

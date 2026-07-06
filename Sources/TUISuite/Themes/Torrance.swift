import Foundation

public struct Torrance : Theme {
}

extension Theme where Self == Torrance {
    public static var torrance: Torrance { .init() }
}

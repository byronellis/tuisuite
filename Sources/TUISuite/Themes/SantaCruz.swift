import Foundation
public struct SantaCruz : Theme {
    
}

extension Theme where Self == SantaCruz {
    public static var santaCruz: SantaCruz {
        .init()
    }
}

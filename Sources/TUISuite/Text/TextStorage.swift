public struct TextSegment {
    public let text: String
    public let style: TextStyle
}

public extension String {
    func styled(_ textStyle: TextStyle) -> TextStorage {
        .rich([TextSegment(text: self, style: textStyle)])
    }
    
    var plain: TextStorage {
        .plain(self)
    }
}

public enum TextStorage {
    case plain(String)
    case rich([TextSegment])
    
    public var string: String {
        switch self {
        case .plain(let string):
            return string
        case .rich(let segments):
            return segments.map(\.text).joined()
        }
    }
    
    public var segments: [TextSegment] {
        switch self {
        case .plain(let string):
            return [TextSegment(text: string, style: .plain)]
        case .rich(let segments):
            return segments
        }
    }
    
    static func + (lhs:TextStorage, rhs: String) -> TextStorage {
        switch lhs {
        case .plain(let lhs):
            return .plain(lhs + rhs)
        case .rich(let lhs):
            return .rich(lhs + [TextSegment(text: rhs, style: .plain)])
        }
    }
    
    static func + (lhs:TextStorage, rhs:TextStorage) -> TextStorage {
        switch (lhs, rhs) {
        case (.plain(let lhs), .plain(let rhs)):
            return .plain(lhs + rhs)
        case (.plain(let lhs), .rich(let rhs)):
            return .rich([TextSegment(text: lhs, style: .plain)] + rhs)
        case (.rich(let lhs), .plain(let rhs)):
            return .rich(lhs + [TextSegment(text: rhs, style: .plain)])
        case (.rich(let lhs), .rich(let rhs)):
            return .rich(lhs + rhs)
        }
    }
    
}

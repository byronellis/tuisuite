public struct ListScrollState {
    public var topVisibleIndex: Int = 0
    public var selectedIndex: Int? = nil
    
    public init(topVisibleIndex: Int = 0, selectedIndex: Int? = nil) {
        self.topVisibleIndex = topVisibleIndex
        self.selectedIndex = selectedIndex
    }
}

public struct List<Data: RandomAccessCollection, Content: Component>: Component where Data.Element: Identifiable {
    public typealias Body = Never
    
    private let data: Data
    private let spacing: Int
    private var scrollState: Binding<ListScrollState>
    private let rowBuilder: (Data.Element) -> Content
    
    public init(
        _ data: Data,
        scrollState: Binding<ListScrollState>,
        spacing: Int = 0,
        rowBuilder: @escaping (Data.Element) -> Content) {
        self.data = data
        self.spacing = spacing
        self.scrollState = scrollState
        self.rowBuilder = rowBuilder
    }
    
    public func sizeThatFits(proposal: ProposedSize, context: Context) -> Size {
        guard !data.isEmpty else {
            return .init(minWidth: 0, idealWidth: 0, maxWidth: proposal.width, minHeight: 0, idealHeight: 0,maxHeight: proposal.height)
        }
        
        context.push("list_row_probe")
        let probeElement = data[data.startIndex]
        let probeRow = rowBuilder(probeElement)
        let probeSize = probeRow.sizeThatFits(proposal:ProposedSize(width:proposal.width,height:nil), context: context)
        context.pop()
        
        let estimatedRowHeight = probeSize.idealHeight
        let totalSpacing = max(0,data.count - 1)*spacing
        let totalCalculatedHeight = (data.count*estimatedRowHeight) + totalSpacing
        
        return Size(minWidth: probeSize.minWidth, idealWidth: probeSize.idealWidth, minHeight: probeSize.minHeight, idealHeight: totalCalculatedHeight, maxHeight: proposal.height)
    }
    
    public func render(renderer: Renderer, bounds: Rect, context: Context) {
        guard bounds.width > 0 && bounds.height > 0 && !data.isEmpty else {
            return
        }
        
        let id = context.currentId
        var activeScroll = scrollState.wrappedValue
        context.onEvent { event in
            switch event {
            case .mouse(let mouse):
                let insideViewport = (mouse.x >= bounds.x && mouse.x <= bounds.x+bounds.width) && (mouse.y >= bounds.y && mouse.y <= bounds.y+bounds.height)
                if insideViewport {
                    switch mouse.button {
                    case .scrollUp:
                        if activeScroll.topVisibleIndex > 0 {
                            activeScroll.topVisibleIndex -= 1
                        }
                        return true
                    case .scrollDown:
                        if activeScroll.topVisibleIndex < data.count - 1 {
                            activeScroll.topVisibleIndex += 1
                        }
                        return true
                    default:
                        return false
                    }
                }
            default: break
            }
            return false
        }
        
        var currentY = bounds.y
        var viewportMaxY = bounds.y + bounds.height
        
        let startIdx = max(0,min(activeScroll.topVisibleIndex,data.count-1))
        let arr = Array(data)
        
        for index in startIdx..<arr.count {
            if currentY > viewportMaxY {
                break
            }
            let element = arr[index]
            
            context.push("row_\(element.id)")
            let row = rowBuilder(element)
            let size = row.sizeThatFits(proposal:ProposedSize(width: bounds.width,height:nil),context:context)
            let height = size.idealHeight
            
            let clippedHeight = min(height,viewportMaxY - currentY)
            let rowBounds = Rect(x: bounds.x, y: currentY, width: bounds.width, height: clippedHeight)
            
            row.render(renderer: renderer, bounds: rowBounds, context: context)
            context.pop()
            currentY += height + spacing            
        }
        
    }
    
    
}

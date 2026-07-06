public enum LayoutDimension {
    case fixed(Int)
    case percentage(Double)
    case flex
}

public struct Columns : Component {
    private let widths: [LayoutDimension]
    private let children: [Component]
    public init(_ widths:[LayoutDimension], @ComponentBuilder _ children: () -> [Component]) {
        self.widths = widths
        self.children = children()
    }
    public func render(renderer: Renderer, bounds: Rect, context: Context) {
        let totalWidth = bounds.width
        var allocatedWidth = 0
        var flexCount = 0
        var computedWidths = [Int](repeating:0,count:children.count)
        for (i,dim) in widths.enumerated() {
            guard i < children.count else { break }
            switch dim {
            case .fixed(let w):
                computedWidths[i] = min(w,totalWidth - allocatedWidth)
                allocatedWidth += computedWidths[i]
            case .percentage(let p):
                let w = Int(Double(totalWidth)*p)
                computedWidths[i] = min(w,totalWidth - allocatedWidth)
                allocatedWidth += computedWidths[i]
            case .flex:
                flexCount += 1
            }
        }
        if flexCount > 0 && allocatedWidth < totalWidth {
            let flexWidth = (totalWidth - allocatedWidth) / flexCount
            for (i,dim) in widths.enumerated() {
                guard i < children.count else { break }
                if case .flex = dim {
                    computedWidths[i] = flexWidth
                }
            }
        }
        var x = bounds.x
        for (i,child) in children.enumerated() {
            let childBounds = Rect(x:x,y:bounds.y,width:computedWidths[i],height:bounds.height)
            child.render(renderer:renderer,bounds:childBounds,context:context)
            x += computedWidths[i]
        }
    }
}

public struct Rows : Component {
    private let heights: [LayoutDimension]
    private let children: [Component]
    public init(_ heights:[LayoutDimension], @ComponentBuilder _ children: () -> [Component]) {
        self.heights = heights
        self.children = children()
    }
    public func render(renderer: Renderer, bounds: Rect, context: Context) {
        let totalHeight = bounds.height
        var allocatedHeight = 0
        var flexCount = 0
        var computedHeights = [Int](repeating:0,count:children.count)
        for (i,dim) in heights.enumerated() {
            guard i < children.count else { break }
            switch dim {
            case .fixed(let w):
                computedHeights[i] = min(w,totalHeight - allocatedHeight)
                allocatedHeight += computedHeights[i]
            case .percentage(let p):
                let w = Int(Double(totalHeight)*p)
                computedHeights[i] = min(w,totalHeight - allocatedHeight)
                allocatedHeight += computedHeights[i]
            case .flex:
                flexCount += 1
            }
        }
        if flexCount > 0 && allocatedHeight < totalHeight {
            let flexWidth = (totalHeight - allocatedHeight) / flexCount
            for (i,dim) in heights.enumerated() {
                guard i < children.count else { break }
                if case .flex = dim {
                    computedHeights[i] = flexWidth
                }
            }
        }
        var y = bounds.y
        for (i,child) in children.enumerated() {
            let childBounds = Rect(x:bounds.x,y:y,width:bounds.width,height:computedHeights[i])
            child.render(renderer:renderer,bounds:childBounds,context:context)
            y += computedHeights[i]
        }
    }
}





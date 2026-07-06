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

public struct LayoutModifierComponent : Component {
    let alignment: Alignment
    let position: Position
    let widthLayout: LayoutDimension
    let heightLayout: LayoutDimension
    let content: Component

    public init(aligment: Alignment = .left,position:Position = .top,widthLayout: LayoutDimension = .flex,heightLayout: LayoutDimension = .flex,content: Component) {
        self.alignment = aligment
        self.position = position
        self.content = content
        self.widthLayout = widthLayout
        self.heightLayout = heightLayout
    }
    
    public func render(renderer: Renderer, bounds: Rect, context: Context) {
        let width = switch widthLayout {
        case .fixed(let int):
            int
        case .percentage(let p):
            max(0,Int(Double(bounds.width)*p))
        case .flex:
            bounds.width
        }
        
        let height = switch heightLayout {
        case .fixed(let int):
            int
        case .percentage(let p):
            max(0,Int(Double(bounds.width)*p))
        case .flex:
            bounds.height
        }
        
        let x = switch alignment {
        case .left:
            bounds.x
        case .right:
            max(0,bounds.x+bounds.width - width)
        case .center:
            max(0,bounds.x+(bounds.width - width)/2)
        }

        let y = switch position {
        case .top:
            bounds.y
        case .bottom:
            max(0,bounds.y+bounds.height - height)
        case .middle:
            max(0,bounds.y+(bounds.height - height)/2)
        }
        content.render(renderer:renderer,bounds:Rect(x:x,y:y,width:width,height:height),context:context)
    }
}

public extension Component {
    func layout(alignment:Alignment?=nil,position:Position?=nil,width:LayoutDimension?=nil,height:LayoutDimension?=nil) -> LayoutModifierComponent {
        let base : LayoutModifierComponent
        if let layoutModifier = self as? LayoutModifierComponent {
            base = layoutModifier
        } else {
            base = LayoutModifierComponent(content: self)
        }
        return LayoutModifierComponent(
            aligment: alignment ?? base.alignment,
            position: position ?? base.position,
            widthLayout: width ?? base.widthLayout,
            heightLayout: height ?? base.heightLayout,
            content: base.content)
    }
    
    func width(_ width: LayoutDimension) -> LayoutModifierComponent {
        layout(width:width)
    }
    func height(_ height: LayoutDimension) -> LayoutModifierComponent {
        layout(height:height)
    }
    func alignment(_ alignment: Alignment) -> LayoutModifierComponent {
        layout(alignment: alignment)
    }
    func position(_ position: Position) -> LayoutModifierComponent {
        layout(position: position)
    }
}





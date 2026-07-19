public enum Alignment {
    case leading,center,trailing
}

public enum VerticalAlignment {
    case top,middle,bottom
}

public enum LayoutDimension {
    case fixed(Int)
    case percentage(Double)
    case flex
}

public struct Spacer : Component {
    public typealias Body = Never
    
    private let minLength: Int
    
    public init(minLength: Int = 0) {
        self.minLength = minLength
    }
    
    public func sizeThatFits(proposal: ProposedSize, context: Context) -> Size {
        // Expand to fill proposed width/height, or fall back to minLength
        Size(minWidth:minLength,idealWidth:minLength,maxWidth:nil,
             minHeight:minLength,idealHeight:minLength,maxHeight:nil)
    }
    
    public func render(renderer: Renderer, bounds: Rect, context: Context) {
        // Spacers are invisible empty cells!
    }
}

public struct VStack<Content:Component> : Component {
    public typealias Body = Never
    
    private let alignment:Alignment
    private let spacing:Int
    private let children: [AnyComponent]
    public init(alignment: Alignment = .center,spacing: Int = 0,@ComponentBuilder _ children: () -> Content) {
        self.alignment = alignment
        self.spacing = spacing

        let content = children()
        if let tuple = content as? ComponentContainer {
            self.children = tuple.children
        } else {
            self.children = [AnyComponent(content)]
        }
        
    }
    
    public func sizeThatFits(proposal: ProposedSize, context: Context) -> Size {
        var minW = 0; var idealW = 0; var maxW: Int? = 0
        var minH = 0; var idealH = 0; var maxH: Int? = 0
         
        let totalSpacing = max(0, children.count - 1) * spacing
         
        for (i, child) in children.enumerated() {
            context.push("v_\(i)")
            let childProf = Context.SharedActivePathTracker.withPath(context.currentId) {
                child.sizeThatFits(proposal: proposal, context: context)
            }
//            StateRegistry.shared.log("VStack \(context.currentId) \(proposal) \(childProf) \(child)\n")
            context.pop()
            
            
            minW = max(minW, childProf.minWidth)
            idealW = max(idealW, childProf.idealWidth)
            if maxW != nil, let cmw = childProf.maxWidth { maxW = max(maxW!, cmw) } else { maxW = nil }
            
            minH += childProf.minHeight
            idealH += childProf.idealHeight
            if maxH != nil, let cmh = childProf.maxHeight { maxH! += cmh } else { maxH = nil }
        }
         
        return Size(
            minWidth: minW, idealWidth: idealW, maxWidth: maxW,
            minHeight: minH + totalSpacing, idealHeight: idealH + totalSpacing, maxHeight: maxH.map { $0 + totalSpacing }
        )
    }
    
    public func render(renderer: Renderer, bounds: Rect, context: Context) {
        let totalSpacing = max(0, children.count - 1) * spacing
        var remainingHeight = bounds.height - totalSpacing
            
        var childProfiles = [Size](repeating: .fixed(width: 0, height: 0), count: children.count)
        var allocatedHeights = [Int](repeating: 0, count: children.count)

        var unallocatedIndices = [Int]()
        var expandingIndices = [Int]()

        for (i, child) in children.enumerated() {
            context.push("v_\(i)")
            let childProfile = Context.SharedActivePathTracker.withPath(context.currentId) {
                let size = child.sizeThatFits(proposal: .init(width: bounds.width, height: remainingHeight),context: context)
                childProfiles[i] = size
                return size
            }
            context.pop()
            
            allocatedHeights[i] = childProfile.minHeight
            remainingHeight -= childProfile.minHeight
            
            if childProfile.maxHeight == nil {
                expandingIndices.append(i)
            } else if childProfile.idealHeight > childProfile.minHeight {
                unallocatedIndices.append(i)
            }
        }
        
        if remainingHeight > 0 && !unallocatedIndices.isEmpty {
            let sorted = unallocatedIndices.sorted {
                (childProfiles[$0].idealHeight - childProfiles[$0].minHeight) < (childProfiles[$1].idealHeight - childProfiles[$1].minHeight)
            }
            var remaining = sorted.count
            for i in sorted {
                let childProfile = childProfiles[i]
                let needed = childProfile.idealHeight - childProfile.minHeight
                let available = remainingHeight / remaining
                let allocation = min(needed,available)
                allocatedHeights[i] += allocation
                remainingHeight -= allocation
                remaining -= 1
                if remainingHeight <= 0 {
                    break
                }
            }
        }
        
        if remainingHeight > 0 && !expandingIndices.isEmpty {
            let amount = remainingHeight / expandingIndices.count
            var remainder = remainingHeight % expandingIndices.count
            for i in expandingIndices {
                let extra = remainder > 0 ? 1 : 0
                remainder -= extra
                allocatedHeights[i] += amount + extra
            }
        }
        
        var yOffset = bounds.y
        for (i,child) in children.enumerated() {
            context.push("v_\(i)")
            let height = allocatedHeights[i]
            let childProfile = childProfiles[i]
            
            guard yOffset < bounds.y + bounds.height else {
                context.pop()
                break
            }
            
            let finalWidth = if childProfile.maxWidth == nil {
                bounds.width
            } else {
                min(childProfile.idealWidth,bounds.width)
            }
            let xOffset = switch alignment {
            case .leading: bounds.x
            case .center: bounds.x + min(0,(bounds.width - finalWidth) / 2)
            case .trailing: bounds.x + min(0,(bounds.width - finalWidth))
            }
            Context.SharedActivePathTracker.withPath(context.currentId) {
                child.render(renderer:renderer,bounds:Rect(x:xOffset,y:yOffset,width:finalWidth,height:height),context:context)
            }
            yOffset += height + spacing
            context.pop()
        }
    }
}

public struct HStack<Content:Component> : Component {
    public typealias Body = Never
    
    private let alignment:VerticalAlignment
    private let spacing:Int
    private let children: [AnyComponent]

    public init(alignment: VerticalAlignment = .middle,spacing: Int = 0,@ComponentBuilder _ children: () -> Content) {
        self.alignment = alignment
        self.spacing = spacing

        let content = children()
        if let tuple = content as? ComponentContainer {
            self.children = tuple.children
        } else {
            self.children = [AnyComponent(content)]
        }
    }
    public func sizeThatFits(proposal: ProposedSize, context: Context) -> Size {
        var minW = 0; var idealW = 0; var maxW: Int? = 0
        var minH = 0; var idealH = 0; var maxH: Int? = 0
        
        let totalSpacing = max(0, children.count - 1) * spacing
        
        for (i, child) in children.enumerated() {
            context.push("h_\(i)")
            
            let childProf = Context.SharedActivePathTracker.withPath(context.currentId) {
                child.sizeThatFits(proposal: proposal, context: context)
            }
//            StateRegistry.shared.log("HStack \(context.currentId) \(proposal) \(childProf) \(child)\n")
            context.pop()
            
            minW += childProf.minWidth
            idealW += childProf.idealWidth
            if maxW != nil, let cmw = childProf.maxWidth { maxW! += cmw } else { maxW = nil }
            
            minH = max(minH, childProf.minHeight)
            idealH = max(idealH, childProf.idealHeight)
            if maxH != nil, let cmh = childProf.maxHeight { maxH = max(maxH!, cmh) } else { maxH = nil }
        }
        
        return Size(
            minWidth: minW + totalSpacing, idealWidth: idealW + totalSpacing, maxWidth: maxW.map { $0 + totalSpacing },
            minHeight: minH, idealHeight: idealH, maxHeight: maxH
        )
   }
    
    public func render(renderer: Renderer, bounds: Rect, context: Context) {
        let totalSpacing = max(0, children.count - 1) * spacing
        var remainingWidth = bounds.width - totalSpacing
        
        var childProfiles = [Size](repeating: .fixed(width: 0, height: 0), count: children.count)
        var allocatedWidths = [Int](repeating: 0, count: children.count)
        
        var unallocatedIndices = [Int]()
        var expandingIndices = [Int]()
        
        for (i, child) in children.enumerated() {
            context.push("h_\(i)")
            let childProfile = Context.SharedActivePathTracker.withPath(context.currentId) {
                child.sizeThatFits(proposal: .init(width:remainingWidth,height:bounds.height), context: context)
            }
            childProfiles[i] = childProfile
            context.pop()
            
            allocatedWidths[i] = childProfile.minWidth
            remainingWidth -= childProfile.minWidth
            
            if childProfile.maxWidth == nil {
                expandingIndices.append(i)
            } else if childProfile.idealWidth > childProfile.minWidth {
                unallocatedIndices.append(i)
            }
        }
        

        
        //Try to allocate remaining space to items that have an ideal width larger than
        //than their minimum width
        if remainingWidth > 0 && !unallocatedIndices.isEmpty {
            let sorted = unallocatedIndices.sorted {
                (childProfiles[$0].idealWidth - childProfiles[$0].minWidth) < (childProfiles[$1].idealWidth - childProfiles[$1].minWidth)
            }
            var remaining = sorted.count
            for i in sorted {
                let childProfile = childProfiles[i]
                let needed = childProfile.idealWidth - childProfile.minWidth
                let available = remainingWidth / remaining
                let allocation = min(needed,available)
                allocatedWidths[i] += allocation
                remainingWidth -= allocation
                remaining -= 1
                if remainingWidth <= 0 {
                    break
                }
            }
        }
        
        
        //Any remaining width can go to flex elements like spacers
        if remainingWidth > 0 && !expandingIndices.isEmpty {
            let amount = remainingWidth / expandingIndices.count
            var remainder = remainingWidth % expandingIndices.count
            for i in expandingIndices {
                let extra = remainder > 0 ? 1 : 0
                remainder -= extra
                allocatedWidths[i] += amount + extra
            }
        }
        
        var xOffset = bounds.x
        for (i,child) in children.enumerated() {
            context.push("h_\(i)")
            let width = allocatedWidths[i]
            let childProfile = childProfiles[i]
            
            guard xOffset < bounds.x + bounds.width else {
                context.pop()
                break
            }
            
            let finalHeight = if childProfile.maxHeight == nil {
                bounds.height
            } else {
                min(childProfile.idealHeight,bounds.height)
            }
            let yOffset = switch alignment {
            case .top: bounds.y
            case .middle: bounds.y + min(0,(bounds.height - finalHeight) / 2)
            case .bottom: bounds.y + min(0,(bounds.height - finalHeight))
            }
            Context.SharedActivePathTracker.withPath(context.currentId) {
                child.render(renderer:renderer,bounds:Rect(x:xOffset,y:yOffset,width:width,height:finalHeight),context:context)
            }
            xOffset += width + spacing
            
            context.pop()
        }
    }
    
}

public struct PaddingLayout<Content:Component>: Component {
    public typealias Body = Never
    
    public var top: Int
    public var leading: Int
    public var bottom: Int
    public var trailing: Int
    public var child: Content
    
    // ==========================================
    // PASS 1: PROFILE MEASUREMENT
    // ==========================================
    public func sizeThatFits(proposal: ProposedSize, context: Context) -> Size {
        let horizontalPadding = leading + trailing
        let verticalPadding = top + bottom
        
        let proposedChildWidth = proposal.width.map { max(0, $0 - horizontalPadding) }
        let proposedChildHeight = proposal.height.map { max(0, $0 - verticalPadding) }
        let childProposal = ProposedSize(width: proposedChildWidth, height: proposedChildHeight)
        
        let childProfile = child.sizeThatFits(proposal: childProposal, context: context)
        
        return Size(
            minWidth: childProfile.minWidth + horizontalPadding,
            idealWidth: childProfile.idealWidth + horizontalPadding,
            maxWidth: childProfile.maxWidth.map { $0 + horizontalPadding },
            minHeight: childProfile.minHeight + verticalPadding,
            idealHeight: childProfile.idealHeight + verticalPadding,
            maxHeight: childProfile.maxHeight.map { $0 + verticalPadding }
        )
    }
    
    // ==========================================
    // PASS 2: PAINT INSET RENDERING
    // ==========================================
    public func render(renderer: Renderer, bounds: Rect, context: Context) {
        let insetBounds = Rect(
            x: bounds.x + leading,
            y: bounds.y + top,
            width: max(0, bounds.width - (leading + trailing)),
            height: max(0, bounds.height - (top + bottom))
        )
        child.render(renderer: renderer, bounds: insetBounds, context: context)
    }
}

extension Component {
    public func padding(_ length: Int = 1) -> PaddingLayout<Self> {
        return PaddingLayout(top: length, leading: length, bottom: length, trailing: length, child: self)
    }
    
    public func padding(top: Int = 0, leading: Int = 0, bottom: Int = 0, trailing: Int = 0) -> PaddingLayout<Self> {
        return PaddingLayout(top: top, leading: leading, bottom: bottom, trailing: trailing, child: self)
    }
}

public struct FrameLayoutModifier<Content:Component>: Component {
    public typealias Body = Never
    
    public let width: LayoutDimension?
    public let height: LayoutDimension?
    public let child: Content
    
    public func sizeThatFits(proposal: ProposedSize, context: Context) -> Size {
        var baseProfile = child.sizeThatFits(proposal: proposal, context: context)
        
        // 1. Resolve Horizontal Overrides
        if let wDim = width {
            switch wDim {
            case .fixed(let val):
                baseProfile.minWidth = val; baseProfile.idealWidth = val; baseProfile.maxWidth = val
            case .percentage(let pct):
                if let proposedMaxX = proposal.width {
                    let val = Int(Double(proposedMaxX) * pct)
                    baseProfile.minWidth = val; baseProfile.idealWidth = val; baseProfile.maxWidth = val
                }
            case .flex:
                baseProfile.maxWidth = nil // Allow infinite expansion
            }
        }
        
        // 2. Resolve Vertical Overrides
        if let hDim = height {
            switch hDim {
            case .fixed(let val):
                baseProfile.minHeight = val; baseProfile.idealHeight = val; baseProfile.maxHeight = val
            case .percentage(let pct):
                if let proposedMaxY = proposal.height {
                    let val = Int(Double(proposedMaxY) * pct)
                    baseProfile.minHeight = val; baseProfile.idealHeight = val; baseProfile.maxHeight = val
                }
            case .flex:
                baseProfile.maxHeight = nil
            }
        }
        
        return baseProfile
    }
    
    public func render(renderer: Renderer, bounds: Rect, context: Context) {
        child.render(renderer: renderer, bounds: bounds, context: context)
    }
}

extension Component {
    public func frame(width: LayoutDimension? = nil, height: LayoutDimension? = nil) -> FrameLayoutModifier<Self> {
        return FrameLayoutModifier(width: width, height: height, child: self)
    }
}

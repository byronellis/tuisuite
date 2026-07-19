public struct DummyTabContent: Component {
    public typealias Body = Never
    public init() {}
    public func sizeThatFits(proposal:ProposedSize, context: Context) -> Size {
        .fixed(width:0,height:0)
    }

    public func render(renderer: Renderer, bounds: Rect, context: Context) {
    }
}
public struct TabBar<Content:Component> : Component {
    public typealias Body = Never
    
    public var selectedTab:Binding<Int>
    private let activeKey: String
    
    let tabs: [(String,Int,Int)]
    let style: BorderStyle


    let content: (Int) -> Content
    
    public init(_ tabs: [String], selected selectedTab: Binding<Int>, style: BorderStyle = .single, @ComponentBuilder content: @escaping (Int) -> Content = { _ in DummyTabContent() }) {
        var t:[(String,Int,Int)] = []
        var offset = 1
        for tab in tabs {
            t.append((tab,tab.count+2,offset))
            offset += tab.count+2
        }
        self.tabs = t
        self.selectedTab = selectedTab
        self.style = style
        self.activeKey = Context.SharedActivePathTracker.currentPath
        
        self.content = content
    }
    
    public func sizeThatFits(proposal: ProposedSize, context: Context) -> Size {
        let tabWidth  = tabs.map(\.1).reduce(0, +)+2
        let tabHeight = 3
        
        let child:(Int,Content) = Context.SharedActivePathTracker.withPath(activeKey) { (selectedTab.wrappedValue,content(selectedTab.wrappedValue)) }

        
        if let dummy = child.1 as? DummyTabContent {
            return Size(minWidth: tabWidth, idealWidth: tabWidth, maxWidth: proposal.width, minHeight: tabHeight, idealHeight: tabHeight, maxHeight: 3)
        }
        if let tuple = child.1 as? ComponentContainer {
            fatalError("Selected tab content must contain a single element")
        }
        

        let proposedChildWidth = proposal.width.map { max(0, $0 - 2) }
        let proposedChildHeight = proposal.height.map { max(0, $0 - 4) }
        let childProposal = ProposedSize(width: proposedChildWidth, height: proposedChildHeight)

        context.push("t_\(child.0)")
        let childProfile = Context.SharedActivePathTracker.withPath(context.currentId) {
            child.1.sizeThatFits(proposal: childProposal, context: context)
        }
//            StateRegistry.shared.log("\(child) \(proposal) \(childProfile)\n")
        
        context.pop()
        return Size(
            minWidth: max(childProfile.minWidth + 2,tabWidth),
            idealWidth: max(childProfile.idealWidth + 2,tabWidth),
            // Preserve the content's flexibility. Converting an unbounded
            // child maximum into the finite proposal makes parent stacks
            // treat the tab bar as fixed at its ideal size.
            maxWidth: childProfile.maxWidth.map { max($0 + 2, tabWidth) },
            minHeight: childProfile.minHeight + 4,
            idealHeight: childProfile.idealHeight + 4,
            maxHeight: childProfile.maxHeight.map { $0 + 4 }
        )

    }
    
    public func render(renderer: Renderer, bounds: Rect, context: Context) {
        let maxX = bounds.x + bounds.width - 1
        let maxY = bounds.y + 2


        
        context.onEvent { event in
            return Context.SharedActivePathTracker.withPath(activeKey) {
                if case let .mouse(button, action, x, y, _) = event, button == .left,action == .press, x >= bounds.x, x < bounds.x + bounds.width, y >= bounds.y, y < bounds.y + bounds.height {

                    for (i,tab) in tabs.enumerated() {
                        if tab.2 <= x && tab.2+tab.1 > x {
                            selectedTab.wrappedValue = i
                        }
                    }
                    return true
                } else if case let .key(key, modifiers) = event, key == .left && modifiers.isEmpty {
                    selectedTab.wrappedValue = max(0,selectedTab.wrappedValue - 1)
                    return true
                } else if case let .key(key, modifiers) = event, key == .right && modifiers.isEmpty {
                    selectedTab.wrappedValue = min(tabs.count-1,selectedTab.wrappedValue + 1)
                    return true
                } /*else if case let .key(key, modifiers) = event, key == .tab  {
                    if modifiers.isEmpty {
                        selectedTab.wrappedValue = (selectedTab.wrappedValue + 1) % tabs.count
                    } else if modifiers.contains([.shift]) {
                        if selectedTab.wrappedValue > 0 {
                            selectedTab.wrappedValue = (selectedTab.wrappedValue - 1)
                        } else {
                            selectedTab.wrappedValue = tabs.count - 1
                        }
                    }
                    return true*
                }*/
                return false
            }
        }
        

        for x in bounds.x...maxX {
            renderer.drawString(style.horizontal, x:x,y:maxY, fg: context.fg, bg: context.bg,modifiers:context.modifier)
        }
        
        var offsetX = bounds.x+1
        for (i,tab) in tabs.enumerated() {
            let tabWidth = tab.1
            renderer.drawString(i == 0 ? style.topLeft : (i < tabs.count) ? style.topMiddle : style.topRight, x: offsetX, y: bounds.y, fg: context.fg, bg: context.bg, modifiers: context.modifier)
            renderer.drawString(style.vertical,x:offsetX,y:bounds.y+1,fg:context.fg,bg:context.bg,modifiers:context.modifier)
            renderer.drawString(style.bottomMiddle,x:offsetX,y:maxY,fg:context.fg,bg:context.bg,modifiers:context.modifier)
            renderer.drawString(tab.0,x:offsetX+1,y:bounds.y+1,fg:context.fg,bg:context.bg,modifiers:context.modifier)
            for x in 0..<(tabWidth-1) {
                renderer.drawString(style.horizontal,x:offsetX+x+1,y:bounds.y,fg:context.fg,bg:context.bg,modifiers: context.modifier)
            }
            offsetX += tabWidth
            // TODO: Compute appropriate truncations if text elements are too large
        }
        renderer.drawString(style.topRight, x: offsetX, y: bounds.y, fg: context.fg, bg: context.bg, modifiers: context.modifier)
        renderer.drawString(style.vertical, x: offsetX, y: bounds.y+1, fg: context.fg, bg: context.bg, modifiers: context.modifier)
        renderer.drawString(style.bottomMiddle, x: offsetX, y: maxY, fg: context.fg, bg: context.bg, modifiers: context.modifier)

        let child: (Int,Content) =
        Context.SharedActivePathTracker.withPath(activeKey) {
            let selected = selectedTab.wrappedValue
            offsetX = tabs[selected].2
            for x in 0..<tabs[selected].1 {
                renderer.drawString(" ", x: offsetX+x, y: maxY, fg: context.fg, bg: context.bg, modifiers: context.modifier)
            }
            renderer.drawString(style.bottomRight, x: offsetX, y: maxY, fg: context.fg, bg: context.bg, modifiers: context.modifier)
            renderer.drawString(style.bottomLeft, x: offsetX+tabs[selected].1, y: maxY, fg: context.fg, bg: context.bg, modifiers: context.modifier)
            return (selected,self.content(selected))
        }
        
        if let dummy = child.1 as? DummyTabContent {
            return
        }
        // The tab header consumes three rows and the outer border consumes one
        // final row. Keep both the content and every border cell in bounds.
        let childBounds = Rect(x: bounds.x + 1, y: bounds.y + 3,
                               width: max(0, bounds.width - 2),
                               height: max(0, bounds.height - 4))

        let bottomY = bounds.y + bounds.height - 1
        let rightX = bounds.x + bounds.width - 1
        for x in childBounds.x..<(childBounds.x + childBounds.width) {
            renderer.drawString(style.horizontal, x: x, y: bottomY, fg: context.fg, bg: context.bg, modifiers: context.modifier)
        }
        for y in childBounds.y..<(childBounds.y + childBounds.height) {
            renderer.drawString(style.vertical, x: bounds.x, y: y, fg: context.fg, bg: context.bg, modifiers: context.modifier)
            renderer.drawString(style.vertical, x: rightX, y: y, fg: context.fg, bg: context.bg, modifiers: context.modifier)
        }
        renderer.drawString(style.topLeft, x: bounds.x, y: bounds.y + 2, fg: context.fg, bg: context.bg, modifiers: context.modifier)
        renderer.drawString(style.topRight, x: rightX, y: bounds.y + 2, fg: context.fg, bg: context.bg, modifiers: context.modifier)
        renderer.drawString(style.bottomLeft, x: bounds.x, y: bottomY, fg: context.fg, bg: context.bg, modifiers: context.modifier)
        renderer.drawString(style.bottomRight, x: rightX, y: bottomY, fg: context.fg, bg: context.bg, modifiers: context.modifier)

        context.push("t_\(child.0)")
        Context.SharedActivePathTracker.withPath(context.currentId) {
            child.1.render(renderer: renderer, bounds: childBounds, context: context)
        }
        context.pop()

    }
    
}

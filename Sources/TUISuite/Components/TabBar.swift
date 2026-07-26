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

    let tabs: [Text]
    let layout: HStackLayout<Text>
    let style: BorderStyle


    let content: (Int) -> Content
    
    public init(_ tabs: [String], selected selectedTab: Binding<Int>, style: BorderStyle = .single, @ComponentBuilder content: @escaping (Int) -> Content = { _ in DummyTabContent() }) {

        var text: [Text] = []
        var hotkeys: [String?] = []
        var tabWidths: [(width:Int,offset:Int)] = []
        
        for tab in tabs {
            let hotkey:String?
            let title:TextStorage
            if let match = tab.wholeMatch(of: /([^~]*)~([^~])~(.*)/) {
                hotkey = String(match.2)
                title = String(match.1).plain + String(match.2).styled(.init(foreground: .accent, background: .transparent, modifier: [.bold])) + String(match.3).plain
            } else {
                hotkey = nil
                title = tab.plain
            }
            text.append(Text(title,lineLimit:1))
            hotkeys.append(hotkey)
            tabWidths.append((0,0))
        }
        self.tabs = text
        self.layout = .init(spacing: 1, leading: 1,trailing: 1,children: self.tabs)
        
        self.selectedTab = selectedTab
        self.style = style
        self.activeKey = Context.SharedActivePathTracker.currentPath
        
        self.content = content
    }
    
    public func sizeThatFits(proposal: ProposedSize, context: Context) -> Size {
        let tabSize = layout.sizeThatFits(proposal: proposal, context: context)
        
        
        let child:(Int,Content) = Context.SharedActivePathTracker.withPath(activeKey) { (selectedTab.wrappedValue,content(selectedTab.wrappedValue)) }

        
        if child.1 is DummyTabContent {
            //If there's no tab context we'll render ourselves as just the tab. Not that the tab size rendering is horizontal so only
            //considers the horizontal space not the vertical space required for the top and bottom of the tab bar.
            return Size(minWidth: tabSize.minWidth, idealWidth: tabSize.idealWidth, maxWidth: nil,
                        minHeight: tabSize.minHeight+2, idealHeight: tabSize.idealHeight+2, maxHeight: tabSize.maxHeight.map({ $0+2 }))
        }
        if child.1 is ComponentContainer {
            fatalError("Selected tab content must contain a single element")
        }
        

        let proposedChildWidth = proposal.width.map { max(0, $0 - 2) }
        let proposedChildHeight = proposal.height.map { max(0, $0 - 4) }
        let childProposal = ProposedSize(width: proposedChildWidth, height: proposedChildHeight)

        context.push("t_\(child.0)")
        let childSize = Context.SharedActivePathTracker.withPath(context.currentId) {
            child.1.sizeThatFits(proposal: childProposal, context: context)
        }
//            StateRegistry.shared.log("\(child) \(proposal) \(childProfile)\n")
        
        context.pop()
        return Size(
            minWidth: max(childSize.minWidth + 2,tabSize.minWidth),
            idealWidth: max(childSize.idealWidth + 2,tabSize.idealWidth),
            // Preserve the content's flexibility. Converting an unbounded
            // child maximum into the finite proposal makes parent stacks
            // treat the tab bar as fixed at its ideal size.
            maxWidth: childSize.maxWidth.map { max($0 + 2, tabSize.idealWidth) },
            minHeight: childSize.minHeight + 4,
            idealHeight: childSize.idealHeight + 4,
            maxHeight: childSize.maxHeight.map { $0 + 4 }
        )

    }
    
    public func render(renderer: Renderer, bounds: Rect, context: Context) {
        let maxX = bounds.x + bounds.width - 1
        let maxY = bounds.y + 2

        for x in bounds.x...maxX {
            renderer.drawString(style.horizontal, x:x,y:maxY, fg: context.fg, bg: context.bg,modifiers:context.modifier)
        }

        var tabBounds: [Rect] = Array(repeating: .zero, count: tabs.count)
        layout.render(renderer: renderer, bounds: Rect(x: bounds.x,y:bounds.y+1,width:bounds.width,height:1), context: context) { i,tab,bounds,context in
            //Draw the tab
            tab.render(renderer: renderer, bounds: bounds, context: context)
            tabBounds[i] = bounds
        }

        let child: (Int,Content) =
        Context.SharedActivePathTracker.withPath(activeKey) {
            let selected = selectedTab.wrappedValue
            return (selected,self.content(selected))
        }
        // Draw the tab borders now that the child borders have all been drawn. Run this in selected tab context
        // so we can alter the drawing to account for the tab
        let selected = child.0
        if !(child.1 is DummyTabContent) {
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
        
        // Render tab over border
        if let end = tabBounds.last {
            renderer.drawString(style.topRight,x:end.x+end.width,y:bounds.y,fg:context.fg,bg:context.bg,modifiers:context.modifier)
            renderer.drawString(style.vertical,x:end.x+end.width,y:end.y,fg:context.fg,bg:context.bg,modifiers:context.modifier)
            renderer.drawString(style.bottomMiddle,x:end.x+end.width,y:end.y+1,fg:context.fg,bg:context.bg,modifiers:context.modifier)
        }

        for (i,b) in tabBounds.enumerated() {
            renderer.drawString(style.vertical, x:b.x-1,y:b.y,fg:context.fg,bg:context.bg,modifiers:context.modifier)
            if(i == 0) {
                renderer.drawString(style.topLeft,x:b.x-1,y:bounds.y,fg:context.fg,bg:context.bg,modifiers:context.modifier)
                renderer.drawString(bounds.height > 3 ? style.leftT : style.bottomMiddle,x:b.x-1,y:b.y+1,fg:context.fg,bg:context.bg,modifiers:context.modifier)
            } else {
                renderer.drawString(style.topMiddle,x:b.x-1,y:bounds.y,fg:context.fg,bg:context.bg,modifiers:context.modifier)
                renderer.drawString(style.bottomMiddle,x:b.x-1,y:b.y+1,fg:context.fg,bg:context.bg,modifiers:context.modifier)
            }
            for x in 0..<b.width {
                renderer.drawString(style.horizontal,x:b.x+x,y:b.y-1,fg:context.fg,bg:context.bg,modifiers:context.modifier)
            }
        }

        // Update the rendering for the selected tab
        let b = tabBounds[selected]
        //Left Side
        if(selected == 0) {
            renderer.drawString(bounds.height > 3 ? style.vertical : style.bottomRight,x:b.x-1,y:b.y+1,fg:context.fg,bg:context.bg,modifiers:context.modifier)
        } else {
            renderer.drawString(style.bottomRight,x:b.x-1,y:b.y+1,fg:context.fg,bg:context.bg,modifiers:context.modifier)
        }
        //Right Side
        renderer.drawString((bounds.height > 3 && b.x+b.width == bounds.width) ? style.vertical : style.bottomLeft,x:b.x+b.width,y:b.y+1,fg:context.fg,bg:context.bg,modifiers:context.modifier)
        for x in 0..<b.width {
            renderer.drawString(" ",x:b.x+x,y:b.y+1,fg:context.fg,bg:context.bg,modifiers:context.modifier)
        }

        
        context.onEvent { event in
            return Context.SharedActivePathTracker.withPath(activeKey) {
                if case let .mouse(button, action, x, y, _) = event, button == .left,action == .press, x >= bounds.x, x < bounds.x + bounds.width, y >= bounds.y, y < bounds.y + 3 {
                    // Check to see if we've got a hit in the tab bar
                    for (i,b) in tabBounds.enumerated() {
                        if x >= b.x && x < b.x+b.width {
                            selectedTab.wrappedValue = i
                            break
                        }
                    }
                    // Always handle mouse events in the tab bar regardless of hit
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


    }
    
}

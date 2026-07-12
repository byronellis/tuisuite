public struct TabBar : Component {
    public typealias Body = Never
    
    public var selectedTab:Binding<Int>
    private let activeKey: String
    
    let tabs: [(String,Int,Int)]
    let style: BorderStyle
    
    public init(_ tabs: [String], selected selectedTab: Binding<Int>, style: BorderStyle = .single) {
        var t:[(String,Int,Int)] = []
        var offset = 0
        for tab in tabs {
            t.append((tab,tab.count+2,offset))
            offset += tab.count+2
        }
        self.tabs = t
        self.selectedTab = selectedTab
        self.style = style
        self.activeKey = Context.SharedActivePathTracker.currentPath
    }
    
    public func sizeThatFits(proposal: ProposedSize, context: Context) -> Size {
        let w = tabs.map(\.1).reduce(0, +)
        return Size(minWidth: proposal.width ?? w, idealWidth: proposal.width ?? w, maxWidth: proposal.width, minHeight: 3, idealHeight: 3, maxHeight: 3)
    }
    
    public func render(renderer: Renderer, bounds: Rect, context: Context) {
        let maxX = bounds.x + bounds.width - 1
        let maxY = bounds.y + bounds.height - 1

        
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
                }
                return false
            }
        }
        

        for x in bounds.x...maxX {
            renderer.drawString(style.horizontal, x:x,y:maxY, fg: context.fg, bg: context.bg,modifiers:context.modifier)
        }
        
        var offsetX = bounds.x
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
        }
        renderer.drawString(style.topRight, x: offsetX, y: bounds.y, fg: context.fg, bg: context.bg, modifiers: context.modifier)
        renderer.drawString(style.vertical, x: offsetX, y: bounds.y+1, fg: context.fg, bg: context.bg, modifiers: context.modifier)
        renderer.drawString(style.bottomMiddle, x: offsetX, y: maxY, fg: context.fg, bg: context.bg, modifiers: context.modifier)

        Context.SharedActivePathTracker.withPath(activeKey) {
            let selected = selectedTab.wrappedValue
            offsetX = tabs[selected].2
            for x in 0..<tabs[selected].1 {
                renderer.drawString(" ", x: offsetX+x, y: maxY, fg: context.fg, bg: context.bg, modifiers: context.modifier)
            }
            renderer.drawString(style.bottomRight, x: offsetX, y: maxY, fg: context.fg, bg: context.bg, modifiers: context.modifier)
            renderer.drawString(style.bottomLeft, x: offsetX+tabs[selected].1, y: maxY, fg: context.fg, bg: context.bg, modifiers: context.modifier)
        }
        

    }
    
}

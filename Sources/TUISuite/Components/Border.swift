public struct BorderStyle : Sendable {
    let topLeft: String
    let topMiddle: String
    let topRight: String
    let bottomLeft: String
    let bottomMiddle: String
    let bottomRight: String
    let horizontal: String
    let vertical: String
    let leftT: String
    let rightT: String
    let center: String

    public static let ascii = BorderStyle(
        topLeft: "+", topMiddle: "+", topRight: "+",
        bottomLeft: "+", bottomMiddle: "+", bottomRight: "+",
        horizontal: "-", vertical: "|", leftT:"+",rightT:"+", 
        center: "+"
    )
    
    public static let single = BorderStyle(
        topLeft: "┌", topMiddle: "┬", topRight: "┐",
        bottomLeft: "└", bottomMiddle: "┴", bottomRight: "┘",
        horizontal: "─", vertical: "│", leftT: "├", rightT: "├", 
        center: "┼"
    )
    public static let double = BorderStyle(
        topLeft: "╔", topMiddle: "╦", topRight: "╗",
        bottomLeft: "╚", bottomMiddle: "╩", bottomRight: "╝",
        horizontal: "═", vertical: "║" ,leftT: "╠", rightT:"╣",
        center: "╬"
    )
    
}


public struct BorderModifierComponent<Content:Component> : Component {
    public typealias Body = Never
    
    let color: Color
    let style: BorderStyle
    let child: Content
    
    public init(color: Color = .transparent,style:BorderStyle = .single,child: Content) {
        self.color = color
        self.style = style
        self.child = child
    }

    public func sizeThatFits(proposal: ProposedSize, context: Context) -> Size {
        let edge = 2
        
        let proposedChildWidth = proposal.width.map { max(0, $0 - edge) }
        let proposedChildHeight = proposal.height.map { max(0, $0 - edge) }
        let childProposal = ProposedSize(width: proposedChildWidth, height: proposedChildHeight)
        
        let childProfile = child.sizeThatFits(proposal: childProposal, context: context)
        
        return Size(
            minWidth: childProfile.minWidth + edge,
            idealWidth: childProfile.idealWidth + edge,
            maxWidth: childProfile.maxWidth.map { $0 + edge },
            minHeight: childProfile.minHeight + edge,
            idealHeight: childProfile.idealHeight + edge,
            maxHeight: childProfile.maxHeight.map { $0 + edge }
        )
    }
    
    public func render(renderer: Renderer,bounds:Rect,context:Context) {
        let maxX = bounds.x + bounds.width - 1
        let maxY = bounds.y + bounds.height - 1
        
        for x in bounds.x...maxX {
            renderer.drawString(style.horizontal, x:x,y:bounds.y, fg: context.fg, bg: context.bg,modifiers:context.modifier)
            renderer.drawString(style.horizontal, x:x,y:maxY, fg: context.fg, bg: context.bg,modifiers:context.modifier)
        }
        for y in bounds.y...maxY {
            renderer.drawString(style.vertical, x:bounds.x,y:y, fg: context.fg, bg: context.bg,modifiers:context.modifier)
            renderer.drawString(style.vertical, x:maxX,y:y, fg: context.fg, bg: context.bg,modifiers:context.modifier)
        }
        renderer.drawString(style.topLeft,x:bounds.x,y:bounds.y,fg:context.fg,bg:context.bg,modifiers:context.modifier)
        renderer.drawString(style.topRight,x:maxX,y:bounds.y,fg:context.fg,bg:context.bg,modifiers:context.modifier)
        renderer.drawString(style.bottomLeft,x:bounds.x,y:maxY,fg:context.fg,bg:context.bg,modifiers:context.modifier)
        renderer.drawString(style.bottomRight,x:maxX,y:maxY,fg:context.fg,bg:context.bg,modifiers:context.modifier)
        child.render(renderer: renderer, bounds: Rect(x:bounds.x+1,y:bounds.y+1,width:bounds.width-2,height:bounds.height-2), context: context)
    }
    
    
}


public extension Component {
    func border(color:Color = .transparent, style: BorderStyle = .single) -> BorderModifierComponent<Self> {
        BorderModifierComponent(color: color,style: style,child:self)
    }
}


public struct Divider : Component {
    public typealias Body = Never
    
    public enum Orientation {
        case horizontal, vertical
    }
    
    let orientation: Orientation
    let style: BorderStyle
    
    public init(_ orientation: Orientation = .horizontal,style: BorderStyle = .single) {
        self.orientation = orientation
        self.style = style
    }
    
    public func sizeThatFits(proposal: ProposedSize, context: Context) -> Size {
        switch orientation {
        case .horizontal:
            return .fixed(width: proposal.width ?? 0, height: 1)
        case .vertical:
            return .fixed(width: 1, height: proposal.height ?? 0)
        }
    }
    
    public func render(renderer: Renderer, bounds: Rect, context: Context) {
        switch orientation {
        case .horizontal:
            let maxX = bounds.x + bounds.width - 1
            for x in bounds.x...maxX {
                renderer.drawString(style.horizontal, x:x,y:bounds.y, fg: context.fg, bg: context.bg,modifiers:context.modifier)
            }
        case .vertical:
            let maxY = bounds.y + bounds.height - 1
            for y in bounds.y...maxY {
                renderer.drawString(style.vertical, x:bounds.x,y:y, fg: context.fg, bg: context.bg,modifiers:context.modifier)
            }
        }
    }
    
}

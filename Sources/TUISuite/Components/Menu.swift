import Foundation

public struct Menu : Component {
    let items: [Component]
    var selector: Binding<Int>
    
    public init(_ selector:Binding<Int>,@ComponentBuilder content: () -> [Component]) {
        self.items = content()
        self.selector = selector
    }
    
    public func render(renderer: Renderer,bounds:Rect,context:Context) {
        switch(context.event) {
        case .controlKey(let key):
            switch key {
            case .up:
                selector.set(max(0,selector.wrappedValue - 1))
            case .down:
                selector.set(selector.wrappedValue + 1)
            default:
                break
            }
        default:
            break
        }
        
        let ctx = context.stop()
        for (i,item) in items.enumerated() {

            if let m = item as? MenuItem {
                (m.id == selector.wrappedValue ? m.reverse() : m).render(renderer: renderer, bounds: Rect(x:bounds.x,y:bounds.y+i,width:bounds.width,height:1), context: ctx)
            } else {
                item.render(renderer: renderer, bounds: Rect(x:bounds.x,y:bounds.y+i,width:bounds.width,height:1), context: ctx)
            }
        }
    }
}

public struct MenuItem : Component {
    let title:String
    public let id:Int
    
    public init(_ title:String,id:Int) {
        self.title = title
        self.id = id
    }
    
    public func render(renderer:Renderer,bounds:Rect,context:Context) {
        let cleanText = title.padding(toLength:bounds.width,withPad:" ",startingAt:0)
        renderer.drawString(cleanText, x: bounds.x, y: bounds.y, fg: context.fg, bg: context.bg, modifiers: context.modifier)
    }
}

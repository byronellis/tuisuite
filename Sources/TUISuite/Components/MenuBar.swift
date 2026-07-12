public struct MenuBar : Component {
    
    public init() { }
    
    @State var isOpen: Bool = false
    @State var menu: String = ""
    @State var log: String = ""
    
    public var body : some Component {
        VStack {
            HStack(spacing:2) {
                HStack {
                    Text("F").foreground(.accent)
                    Text("ile")
                }.reverse(apply:isOpen)
                HStack {
                    Text("E").foreground(.accent)
                    Text("dit")
                }
                Spacer()
            }
            .frame(height: .fixed(1)).background().reverse()
            Text(log)
        }
    }
}

import TUISuite

struct ConfigurationMenu : Component {
    public var body : some Component {
        VStack {
            HStack(spacing:0) {
                Text("[").foreground(.textSecondary)
                Text("P").foreground(.accent)
                Text("]").foreground(.textSecondary)
                Text("roviders")
            }
            HStack(spacing:0) {
                Text("[").foreground(.textSecondary)
                Text("A").foreground(.accent)
                Text("]").foreground(.textSecondary)
                Text("gents")
            }
            HStack(spacing:0) {
                Text("[").foreground(.textSecondary)
                Text("R").foreground(.accent)
                Text("]").foreground(.textSecondary)
                Text("outing")
            }
            Spacer()
            HStack(spacing:0) {
                Text("[").foreground(.textSecondary)
                Text("S").foreground(.accent)
                Text("]").foreground(.textSecondary)
                Text("ave and Exit")
            }
            HStack(spacing:0) {
                Text("[").foreground(.textSecondary)
                Text("C").foreground(.accent)
                Text("]").foreground(.textSecondary)
                Text("ancel and Exit")
            }
        }.border(color:.border).frame(width:.fixed(22))
    }
}


@main
struct TextEditor {

    func run() {
        let app = Application {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack {
                        HStack {
                            Spacer()
                            Text("Configuration")
                            Spacer()
                        }
                        .background()
                        .frame(height:.fixed(1)).reverse()
                        HStack {
                            ConfigurationMenu()
                            VStack {
                                Text("Content")
                                Spacer()
                            }.border(color:.border)
                        }

                        HStack(spacing:1) {
                            Text("First")
                            Text("Second")
                            Spacer()
                            Text("Third")
                        }
                        .background()
                        .frame(height:.fixed(1)).reverse()
                    }
                    .frame(width:.fixed(80),height:.fixed(24))
                    Spacer()
                }
                Spacer()
            }.foreground(.textPrimary).background(.background)
        }
        app.run()
    }

    
    static func main() {
        TextEditor().run()
    }
}

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

struct AgentEntry : Identifiable {
    enum EntryType {
        case user, system, agent, tool
    }
    
    let id : String
    let type : EntryType
    let text : String
}

public struct AgentInterface : Component {
    @State var log : [AgentEntry] = [
        AgentEntry(id: "1", type: .user, text: "Hello how are you?"),
        AgentEntry(id: "2", type: .agent, text: "I'm fine, how can I help you today?")
    ]
    @State var listScroll = ListScrollState()
    
    public var body : some Component {
        VStack {
            List(log,scrollState: $listScroll,spacing: 1) { element in
                VStack {
                    Text("\(element.type)").foreground(.accent).modifier(.bold)
                    Text(element.text)
                }
            }
            Spacer()
            HStack {
                Text("Agent Text Input").foreground(.textSecondary)
                Spacer().frame(height:.fixed(1))
            }.border(color:.border)
            HStack {
                Text("Status Line")
                Spacer()
                Text("0 sessions")
            }.frame(height:.fixed(1))
        }
    }
}

@main
struct TextEditor {

    func run() {
        let app = Application {
            AgentInterface()
        }
        app.run()
    }

    
    static func main() {
        TextEditor().run()
    }
}

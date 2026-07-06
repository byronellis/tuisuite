import TUISuite

@main
struct TextEditor {
    let theme : Theme = .santaCruz

    @State(id:"configMenu")
    var configMenu:Int = 1
    
    @MainActor
    func run() {
        let app = Application {
            Rows([.fixed(1),.flex,.fixed(1)]) {
                Label("Configuration",alignment:.center)
                Columns([.fixed(22),.flex]) {
                    Panel() {
                        Rows([.fixed(3),.flex,.fixed(2)]) {
                            Menu($configMenu) {
                                MenuItem("Providers...",id:0)
                                MenuItem("Agents...",id:1)
                                MenuItem("Routing...",id:2)
                            }
                            Empty()
                            Menu($configMenu) {
                                MenuItem("Save and Exit",id:3)
                                MenuItem("Cancel and Exit",id:4)
                            }
                        }
                    }
                    Panel() { Empty() }.modifier([.dim])
                }
                StatusBar("Hints").reverse()
            }
            .attribute(fg:.ansi16(15),bg:.ansi16(0))
            .layout(alignment:.center,position:.middle,width:.fixed(80),height:.fixed(24))
        }
        app.run()
    }

    
    static func main() {
        TextEditor().run()
    }
}

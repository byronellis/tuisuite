import TUISuite

@main
struct TextEditor {
    let theme : Theme = .santaCruz

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
                            VStack {
                                HStack(spacing:0) {
                                    Text("[P]").foreground(.ansi16(2))
                                    Text("roviders")
                                }
                                HStack(spacing:0) {
                                    Text("[A]").foreground(.ansi16(2))
                                    Text("gents")
                                }
                                HStack(spacing:0) {
                                    Text("[R]").foreground(.ansi16(2))
                                    Text("outing")
                                }
                                Spacer()
                                HStack(spacing:0) {
                                    Text("[S]").foreground(.ansi16(2))
                                    Text("ave and Exit")
                                }
                                HStack(spacing:0) {
                                    Text("[C]").foreground(.ansi16(2))
                                    Text("ancel and Exit")
                                }
                            }.border(color:.ansi16(15)).frame(width:.fixed(22))
                            VStack {
                                Text("Content")
                                Spacer()
                            }.border(color:.ansi16(15))
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
                 //   .border(color:.ansi16(15))
                    Spacer()
                }
                Spacer()
            }.foreground(.ansi16(15)).background(.ansi16(0))
        }
        app.run()
    }

    
    static func main() {
        TextEditor().run()
    }
}

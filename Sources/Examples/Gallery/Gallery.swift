import Foundation
import TUISuite

public struct KeyboardEntry : Component {
    
    @State var tab: Int = 0
    @State var key: String = "Key: None"
    
    public var body : some Component {
        VStack {
            TabBar(["~F~irst","~S~econd","~T~hird","Fou~r~th"],selected:$tab) { selected in
                switch(selected) {
                case 0:
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            VStack {
                                Text("\(selected)")
                            }
                            .frame(width:.fixed(20), height:.fixed(10))
                            .border(color:.accent)
                            Spacer()
                        }
                        Spacer()
                    }
                case 1:
                    VStack {
                        Spacer()
                    }
                case 2:
                    HStack {
                        Spacer()
                    }
                default:
                    Spacer()
                }
            }
        }
    }
}


@main
struct Gallery {

    func run() {
        let app = Application {
            VStack {
                KeyboardEntry()
            }
        }
        app.run()
    }

    
    static func main() {
        Gallery().run()
    }
}


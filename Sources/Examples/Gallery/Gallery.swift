import Foundation
import TUISuite

public struct KeyboardEntry : Component {
    
    @State var tab: Int = 0
    @State var key: String = "Key: None"
    
    public var body : some Component {
        VStack {
            TabBar(["~F~irst","~S~econd","~T~hird","~F~ourth"],selected:$tab)
            Spacer()
            HStack {
                Spacer()
                VStack {
                    Text("\(tab)")
                }
                .frame(width:.fixed(20), height:.fixed(10))
                .border(color:.accent)
                Spacer()
            }
            Spacer()
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


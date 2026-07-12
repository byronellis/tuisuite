import Foundation
import TUISuite

public struct KeyboardEntry : Component {
    
    @State var key: String = "Key: None"
    
    public var body : some Component {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack {
                    Text("\(key)").onKey({ event in
                        $key.wrappedValue = "\(event)"
                        return false
                    })
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


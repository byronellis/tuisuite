import TUISuite

@main
struct TextEditor {
    let theme : Theme = .santaCruz
    static func main() {
        let app = Application {
            Columns([.flex,.fixed(80),.flex]) {
                Empty()
                Rows([.flex,.fixed(24),.flex]) {
                    Empty()
                    Panel(Label("Configuration",alignment:.center,position:.top)) {
                        Empty()
                    }
                    Empty()
                }
                Empty()
            }
        }
        app.run()
        
        /*
        RunLoop.run() { renderer in
            let bounds = renderer.bounds
            renderer.fill(" ",x:0,y:0,width:bounds.width,height:bounds.height,fg:.ansi16(15),bg:.ansi16(0))
            renderer.drawString("\(bounds.width)x\(bounds.height)", x:0, y:0, fg:.transparent, bg:.transparent)

              // Smooth 24-bit Truecolor gradients
            
            
            for i in 0..<bounds.width {
                let iVal = Int(255.0*Double(i)/Double(bounds.width))
                
                renderer.drawString(i % 100 == 0 ? "\(i / 100)" : " ",x:i,y:1)
                let tens = i >= 100 ? i - 100*(i / 100) : 0
                renderer.drawString(i % 10 == 0 ? "\(tens / 10)" : " ",x:i,y:2)
                renderer.drawString("\(i % 10)",x:i,y:3)
                for y in 4..<bounds.height {
                    let jVal = Int(255.0*Double(y-4)/Double(bounds.height-4))
                    renderer.drawChar("█", x: i, y: y,fg: .truecolor(r: 0, g: UInt8(iVal), b: UInt8(jVal)))
                }
              }
        }
         */
    }
}

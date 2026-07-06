import Foundation

func setupCrashTraps() {
    let signals = [SIGINT,SIGTERM,SIGSEGV,SIGABRT]
    for sig in signals {
        signal(sig) { num in
            TerminalControl.exit()
            exit(num)
        }
    }
}

public struct RunLoop {
    
    
    public static func run(fps : Double = 60.0, _ body: (Renderer,InputEvent?) -> Void) {
        setupCrashTraps()
        
        let renderer = Renderer()

        //Make sure we enter raw mode after getting the initial size.
        let input = Input()
        input.enterRawMode()
        defer { input.exitRawMode() }

        
        var isRunning = true
        let targetFrameTime: TimeInterval = 1.0 / TimeInterval(fps)
        
        renderer.clearBackBuffer()
        while isRunning {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            var frameEvent: InputEvent?
            if(input.waitForInput(timeout: targetFrameTime)) {
                while let event = input.poll() {
                    switch event {
                    case .controlKey(.escape):
                        isRunning = false
                    default:
                        frameEvent = event
                    }
                }
            }
            renderer.render {
                body($0,frameEvent)
            }
            let elaspsedTime = CFAbsoluteTimeGetCurrent() - startTime
            if elaspsedTime < targetFrameTime {
                let remaining_sleep = targetFrameTime - elaspsedTime
                usleep(UInt32(remaining_sleep * 1_000_000))
            }
        }
    }
}

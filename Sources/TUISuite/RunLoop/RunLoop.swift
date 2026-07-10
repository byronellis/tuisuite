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

public final class ApplicationContext: @unchecked Sendable {
    public static let shared = ApplicationContext()
    
    private var shutdownRequested: Bool = false
    private var lock = os_unfair_lock()
    
    private var cachedDarkMode:Bool = false
    private var lastChecked:CFTimeInterval = CFTimeInterval.nan
    private var dark_lock = os_unfair_lock()
    
    private var darkModeTheme: Theme = Modern.Dark()
    private var lightModeTheme: Theme = Modern.Light()
    
    private init() { }
    
    public var isShutdownRequested : Bool {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        return shutdownRequested
    }
    
    public func signalShutdown() {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        shutdownRequested = true
    }
    
    public var darkMode : Bool {
        let now = CFAbsoluteTimeGetCurrent()
        if lastChecked == .nan || now - lastChecked > 60.0 {
            os_unfair_lock_lock(&dark_lock)
            defer { os_unfair_lock_unlock(&dark_lock) }
            // Make sure we didn't get updated while waiting for the lock
            if lastChecked == .nan || now - lastChecked > 60.0 {
                cachedDarkMode = false
                let globalDefaults = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain)!
                if let intefaceStyle = globalDefaults["AppleInterfaceStyle"] as? String {
                    cachedDarkMode = intefaceStyle.caseInsensitiveCompare( "dark" ) == .orderedSame
                }
                lastChecked = now
            }
        }
        return cachedDarkMode
    }
    
    public var currentTheme: Theme {
        darkMode ? darkModeTheme : lightModeTheme
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
            if ApplicationContext.shared.isShutdownRequested {
                isRunning = false
                break
            }
            
            var frameEvent: InputEvent?
            if(input.waitForInput(timeout: targetFrameTime)) {
                if let event = input.poll() {
                    frameEvent = event
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

import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as an accessory app (menu bar + floating HUD)
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize Drift Window and State
        WindowManager.shared.setupApp()
        
        print("✨ Drift Lyrics Engine is running!")
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

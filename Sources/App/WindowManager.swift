import AppKit
import SwiftUI

public final class WindowManager: NSObject, ObservableObject, NSMenuDelegate {
    public static let shared = WindowManager()
    
    private var floatingWindow: NSWindow?
    private var notchIslandWindow: NSWindow?
    private var immersiveWindow: NSWindow?
    private var statusItem: NSStatusItem?
    private var statusMenu: NSMenu?
    
    private override init() {
        super.init()
    }
    
    public func setupApp() {
        setupStatusItem()
        createFloatingWindow()
        createNotchIslandWindow()
        createImmersiveWindow()
        
        switchMode(to: AppState.shared.displayMode)
    }
    
    // MARK: - Menu Bar Status Item
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }
        
        button.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Drift Lyrics")
        
        let menu = NSMenu()
        menu.delegate = self
        statusMenu = menu
        statusItem?.menu = menu
    }
    
    // MARK: - NSMenuDelegate (Dynamically populate menu before it opens)
    
    public func menuWillOpen(_ menu: NSMenu) {
        menu.removeAllItems()
        let track = MusicDetector.shared.currentTrack
        
        // Track Title item
        let titleItem = NSMenuItem(title: "\(track.title) — \(track.artist)", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        
        // Active Verse item
        if let verse = AppState.shared.currentVerseName {
            let verseItem = NSMenuItem(title: "Active Verse: [\(verse)]", action: nil, keyEquivalent: "")
            verseItem.isEnabled = false
            menu.addItem(verseItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Play / Pause
        let playTitle = track.isPlaying ? "Pause" : "Play"
        let playItem = NSMenuItem(title: playTitle, action: #selector(togglePlayback), keyEquivalent: " ")
        playItem.target = self
        menu.addItem(playItem)
        
        // Next Track
        let nextItem = NSMenuItem(title: "Next Track", action: #selector(nextTrack), keyEquivalent: "n")
        nextItem.target = self
        menu.addItem(nextItem)
        
        // Previous Track
        let prevItem = NSMenuItem(title: "Previous Track", action: #selector(prevTrack), keyEquivalent: "p")
        prevItem.target = self
        menu.addItem(prevItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Display Modes Submenu
        let modesMenu = NSMenu()
        for mode in DriftDisplayMode.allCases {
            let item = NSMenuItem(title: mode.rawValue, action: #selector(modeSelected(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = mode
            if mode == AppState.shared.displayMode {
                item.state = .on
            }
            modesMenu.addItem(item)
        }
        let modeParent = NSMenuItem(title: "Display Mode", action: nil, keyEquivalent: "")
        modeParent.submenu = modesMenu
        menu.addItem(modeParent)
        
        // Click-through Toggle
        let clickThroughItem = NSMenuItem(title: "Click-Through Mode", action: #selector(toggleClickThrough), keyEquivalent: "l")
        clickThroughItem.target = self
        clickThroughItem.state = AppState.shared.isClickThrough ? .on : .off
        menu.addItem(clickThroughItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Preferences
        let prefItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        prefItem.target = self
        menu.addItem(prefItem)
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit Drift", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    // MARK: - Actions
    
    @objc private func togglePlayback() {
        MusicDetector.shared.togglePlayPause()
    }
    
    @objc private func nextTrack() {
        MusicDetector.shared.nextTrack()
    }
    
    @objc private func prevTrack() {
        MusicDetector.shared.previousTrack()
    }
    
    @objc private func toggleClickThrough() {
        AppState.shared.isClickThrough.toggle()
        updateClickThrough(AppState.shared.isClickThrough)
    }
    
    @objc private func modeSelected(_ sender: NSMenuItem) {
        if let mode = sender.representedObject as? DriftDisplayMode {
            AppState.shared.displayMode = mode
            switchMode(to: mode)
        }
    }
    
    @objc private func openPreferences() {
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        let prefWindow = NSWindow(contentViewController: hostingController)
        prefWindow.title = "Drift Settings"
        prefWindow.styleMask = [.titled, .closable]
        prefWindow.center()
        prefWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Window Creation
    
    private func createFloatingWindow() {
        let contentView = FloatingLyricsView()
        let hosting = NSHostingController(rootView: contentView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 480, height: 540),
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = hosting
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.isMovableByWindowBackground = true
        window.level = AppState.shared.isAlwaysOnTop ? .floating : .normal
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.maxX - 520
            let y = screenRect.midY - 270
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        self.floatingWindow = window
    }
    
    private func createNotchIslandWindow() {
        let contentView = NotchIslandView()
        let hosting = NSHostingController(rootView: contentView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 160),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = hosting
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.isMovableByWindowBackground = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        if let screen = NSScreen.main {
            let screenRect = screen.frame
            let x = screenRect.midX - 240
            let y = screenRect.maxY - 46
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        self.notchIslandWindow = window
    }
    
    private func createImmersiveWindow() {
        let contentView = ImmersiveStudioView()
        let hosting = NSHostingController(rootView: contentView)
        
        guard let screen = NSScreen.main else { return }
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = hosting
        window.backgroundColor = .clear
        window.isOpaque = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenPrimary]
        
        self.immersiveWindow = window
    }
    
    // MARK: - Switching Modes
    
    public func switchMode(to mode: DriftDisplayMode) {
        floatingWindow?.orderOut(nil)
        notchIslandWindow?.orderOut(nil)
        immersiveWindow?.orderOut(nil)
        
        switch mode {
        case .floatingWidget:
            floatingWindow?.makeKeyAndOrderFront(nil)
            floatingWindow?.ignoresMouseEvents = AppState.shared.isClickThrough
        case .notchIsland:
            notchIslandWindow?.makeKeyAndOrderFront(nil)
            notchIslandWindow?.ignoresMouseEvents = false
        case .immersiveStudio:
            if let screen = NSScreen.main {
                immersiveWindow?.setFrame(screen.frame, display: true)
            }
            immersiveWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    public func updateClickThrough(_ enabled: Bool) {
        floatingWindow?.ignoresMouseEvents = enabled
    }
    
    public func updateAlwaysOnTop(_ enabled: Bool) {
        floatingWindow?.level = enabled ? .floating : .normal
    }
}

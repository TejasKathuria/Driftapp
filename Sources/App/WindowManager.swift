import AppKit
import SwiftUI

public final class WindowManager: NSObject, ObservableObject, NSMenuDelegate {
    public static let shared = WindowManager()
    
    private var floatingWindow: NSWindow?
    private var notchIslandWindow: NSWindow?
    private var immersiveWindow: NSWindow?
    private var externalImmersiveWindows: [NSWindow] = []
    private var preferencesWindow: NSWindow?
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
        
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            AppState.shared.connectedScreensCount = NSScreen.screens.count
            if AppState.shared.displayMode == .immersiveStudio {
                if let screen = NSScreen.main ?? NSScreen.screens.first {
                    self?.immersiveWindow?.setFrame(screen.frame, display: true)
                }
                self?.updateExternalDisplayMirroring()
            }
        }
        
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
        
        // Fullscreen Kinetic Animation Style Submenu
        let stylesMenu = NSMenu()
        for style in KineticAnimationStyle.allCases {
            let item = NSMenuItem(title: style.rawValue, action: #selector(kineticStyleSelected(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = style
            if style == AppState.shared.kineticStyle {
                item.state = .on
            }
            stylesMenu.addItem(item)
        }
        let styleParent = NSMenuItem(title: "Kinetic Lyric Style", action: nil, keyEquivalent: "")
        styleParent.submenu = stylesMenu
        menu.addItem(styleParent)
        
        // Click-through Toggle
        let clickThroughItem = NSMenuItem(title: "Click-Through Mode", action: #selector(toggleClickThrough), keyEquivalent: "l")
        clickThroughItem.target = self
        clickThroughItem.state = AppState.shared.isClickThrough ? .on : .off
        menu.addItem(clickThroughItem)
        
        // Mirror on External Display Toggle
        let mirrorItem = NSMenuItem(title: "Mirror Fullscreen on External Display", action: #selector(toggleMirrorOnExternalDisplay), keyEquivalent: "m")
        mirrorItem.target = self
        mirrorItem.state = AppState.shared.mirrorOnExternalDisplay ? .on : .off
        menu.addItem(mirrorItem)
        
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
    
    @objc private func toggleMirrorOnExternalDisplay() {
        AppState.shared.mirrorOnExternalDisplay.toggle()
        updateExternalDisplayMirroring()
    }
    
    @objc private func modeSelected(_ sender: NSMenuItem) {
        if let mode = sender.representedObject as? DriftDisplayMode {
            AppState.shared.displayMode = mode
            switchMode(to: mode)
        }
    }
    
    @objc private func kineticStyleSelected(_ sender: NSMenuItem) {
        if let style = sender.representedObject as? KineticAnimationStyle {
            AppState.shared.kineticStyle = style
        }
    }
    
    @objc private func openPreferences() {
        if let existing = preferencesWindow, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        let prefWindow = NSWindow(contentViewController: hostingController)
        prefWindow.title = "Drift Preferences"
        prefWindow.styleMask = [.titled, .closable, .miniaturizable]
        prefWindow.isReleasedWhenClosed = false
        prefWindow.center()
        prefWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        self.preferencesWindow = prefWindow
    }
    
    @objc private func quitApp() {
        NSApp.presentationOptions = []
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
        
        let screen = NSScreen.main ?? NSScreen.screens.first
        let frame = screen?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let window = FullscreenImmersiveWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = hosting
        window.backgroundColor = .black
        window.isOpaque = true
        window.hasShadow = false
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        window.hidesOnDeactivate = false
        
        self.immersiveWindow = window
    }
    
    // MARK: - Switching Modes
    
    public func switchMode(to mode: DriftDisplayMode) {
        floatingWindow?.orderOut(nil)
        notchIslandWindow?.orderOut(nil)
        immersiveWindow?.orderOut(nil)
        externalImmersiveWindows.forEach { $0.orderOut(nil) }
        externalImmersiveWindows.removeAll()
        
        switch mode {
        case .floatingWidget:
            NSApp.presentationOptions = []
            floatingWindow?.makeKeyAndOrderFront(nil)
            floatingWindow?.ignoresMouseEvents = AppState.shared.isClickThrough
        case .notchIsland:
            NSApp.presentationOptions = []
            notchIslandWindow?.makeKeyAndOrderFront(nil)
            notchIslandWindow?.ignoresMouseEvents = false
        case .immersiveStudio:
            if let targetScreen = NSScreen.main ?? NSScreen.screens.first {
                immersiveWindow?.setFrame(targetScreen.frame, display: true)
            }
            NSApp.presentationOptions = [
                .autoHideMenuBar,
                .autoHideDock,
                .fullScreen
            ]
            immersiveWindow?.level = .screenSaver
            immersiveWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            
            updateExternalDisplayMirroring()
        }
    }
    
    public func updateExternalDisplayMirroring() {
        guard AppState.shared.displayMode == .immersiveStudio else {
            externalImmersiveWindows.forEach { $0.orderOut(nil) }
            externalImmersiveWindows.removeAll()
            return
        }
        
        if AppState.shared.mirrorOnExternalDisplay {
            let screens = NSScreen.screens
            guard screens.count > 1 else {
                externalImmersiveWindows.forEach { $0.orderOut(nil) }
                externalImmersiveWindows.removeAll()
                return
            }
            
            let primaryScreen = NSScreen.main ?? screens.first
            let secondaryScreens = screens.filter { $0 != primaryScreen }
            
            externalImmersiveWindows.forEach { $0.orderOut(nil) }
            externalImmersiveWindows.removeAll()
            
            for screen in secondaryScreens {
                let window = FullscreenImmersiveWindow(
                    contentRect: screen.frame,
                    styleMask: [.borderless],
                    backing: .buffered,
                    defer: false
                )
                window.contentViewController = NSHostingController(rootView: ImmersiveStudioView())
                window.backgroundColor = .black
                window.isOpaque = true
                window.hasShadow = false
                window.level = .screenSaver
                window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
                window.hidesOnDeactivate = false
                window.setFrame(screen.frame, display: true)
                window.orderFront(nil)
                
                externalImmersiveWindows.append(window)
            }
        } else {
            externalImmersiveWindows.forEach { $0.orderOut(nil) }
            externalImmersiveWindows.removeAll()
        }
    }
    
    public func updateClickThrough(_ enabled: Bool) {
        floatingWindow?.ignoresMouseEvents = enabled
    }
    
    public func updateAlwaysOnTop(_ enabled: Bool) {
        floatingWindow?.level = enabled ? .floating : .normal
    }
}

// MARK: - Key & Main Capable Borderless Fullscreen Window

final class FullscreenImmersiveWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

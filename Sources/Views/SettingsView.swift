import SwiftUI

public struct SettingsView: View {
    @ObservedObject var appState = AppState.shared
    @ObservedObject var detector = MusicDetector.shared
    @ObservedObject var audioSync = AudioSyncEngine.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab: SettingsTab = .appearance
    @State private var searchTitle: String = ""
    @State private var searchArtist: String = ""
    @State private var isSearching: Bool = false
    @State private var searchStatus: String? = nil
    
    public enum SettingsTab: String, CaseIterable, Identifiable {
        case appearance = "Appearance"
        case sync = "Sync & Timing"
        case library = "Library & Search"
        
        public var id: String { rawValue }
        
        public var icon: String {
            switch self {
            case .appearance: return "paintpalette.fill"
            case .sync: return "waveform.badge.magnifyingglass"
            case .library: return "music.note.list"
            }
        }
    }
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header with Tab Bar
            VStack(spacing: 12) {
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [detector.currentTrack.palette.accent, detector.currentTrack.palette.primary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Drift Preferences")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                            Text("Realtime Typography & Audio Visualizer")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button("Done") {
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                }
                
                // Segmented Pill Navigation Bar
                HStack(spacing: 6) {
                    ForEach(SettingsTab.allCases) { tab in
                        Button(action: {
                            withAnimation(.spring(response: 0.30, dampingFraction: 0.75)) {
                                selectedTab = tab
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 12))
                                Text(tab.rawValue)
                                    .font(.system(size: 12, weight: selectedTab == tab ? .bold : .medium))
                            }
                            .foregroundColor(selectedTab == tab ? .white : .secondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedTab == tab ? detector.currentTrack.palette.accent.opacity(0.85) : Color.white.opacity(0.06))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Tab Content
            ScrollView {
                VStack(spacing: 18) {
                    switch selectedTab {
                    case .appearance:
                        appearanceTab
                    case .sync:
                        syncTimingTab
                    case .library:
                        librarySearchTab
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 580, height: 600)
    }
    
    // MARK: - Tab 1: Appearance & Styles
    
    @ViewBuilder
    private var appearanceTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Display Mode Selector Cards
            settingsSection(title: "DISPLAY MODE", subtitle: "Choose how Drift floats on your Mac") {
                HStack(spacing: 10) {
                    ForEach(DriftDisplayMode.allCases) { mode in
                        let isSelected = appState.displayMode == mode
                        Button(action: {
                            appState.displayMode = mode
                            WindowManager.shared.switchMode(to: mode)
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: mode.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(isSelected ? detector.currentTrack.palette.accent : .secondary)
                                
                                Text(mode.shortName)
                                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? .white : .primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isSelected ? detector.currentTrack.palette.accent.opacity(0.18) : Color(NSColor.controlBackgroundColor))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(isSelected ? detector.currentTrack.palette.accent : Color.white.opacity(0.08), lineWidth: isSelected ? 1.5 : 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Text(appState.displayMode.description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
            
            // Fullscreen Kinetic Animation Style Cards
            settingsSection(title: "FULLSCREEN KINETIC LYRIC STYLE", subtitle: "Select kinetic choreography for Immersive Fullscreen mode") {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(KineticAnimationStyle.allCases) { style in
                        let isSelected = appState.kineticStyle == style
                        Button(action: {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                                appState.kineticStyle = style
                            }
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: style.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(isSelected ? detector.currentTrack.palette.accent : .secondary)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(style.displayName)
                                        .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                        .foregroundColor(isSelected ? .white : .primary)
                                    
                                    Text(styleCardSubtitle(style))
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 13))
                                        .foregroundColor(detector.currentTrack.palette.accent)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isSelected ? detector.currentTrack.palette.accent.opacity(0.18) : Color(NSColor.controlBackgroundColor))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(isSelected ? detector.currentTrack.palette.accent : Color.white.opacity(0.08), lineWidth: isSelected ? 1.5 : 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Text(appState.kineticStyle.description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
            
            // Typography & Appearance Card
            settingsSection(title: "TYPOGRAPHY & VISUALS") {
                VStack(spacing: 12) {
                    HStack {
                        Text("Font Family")
                            .font(.system(size: 12))
                            .frame(width: 140, alignment: .leading)
                        Picker("", selection: $appState.fontChoice) {
                            ForEach(LyricFont.allCases) { f in
                                Text(f.rawValue).tag(f)
                            }
                        }
                    }
                    
                    HStack {
                        Text("Font Size")
                            .font(.system(size: 12))
                            .frame(width: 140, alignment: .leading)
                        Slider(value: $appState.fontSize, in: 18...42, step: 1)
                        Text("\(Int(appState.fontSize)) pt")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .frame(width: 44, alignment: .trailing)
                    }
                    
                    HStack {
                        Text("Color Theme")
                            .font(.system(size: 12))
                            .frame(width: 140, alignment: .leading)
                        Picker("", selection: $appState.colorTheme) {
                            ForEach(DriftColorTheme.allCases) { theme in
                                Text(theme.rawValue).tag(theme)
                            }
                        }
                    }
                    
                    HStack {
                        Text("Backdrop Opacity")
                            .font(.system(size: 12))
                            .frame(width: 140, alignment: .leading)
                        Slider(value: $appState.backgroundOpacity, in: 0.1...0.95, step: 0.05)
                        Text("\(Int(appState.backgroundOpacity * 100))%")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .frame(width: 44, alignment: .trailing)
                    }
                    
                    Divider().padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Active Verse Karaoke Sweep Glow", isOn: $appState.karaokeProgressSweep)
                        Toggle("Show Audio Spectrum Waveform", isOn: $appState.showWaveform)
                        Toggle("Always On Top (Floating Above Windows)", isOn: $appState.isAlwaysOnTop)
                            .onChange(of: appState.isAlwaysOnTop) { _, newVal in
                                WindowManager.shared.updateAlwaysOnTop(newVal)
                            }
                        Toggle("Click-Through Mode (Ignores Mouse Clicks)", isOn: $appState.isClickThrough)
                            .onChange(of: appState.isClickThrough) { _, newVal in
                                WindowManager.shared.updateClickThrough(newVal)
                            }
                    }
                    .font(.system(size: 12))
                }
            }
        }
    }
    
    // MARK: - Tab 2: Sync & Timing
    
    @ViewBuilder
    private var syncTimingTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Music Player Source
            settingsSection(title: "MUSIC SOURCE", subtitle: "Select active audio player") {
                HStack(spacing: 8) {
                    ForEach(MusicSource.allCases) { source in
                        let isSelected = detector.preferredSource == source
                        Button(action: {
                            detector.preferredSource = source
                            if source == .demo {
                                detector.loadDemoTrack(index: 0, autoPlay: true)
                            } else {
                                detector.pollActivePlayer()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: source.iconName)
                                    .font(.system(size: 12))
                                Text(source.rawValue)
                                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isSelected ? detector.currentTrack.palette.accent.opacity(0.85) : Color(NSColor.controlBackgroundColor))
                            )
                            .foregroundColor(isSelected ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Lyrics Sync Calibration
            settingsSection(title: "ACOUSTIC SYNC CALIBRATION") {
                VStack(spacing: 12) {
                    Toggle("Live Acoustic Vocal Trigger (Computer Audio Beat Sync)", isOn: $audioSync.useAudioOnsetSync)
                        .font(.system(size: 12))
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Manual Offset")
                                .font(.system(size: 12))
                            Text(String(format: "%+.2f seconds", detector.syncOffset))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(detector.syncOffset == 0 ? .secondary : detector.currentTrack.palette.accent)
                        }
                        .frame(width: 140, alignment: .leading)
                        
                        Slider(value: $detector.syncOffset, in: -3.0...3.0, step: 0.05)
                        
                        Button("Reset") {
                            detector.syncOffset = 0.0
                        }
                        .buttonStyle(.bordered)
                        .font(.system(size: 11))
                    }
                }
            }
            
            // Word Flow & Pacing Tempo
            settingsSection(title: "VOCAL FLOW & TEMPO PACING") {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pacing Speed")
                                .font(.system(size: 12))
                            Text(String(format: "%.1fx (%@)", appState.pacingSpeedMultiplier, appState.pacingSpeedMultiplier < 0.85 ? "Ballad" : (appState.pacingSpeedMultiplier > 1.15 ? "Fast Pop" : "Normal")))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 140, alignment: .leading)
                        
                        Slider(value: $appState.pacingSpeedMultiplier, in: 0.6...1.4, step: 0.05)
                        
                        Button("Reset") {
                            appState.pacingSpeedMultiplier = 1.0
                        }
                        .buttonStyle(.bordered)
                        .font(.system(size: 11))
                    }
                    
                    Divider().padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Auto Ballad Tempo (Stretches word durations on slow songs)", isOn: $appState.autoBalladPacing)
                        Toggle("Group Short Phrases (Combines particles like 'to my', 'मेरी जान')", isOn: $appState.usePhraseChunking)
                    }
                    .font(.system(size: 12))
                }
            }
        }
    }
    
    // MARK: - Tab 3: Library & Live Search
    
    @ViewBuilder
    private var librarySearchTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Built-in Demo Tracks
            settingsSection(title: "BUILT-IN DEMO TRACKS", subtitle: "Test synced lyrics without launching music players") {
                VStack(spacing: 8) {
                    ForEach(0..<BuiltInDemoLyrics.songs.count, id: \.self) { idx in
                        let song = BuiltInDemoLyrics.songs[idx]
                        let isCurrent = detector.currentTrack.title == song.title
                        
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(detector.currentTrack.palette.accent.opacity(isCurrent ? 0.35 : 0.15))
                                    .frame(width: 38, height: 38)
                                
                                Image(systemName: isCurrent && detector.currentTrack.isPlaying ? "waveform" : "music.note")
                                    .font(.system(size: 16))
                                    .foregroundColor(detector.currentTrack.palette.accent)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(song.title)
                                    .font(.system(size: 12, weight: .bold))
                                Text(song.artist)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                detector.preferredSource = .demo
                                detector.loadDemoTrack(index: idx, autoPlay: true)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: isCurrent && detector.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                                    Text(isCurrent && detector.currentTrack.isPlaying ? "Playing" : "Play")
                                }
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(isCurrent ? detector.currentTrack.palette.accent : Color.white.opacity(0.1))
                                )
                                .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                    }
                }
            }
            
            // Manual Song Search via LRCLIB
            settingsSection(title: "SEARCH & TEST ANY SONG", subtitle: "Fetches synchronized lyrics & artwork from LRCLIB") {
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        TextField("Song Title (e.g. Starboy)", text: $searchTitle)
                            .textFieldStyle(.roundedBorder)
                        TextField("Artist (e.g. The Weeknd)", text: $searchArtist)
                            .textFieldStyle(.roundedBorder)
                        
                        Button(action: performManualSearch) {
                            if isSearching {
                                ProgressView().scaleEffect(0.6).frame(width: 70)
                            } else {
                                Text("Load Lyrics")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(searchTitle.isEmpty || isSearching)
                    }
                    
                    if let status = searchStatus {
                        HStack(spacing: 6) {
                            Image(systemName: status.contains("Loaded") ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            Text(status)
                                .font(.system(size: 11))
                        }
                        .foregroundColor(status.contains("Loaded") ? .green : .orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }
    
    // MARK: - Reusable Settings Card Container
    
    @ViewBuilder
    private func settingsSection<Content: View>(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                
                if let sub = subtitle {
                    Text(sub)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.8))
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(0.65))
            )
        }
    }
    
    private func styleCardSubtitle(_ style: KineticAnimationStyle) -> String {
        switch style {
        case .threeSlotReel: return "Vertical 3-Slot Reel"
        case .popPosterCanvas: return "Dynamic Pop Posters"
        case .staircaseCascade: return "Step-Down with Star"
        case .soloCinematicStream: return "Zooms & 3D Rolls"
        }
    }
    
    private func performManualSearch() {
        isSearching = true
        searchStatus = "Searching LRCLIB..."
        
        let testTrack = Track(
            id: UUID().uuidString,
            title: searchTitle,
            artist: searchArtist,
            album: "",
            duration: 240,
            position: 0,
            isPlaying: true,
            source: .demo
        )
        
        Task {
            var trackWithArt = testTrack
            let (data, pal) = await ArtworkService.shared.fetchArtworkDataAndPalette(for: testTrack)
            trackWithArt.artworkImage = data.flatMap { NSImage(data: $0) }
            trackWithArt.palette = pal
            
            let result = await LyricsService.shared.fetchLyrics(for: trackWithArt)
            await MainActor.run {
                isSearching = false
                if let parsed = result, !parsed.lines.isEmpty {
                    searchStatus = "Loaded \(parsed.lines.count) synchronized lines with album palette!"
                    detector.preferredSource = .demo
                    detector.currentTrack = trackWithArt
                    appState.lyrics = parsed
                    appState.activeLineIndex = 0
                } else {
                    searchStatus = "No lyrics found for '\(searchTitle)'. Try another query."
                }
            }
        }
    }
}

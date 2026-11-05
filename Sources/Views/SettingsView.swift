import SwiftUI

public struct SettingsView: View {
    @ObservedObject var appState = AppState.shared
    @ObservedObject var detector = MusicDetector.shared
    @ObservedObject var audioSync = AudioSyncEngine.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchTitle: String = ""
    @State private var searchArtist: String = ""
    @State private var isSearching: Bool = false
    @State private var searchStatus: String? = nil
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "music.note")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(detector.currentTrack.accentColor)
                    Text("Drift Preferences")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Preferences Form
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    // Display Mode
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DISPLAY MODE")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: $appState.displayMode) {
                            ForEach(DriftDisplayMode.allCases) { mode in
                                Label(mode.rawValue, systemImage: mode.icon).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: appState.displayMode) { _, newMode in
                            WindowManager.shared.switchMode(to: newMode)
                        }
                        
                        Text(appState.displayMode.description)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Music Player Source
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MUSIC PLAYER SOURCE")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: $detector.preferredSource) {
                            ForEach(MusicSource.allCases) { source in
                                Label(source.rawValue, systemImage: source.iconName).tag(source)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: detector.preferredSource) { _, newSource in
                            if newSource == .demo {
                                detector.loadDemoTrack(index: 0, autoPlay: true)
                            } else {
                                detector.pollActivePlayer()
                            }
                        }
                    }
                    
                    // Demo Songs Quick Pick
                    VStack(alignment: .leading, spacing: 8) {
                        Text("BUILT-IN DEMO TRACKS")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            ForEach(0..<BuiltInDemoLyrics.songs.count, id: \.self) { idx in
                                let song = BuiltInDemoLyrics.songs[idx]
                                Button(action: {
                                    detector.preferredSource = .demo
                                    detector.loadDemoTrack(index: idx, autoPlay: true)
                                }) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(song.title)
                                            .font(.system(size: 12, weight: .bold))
                                            .lineLimit(1)
                                        Text(song.artist)
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Typography & Styling
                    VStack(alignment: .leading, spacing: 14) {
                        Text("TYPOGRAPHY & APPEARANCE")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("Font Family")
                                .frame(width: 120, alignment: .leading)
                            Picker("", selection: $appState.fontChoice) {
                                ForEach(LyricFont.allCases) { f in
                                    Text(f.rawValue).tag(f)
                                }
                            }
                        }
                        
                        HStack {
                            Text("Font Size (\(Int(appState.fontSize))pt)")
                                .frame(width: 120, alignment: .leading)
                            Slider(value: $appState.fontSize, in: 18...42, step: 1)
                        }
                        
                        HStack {
                            Text("Color Theme")
                                .frame(width: 120, alignment: .leading)
                            Picker("", selection: $appState.colorTheme) {
                                ForEach(DriftColorTheme.allCases) { theme in
                                    Text(theme.rawValue).tag(theme)
                                }
                            }
                        }
                        
                        HStack {
                            Text("Backdrop Opacity (\(Int(appState.backgroundOpacity * 100))%)")
                                .frame(width: 120, alignment: .leading)
                            Slider(value: $appState.backgroundOpacity, in: 0.1...0.95, step: 0.05)
                        }
                        
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
                    
                    Divider()
                    
                    // Lyrics Sync Calibration
                    VStack(alignment: .leading, spacing: 10) {
                        Text("LYRICS SYNC CALIBRATION")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        Toggle("Computer Audio Vocal Beat Sync (Live Acoustic Trigger)", isOn: $audioSync.useAudioOnsetSync)
                        
                        HStack {
                            Text(String(format: "Manual Offset: %+.2f seconds", detector.syncOffset))
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .frame(width: 180, alignment: .leading)
                            
                            Slider(value: $detector.syncOffset, in: -3.0...3.0, step: 0.05)
                            
                            Button("Reset") {
                                detector.syncOffset = 0.0
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Manual Song Search
                    VStack(alignment: .leading, spacing: 10) {
                        Text("SEARCH & TEST ANY SONG")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        HStack {
                            TextField("Song Title (e.g. Starboy)", text: $searchTitle)
                                .textFieldStyle(.roundedBorder)
                            TextField("Artist (e.g. The Weeknd)", text: $searchArtist)
                                .textFieldStyle(.roundedBorder)
                            Button(action: performManualSearch) {
                                if isSearching {
                                    ProgressView().scaleEffect(0.6)
                                } else {
                                    Text("Load Lyrics")
                                }
                            }
                            .disabled(searchTitle.isEmpty || isSearching)
                        }
                        
                        if let status = searchStatus {
                            Text(status)
                                .font(.system(size: 11))
                                .foregroundColor(status.contains("Loaded") ? .green : .orange)
                        }
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 540, height: 580)
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

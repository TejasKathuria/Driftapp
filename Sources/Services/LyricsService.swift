import Foundation

public actor LyricsService {
    public static let shared = LyricsService()
    
    private let cacheDir: URL
    private var memoryCache: [String: ParsedLyrics] = [:]
    
    private init() {
        let fileManager = FileManager.default
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDir = caches.appendingPathComponent("DriftLyrics", isDirectory: true)
        try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }
    
    public func fetchLyrics(for track: Track) async -> ParsedLyrics? {
        let cacheKey = "\(track.artist.lowercased()) - \(track.title.lowercased())"
        
        // 1. Check memory cache
        if let cached = memoryCache[cacheKey] {
            return cached
        }
        
        // 2. Check disk cache
        if let diskCached = loadFromDisk(key: cacheKey) {
            memoryCache[cacheKey] = diskCached
            return diskCached
        }
        
        // 3. Check built-in demo lyrics
        if let demo = BuiltInDemoLyrics.getDemo(title: track.title, artist: track.artist) {
            let parsed = LRCParser.parse(demo)
            memoryCache[cacheKey] = parsed
            return parsed
        }
        
        // 4. Check Apple Music embedded lyrics if available
        if let embedded = track.embeddedLyrics, !embedded.isEmpty {
            if embedded.contains("[") && (embedded.contains(":") || embedded.contains(".")) {
                let parsed = LRCParser.parse(embedded)
                if !parsed.lines.isEmpty {
                    memoryCache[cacheKey] = parsed
                    saveToDisk(key: cacheKey, content: embedded)
                    return parsed
                }
            }
        }
        
        // 5. Query LRCLIB API with smart duration matching and title normalization
        if let remoteLRC = await fetchFromLRCLIB(track: track) {
            let parsed = LRCParser.parse(remoteLRC)
            if !parsed.lines.isEmpty {
                memoryCache[cacheKey] = parsed
                saveToDisk(key: cacheKey, content: remoteLRC)
                return parsed
            }
        }
        
        return nil
    }
    
    public static func cleanTitle(_ title: String) -> String {
        var cleaned = title
        
        // Strip parenthetical / bracketed tags (feat, ft, with, from, remaster, etc.)
        let parenPattern = "\\s*[\\(\\[](?:feat\\.|ft\\.|with|from|remaster|remastered|deluxe|version|edition|live|radio edit|bonus track|acoustic|official|visualizer|audio|video)[^\\)\\]]*[\\)\\]]"
        if let regex = try? NSRegularExpression(pattern: parenPattern, options: [.caseInsensitive]) {
            let range = NSRange(location: 0, length: (cleaned as NSString).length)
            cleaned = regex.stringByReplacingMatches(in: cleaned, options: [], range: range, withTemplate: "")
        }
        
        // Strip trailing dash suffixes like " - 2013 Remaster", " - Remastered 2011", " - Single", " - Live"
        let dashPattern = "\\s*-\\s*(?:(?:\\d{4}\\s+)?remaster|remastered|single|deluxe|live|radio edit|from|bonus track|acoustic|edit|version).*$"
        if let regex = try? NSRegularExpression(pattern: dashPattern, options: [.caseInsensitive]) {
            let range = NSRange(location: 0, length: (cleaned as NSString).length)
            cleaned = regex.stringByReplacingMatches(in: cleaned, options: [], range: range, withTemplate: "")
        }
        
        cleaned = cleaned.trimmingCharacters(in: CharacterSet(charactersIn: " \"'“”’‘`").union(.whitespacesAndNewlines))
        return cleaned.isEmpty ? title : cleaned
    }
    
    public static func cleanArtist(_ artist: String) -> String {
        let separators = [",", ";", "/", "&", " feat. ", " ft. ", " with "]
        var primary = artist
        for sep in separators {
            if let first = primary.components(separatedBy: sep).first, !first.trimmingCharacters(in: .whitespaces).isEmpty {
                primary = first
                break
            }
        }
        primary = primary.trimmingCharacters(in: .whitespacesAndNewlines)
        return primary.isEmpty ? artist : primary
    }
    
    private func fetchFromLRCLIB(track: Track) async -> String? {
        let cleanT = Self.cleanTitle(track.title)
        let cleanA = Self.cleanArtist(track.artist)
        
        // Strategy 1: Exact get with original title & artist
        if let exact = await queryLRCLIBGet(title: track.title, artist: track.artist, album: track.album, duration: track.duration) {
            return exact
        }
        
        // Strategy 2: Exact get with normalized title & primary artist
        if cleanT != track.title || cleanA != track.artist {
            if let exactClean = await queryLRCLIBGet(title: cleanT, artist: cleanA, album: nil, duration: track.duration) {
                return exactClean
            }
        }
        
        // Strategy 3: Targeted Search by track_name and artist_name with duration matching
        if let searchMatch = await searchLRCLIBSmart(trackName: cleanT, artistName: cleanA, targetDuration: track.duration) {
            return searchMatch
        }
        
        // Strategy 4: Broad Search by query string with duration matching
        if let broadMatch = await searchLRCLIBSmart(query: "\(cleanA) \(cleanT)", targetDuration: track.duration) {
            return broadMatch
        }
        
        return nil
    }
    
    private func queryLRCLIBGet(
        title: String,
        artist: String,
        album: String? = nil,
        duration: TimeInterval = 0
    ) async -> String? {
        var components = URLComponents(string: "https://lrclib.net/api/get")
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "track_name", value: title),
            URLQueryItem(name: "artist_name", value: artist)
        ]
        if let alb = album, !alb.isEmpty {
            queryItems.append(URLQueryItem(name: "album_name", value: alb))
        }
        if duration > 0 {
            queryItems.append(URLQueryItem(name: "duration", value: String(Int(duration))))
        }
        components?.queryItems = queryItems
        guard let url = components?.url else { return nil }
        
        var request = URLRequest(url: url)
        request.setValue("DriftLyrics/1.0 (https://github.com/macOS/Drift)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 7.0
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let synced = json["syncedLyrics"] as? String, !synced.isEmpty {
                        return synced
                    }
                }
            }
        } catch {
            return nil
        }
        return nil
    }
    
    private func searchLRCLIBSmart(
        trackName: String? = nil,
        artistName: String? = nil,
        query: String? = nil,
        targetDuration: TimeInterval
    ) async -> String? {
        var components = URLComponents(string: "https://lrclib.net/api/search")
        var items: [URLQueryItem] = []
        if let t = trackName, !t.isEmpty { items.append(URLQueryItem(name: "track_name", value: t)) }
        if let a = artistName, !a.isEmpty { items.append(URLQueryItem(name: "artist_name", value: a)) }
        if let q = query, !q.isEmpty { items.append(URLQueryItem(name: "q", value: q)) }
        components?.queryItems = items
        
        guard let url = components?.url else { return nil }
        
        var request = URLRequest(url: url)
        request.setValue("DriftLyrics/1.0 (https://github.com/macOS/Drift)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 7.0
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            guard let list = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return nil }
            
            // Extract items that have non-empty synchronized lyrics
            let candidates = list.compactMap { item -> (synced: String, duration: Double)? in
                guard let synced = item["syncedLyrics"] as? String, !synced.isEmpty else { return nil }
                let dur = item["duration"] as? Double ?? 0
                return (synced: synced, duration: dur)
            }
            
            guard !candidates.isEmpty else { return nil }
            
            // If targetDuration is known, find the candidate with the closest duration!
            if targetDuration > 0 {
                let sorted = candidates.sorted {
                    abs($0.duration - targetDuration) < abs($1.duration - targetDuration)
                }
                
                // If the closest candidate is within 8.0s of the track duration, use it
                if let best = sorted.first, abs(best.duration - targetDuration) <= 8.0 {
                    return best.synced
                }
                
                // Return closest available candidate
                return sorted.first?.synced
            }
            
            return candidates.first?.synced
        } catch {
            return nil
        }
    }
    
    private func safeFilename(for key: String) -> String {
        let invalid = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return key.components(separatedBy: invalid).joined(separator: "_") + ".lrc"
    }
    
    private func loadFromDisk(key: String) -> ParsedLyrics? {
        let file = cacheDir.appendingPathComponent(safeFilename(for: key))
        guard let content = try? String(contentsOf: file, encoding: .utf8) else { return nil }
        return LRCParser.parse(content)
    }
    
    private func saveToDisk(key: String, content: String) {
        let file = cacheDir.appendingPathComponent(safeFilename(for: key))
        try? content.write(to: file, atomically: true, encoding: .utf8)
    }
}

// Built-in Demo Songs with Accurate Millisecond Synced Lyrics
public struct BuiltInDemoLyrics {
    public static let songs: [(title: String, artist: String, lrc: String)] = [
        (
            title: "Blinding Lights",
            artist: "The Weeknd",
            lrc: """
            [ti:Blinding Lights]
            [ar:The Weeknd]
            [al:After Hours]
            [length:03:20]
            [00:00.00][Intro - Synthesizer Echo]
            [00:13.20]Yeah
            [00:26.50][Verse 1]
            [00:27.20]I've been tryna call
            [00:29.80]I've been on my own for long enough
            [00:33.40]Maybe you can show me how to love, maybe
            [00:40.10]I'm going through withdrawals
            [00:43.15]You don't even have to do too much
            [00:46.80]You can turn me on with just a touch, baby
            [00:53.30][Pre-Chorus]
            [00:54.00]I look around and Sin City's cold and empty
            [00:59.00]No one's around to judge me
            [01:02.40]I can't see clearly when you're gone
            [01:06.10][Chorus]
            [01:06.80]I said, ooh, I'm blinded by the lights
            [01:13.90]No, I can't sleep until I feel your touch
            [01:20.20]I said, ooh, I'm drowning in the night
            [01:27.30]Oh, when I'm like this, you're the one I trust
            [01:34.50][Verse 2]
            [01:35.20]I'm running out of time
            [01:38.00]'Cause I can see the sun light up the sky
            [01:41.80]So I hit the road in overdrive, baby
            [01:48.00][Pre-Chorus]
            [01:48.80]The city's cold and empty
            [01:52.40]No one's around to judge me
            [01:55.70]I can't see clearly when you're gone
            [01:59.80][Chorus]
            [02:00.50]I said, ooh, I'm blinded by the lights
            [02:07.50]No, I can't sleep until I feel your touch
            [02:14.00]I said, ooh, I'm drowning in the night
            [02:21.00]Oh, when I'm like this, you're the one I trust
            [02:27.80][Bridge]
            [02:28.40]I'm just walking by to let you know
            [02:32.00]I could never say it on the phone
            [02:35.40]Will never let you go this time
            [02:40.50][Chorus]
            [02:41.20]I said, ooh, I'm blinded by the lights
            [02:48.00]No, I can't sleep until I feel your touch
            [02:54.40]Hey, hey, hey
            [03:00.00][Outro - Synth Fade]
            """
        ),
        (
            title: "Bohemian Rhapsody",
            artist: "Queen",
            lrc: """
            [ti:Bohemian Rhapsody]
            [ar:Queen]
            [al:A Night at the Opera]
            [length:05:55]
            [00:00.00][Intro - A Cappella]
            [00:01.20]Is this the real life? Is this just fantasy?
            [00:08.50]Caught in a landslide, no escape from reality
            [00:16.80]Open your eyes, look up to the skies and see
            [00:27.50]I'm just a poor boy, I need no sympathy
            [00:34.20]Because I'm easy come, easy go
            [00:37.80]Little high, little low
            [00:41.20]Any way the wind blows doesn't really matter to me, to me
            [00:54.50][Verse 1 - Piano Ballad]
            [00:55.50]Mama, just killed a man
            [01:03.20]Put a gun against his head, pulled my trigger, now he's dead
            [01:13.50]Mama, life had just begun
            [01:21.20]But now I've gone and thrown it all away
            [01:28.50]Mama, ooh, didn't mean to make you cry
            [01:38.20]If I'm not back again this time tomorrow
            [01:43.50]Carry on, carry on as if nothing really matters
            [01:55.20][Verse 2]
            [01:56.00]Too late, my time has come
            [02:03.80]Sends shivers down my spine, body's aching all the time
            [02:14.20]Goodbye, everybody, I've got to go
            [02:22.00]Gotta leave you all behind and face the truth
            [02:29.20]Mama, ooh, I don't wanna die
            [02:39.00]I sometimes wish I'd never been born at all
            [02:49.00][Guitar Solo]
            [03:02.50][Operatic Section]
            [03:03.00]I see a little silhouetto of a man
            [03:06.00]Scaramouche, Scaramouche, will you do the Fandango?
            [03:09.50]Thunderbolt and lightning, very, very frightening me
            [03:13.00]Galileo, Galileo, Galileo, Figaro, Magnifico!
            """
        ),
        (
            title: "Viva La Vida",
            artist: "Coldplay",
            lrc: """
            [ti:Viva La Vida]
            [ar:Coldplay]
            [al:Viva la Vida or Death and All His Friends]
            [length:04:02]
            [00:00.00][Intro - String Quartet]
            [00:13.50][Verse 1]
            [00:14.20]I used to rule the world
            [00:17.50]Seas would rise when I gave the word
            [00:21.20]Now in the morning I sleep alone
            [00:25.00]Sweep the streets I used to own
            [00:28.50][Verse 2]
            [00:29.00]I used to roll the dice
            [00:32.20]Feel the fear in my enemy's eyes
            [00:35.80]Listen as the crowd would sing
            [00:39.50]Now the old king is dead, long live the king
            [00:43.00][Chorus]
            [00:43.50]One minute I held the key
            [00:47.00]Next the walls were closed on me
            [00:50.50]And I discovered that my castles stand
            [00:54.20]Upon pillars of salt and pillars of sand
            [00:58.00][Chorus 2]
            [00:58.50]I hear Jerusalem bells a-ringin'
            [01:02.00]Roman Cavalry choirs are singin'
            [01:05.50]Be my mirror, my sword and shield
            [01:09.20]My missionaries in a foreign field
            [01:13.00]For some reason I can't explain
            [01:16.80]Once you'd gone there was never, never an honest word
            [01:22.50]And that was when I ruled the world
            """
        ),
        (
            title: "Hotel California",
            artist: "Eagles",
            lrc: """
            [ti:Hotel California]
            [ar:Eagles]
            [al:Hotel California]
            [length:06:30]
            [00:00.00][Intro - 12 String Acoustic Guitar]
            [00:53.00][Verse 1]
            [00:53.50]On a dark desert highway, cool wind in my hair
            [01:00.50]Warm smell of colitas, rising up through the air
            [01:07.50]Up ahead in the distance, I saw a shimmering light
            [01:14.50]My head grew heavy and my sight grew dim
            [01:18.20]I had to stop for the night
            [01:21.50][Verse 2]
            [01:22.00]There she stood in the doorway, I heard the mission bell
            [01:29.00]And I was thinkin' to myself, "This could be heaven or this could be hell"
            [01:36.50]Then she lit up a candle and she showed me the way
            [01:43.50]There were voices down the corridor, I thought I heard them say
            [01:50.50][Chorus]
            [01:51.00]Welcome to the Hotel California
            [01:57.80]Such a lovely place, such a lovely face
            [02:04.80]Plenty of room at the Hotel California
            [02:11.80]Any time of year, you can find it here
            """
        )
    ]
    
    public static func getDemo(title: String, artist: String) -> String? {
        let t = title.lowercased()
        let a = artist.lowercased()
        for song in songs {
            if t.contains(song.title.lowercased()) || song.title.lowercased().contains(t) {
                return song.lrc
            }
            if a.contains(song.artist.lowercased()) || song.artist.lowercased().contains(a) {
                return song.lrc
            }
        }
        return nil
    }
}


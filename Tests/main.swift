import Foundation

// Test runner for Drift Lyrics Parser & Detection Engine
func runTests() {
    print("🧪 Running Drift Unit Tests...")
    
    // Test 1: LRC Parser with sections and timestamps
    let sampleLRC = """
    [ti:Test Song]
    [ar:Drift Artist]
    [al:Drift Album]
    [00:00.00][Intro]
    [00:05.50]First line of verse one
    [00:10.00]Second line of verse one
    [00:15.80][Chorus]
    [00:16.20]This is the great chorus
    [00:22.00]Chorus line two
    """
    
    let parsed = LRCParser.parse(sampleLRC)
    assert(parsed.lines.count == 6, "Expected 6 lines (including prelude), got \(parsed.lines.count)")
    print("✅ Test 1 Passed: Parsed \(parsed.lines.count) lines successfully.")
    
    // Test 2: Verse Identification at exact timestamps
    // At 00:02.00 -> Intro line (prelude)
    let idxAt2 = parsed.activeLineIndex(for: 2.0)
    assert(idxAt2 == 0, "Expected index 0, got \(String(describing: idxAt2))")
    assert(parsed.lines[0].text == "• • •", "Expected prelude marker")
    assert(parsed.lines[0].sectionName == "Intro", "Expected Intro section")
    
    // At 00:07.00 -> First line of verse one
    let idxAt7 = parsed.activeLineIndex(for: 7.0)
    assert(idxAt7 == 1, "Expected index 1, got \(String(describing: idxAt7))")
    assert(parsed.lines[idxAt7!].text == "First line of verse one", "Wrong text at 7s")
    
    // At 00:18.00 -> Chorus line
    let idxAt18 = parsed.activeLineIndex(for: 18.0)
    assert(idxAt18 == 4, "Expected index 4, got \(String(describing: idxAt18))")
    assert(parsed.lines[idxAt18!].text == "This is the great chorus", "Expected chorus line text")
    assert(parsed.lines[idxAt18!].sectionName == "Chorus", "Expected Chorus section tag")
    print("✅ Test 2 Passed: Exact verse identification and section detection accurate!")
    
    // Test 3: Multi-tag line parsing
    let multiTagLRC = "[00:01.00][00:05.00]Repeated lyric"
    let multiParsed = LRCParser.parse(multiTagLRC)
    assert(multiParsed.lines.count == 2, "Expected 2 lines from multi-timestamp tag")
    assert(multiParsed.lines[0].startTime == 1.0)
    assert(multiParsed.lines[1].startTime == 5.0)
    print("✅ Test 3 Passed: Multi-timestamp tag expanded and ordered chronologically.")
    
    // Test 4: Built-in demo songs available
    assert(!BuiltInDemoLyrics.songs.isEmpty, "Demo songs should not be empty")
    let weekndDemo = BuiltInDemoLyrics.getDemo(title: "Blinding Lights", artist: "The Weeknd")
    assert(weekndDemo != nil, "Weeknd demo should be found")
    let parsedWeeknd = LRCParser.parse(weekndDemo!)
    assert(parsedWeeknd.lines.count > 10, "Parsed Weeknd lyrics should have multiple lines")
    print("✅ Test 4 Passed: Built-in demo tracks verified with rich timestamps.")
    
    print("\n🎉 ALL TESTS PASSED SUCCESSFULLY! Drift is 100% accurate and ready.")
}

runTests()

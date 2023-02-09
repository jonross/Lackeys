import Foundation
import Carbon.HIToolbox
import XCTest

@testable import Lackeys

class EngineTests: XCTestCase {
    
    override func setUpWithError() throws {
        Key.setup()
    }

    /// Common engine configuration for test cases.

    private func engine() -> Engine {
        let e = Engine()
        let globals = e.bindings(scope: nil)
        globals.bind(nil, "Command H".asChord, SendKey("LeftArrow".asChord))
        globals.bind(nil, "Command J".asChord, SendKey("DownArrow".asChord))
        globals.bind(nil, "Command K".asChord, SendKey("UpArrow".asChord))
        globals.bind(nil, "Command L".asChord, SendKey("RightArrow".asChord))
        globals.bind("Command Semicolon".asChord, "G".asChord, OpenApp("Google Chrome"))
        let slack = e.bindings(scope: "Slack")
        slack.bind(nil, "Command G".asChord, SendKey("Command K".asChord))
        slack.bind(nil, "Command S".asChord, SendKey("Command G".asChord))
        let chrome = e.bindings(scope: "Google Chrome")
        chrome.bind(nil, "Command G".asChord, SendKey("Command L".asChord))
        return e
    }
    
    func testEngineBasics() {
        let e = engine()

        verify(e, .keyDown, false, "M", "pass unbound")
        verify(e, .keyDown, true, "M", "pass unbound")
        verify(e, .keyUp, false, "M", "pass unbound")
        
        verify(e, .keyDown, false, "Control Shift G", "pass unbound")
        verify(e, .keyDown, true, "Control Shift G", "pass unbound")
        verify(e, .keyUp, false, "Control Shift G", "pass unbound")
        
        verify(e, .keyDown, false, "Command J", "send DownArrow by globals")
        verify(e, .keyDown, true, "Command J", "send DownArrow by globals")
        verify(e, .keyUp, false, "Command J", "send DownArrow by globals")
    }
    
    func testAppBindings() {
        let e = engine()
        let G_KEY = Key.findByName(name: "G")!
        let K_KEY = Key.findByName(name: "K")!
        let L_KEY = Key.findByName(name: "L")!

        verify(e, .keyDown, false, "Command G", "pass unbound")
        verify(e, .keyUp, false, "Command G", "pass unbound")
        verify(e, .keyDown, false, "Command L", "send RightArrow by globals")
        verify(e, .keyDown, true, "Command L", "send RightArrow by globals")
        verify(e, .keyUp, false, "Command L", "send RightArrow by globals")

        e.setApp(name: "Chrome")
        assertBindingsFor(e, key: G_KEY, are: "none")
        assertBindingsFor(e, key: L_KEY, are: "none")

        // Should not match binding regex
        // Change apps with these keys down
        verify(e, .keyDown, false, "Command G", "pass unbound")
        verify(e, .keyDown, false, "Command L", "send RightArrow by globals")
        verify(e, .keyDown, true, "Command L", "send RightArrow by globals")

        e.setApp(name: "Google Chrome")
        assertBindingsFor(e, key: G_KEY, are: "globals")
        assertBindingsFor(e, key: L_KEY, are: "globals")

        // Prior bindings should receive keyUp? (not atm, see code)
        verify(e, .keyUp, false, "Command L", "send RightArrow by globals")
        verify(e, .keyUp, false, "Command G", "send Command L by Google Chrome")
        // Command G binding changed
        verify(e, .keyDown, false, "Command G", "send Command L by Google Chrome")
        verify(e, .keyUp, false, "Command G", "send Command L by Google Chrome")
        // Globals should still work
        // Change apps with these keys down
        verify(e, .keyDown, false, "Command L", "send RightArrow by globals")
        verify(e, .keyDown, true, "Command L", "send RightArrow by globals")
        verify(e, .keyDown, false, "Command G", "send Command L by Google Chrome")

        e.setApp(name: "Slack")
        assertBindingsFor(e, key: G_KEY, are: "Google Chrome")
        assertBindingsFor(e, key: L_KEY, are: "globals")
        
        // Prior bindings should receive keyUp? (not atm, see code))
        verify(e, .keyUp, false, "Command G", "send Command K by Slack")
        verify(e, .keyUp, false, "Command L", "send RightArrow by globals")
        // Command G binding changed
        verify(e, .keyDown, false, "Command G", "send Command K by Slack")
        verify(e, .keyUp, false, "Command G", "send Command K by Slack")
        // Globals should still work
        verify(e, .keyDown, false, "Command K", "send UpArrow by globals")
        verify(e, .keyDown, true, "Command K", "send UpArrow by globals")
        verify(e, .keyUp, false, "Command K", "send UpArrow by globals")

        e.setApp(name: nil)
        assertBindingsFor(e, key: G_KEY, are: "none")
        assertBindingsFor(e, key: L_KEY, are: "none")
        assertBindingsFor(e, key: K_KEY, are: "none")

        // Globals are back
        verify(e, .keyDown, false, "Command G", "pass unbound")
        verify(e, .keyUp, false, "Command G", "pass unbound")
        verify(e, .keyDown, false, "Command K", "send UpArrow by globals")
        verify(e, .keyUp, false, "Command K", "send UpArrow by globals")
        verify(e, .keyDown, true, "Command L", "send RightArrow by globals")
        verify(e, .keyUp, false, "Command L", "send RightArrow by globals")
    }

    func testUnboundLeaderKeyAfterLeaderKey() {
        let e = engine()
        verify(e, .keyDown, false, "Command Semicolon", "discard by globals")
        verify(e, .keyDown, true, "Command Semicolon", "discard ignored")
        verify(e, .keyUp, false, "Command Semicolon", "discard ignored")
        verify(e, .keyDown, false, "Command Semicolon", "pass unbound")
        verify(e, .keyDown, true, "Command Semicolon", "pass ignored")
        verify(e, .keyUp, false, "Command Semicolon", "pass ignored")
    }

    /// Assert that passing the usual args to `Engine.handle` results in an action matching
    /// the given description.
    
    private func verify(_ engine: Engine, _ type: CGEventType, _ dupe: Bool, _ chordDesc: String, _ expected: String) {
        let chord = Chord.parseFrom(chordDesc)!
        let (action, reason) = try! engine.handle(type: type, keycode: chord.key.code, dupe: dupe, flags: chord.flags)
        let actual = "\(action) \(reason)"
        XCTAssert(actual == expected, "Expected \(expected), got \(actual)")
    }

    private func assertBindingsFor(_ engine: Engine, key: Key, are: String) {
        let bindings = engine.activeKeys[key.code]
        let actual = bindings != nil ? "\(bindings!)" : "none"
        XCTAssert(actual == are, "Expected \(are), got \(actual)")
    }
}

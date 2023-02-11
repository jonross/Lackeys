/// This implements key translation.  Keep it separate from KeyTap and MacOS API calls in general,
/// so it's easy to unit test.

import Foundation
import Carbon.HIToolbox

class Engine {
    
    // Non-app-specific key bindings, if any
    private var globalBindings: Bindings?

    // Active app-specific key bindings, if any
    private var appBindings: Bindings?

    // App-specific key bindings for all apps
    private var perAppBindings: [String:Bindings] = [:]
    
    // What keys are pressed, and who gets the next event for each.
    var activeKeys: [Int:Bindings] = [:]

    // What keys are unbound or ignored until keyUp is received.
    var ignoredKeys: [Int:Action] = [:]

    init() {}

    /// Return the bindings for the named application, or global bindings if `nil`.
    /// Creates the `Bindings` instance if it doesn't yet exist.
    
    func bindings(scope: String?) -> Bindings {
        guard let scope = scope else {
            if globalBindings == nil {
                globalBindings = Bindings(desc: "globals", engine: self)
            }
            return globalBindings!
        }
        if let bindings = perAppBindings[scope] {
            return bindings
        }
        let bindings = Bindings(desc: "\(scope)", engine: self)
        perAppBindings[scope] = bindings
        return bindings
    }

    /// Called when the frontmost (active) application (if any) changes; switch to that app's bindings,
    /// or remove app-specific bindings if `name` is `nil`.
    
    func setApp(name: String?) {
        if let name = name, let bindings = perAppBindings[name] {
            Log.maps.info("bindings \(bindings) now active")
            appBindings = bindings
            return
        }
        Log.maps.info("global bindings restored")
        appBindings = nil
    }
    
    /**
        Initially I tried to code this with a state machine.  That quickly became unreadable. The better approach is 
        to keep track of all the down keys along with the bindings they initially found.  This ensures:

        * we find the right bindings for a keyUp or repeat keyDown; they should always be the same as for the 
          initial keyDown

        * no acrobatics are needed for the edge case of overlapping down  up events e.g. K down, J down, J up, K up

        * the logic is easy to follow

        This way, either ask an active key's bindings to handle the next event for that key, or handle it with the 
        applicable bindings for the key, checking each key receiver in order to see if it returns an action.
    */
            
    func handle(type: CGEventType, keycode: Int, dupe: Bool, flags: CGEventFlags) throws -> (Action, String) {
        
        if type != .keyUp && type != .keyDown {
            Log.maps.info("pass unwanted type \(type.rawValue)")
            return (PassKey(), "unwanted event")
        }
        
        guard let key = Key.findByCode(code: Int(keycode)) else {
            Log.maps.info("pass unknown key \(keycode)")
            return (PassKey(), "unknown key")
        }
        
        if !key.flags.isEmpty {
            Log.maps.info("pass modifier key \(key)")
            return (PassKey(), "modifier key")
        }

        if let action = ignoredKeys[key.code] {
            if type == .keyUp {
                Log.maps.info("\(key) no longer ignored")
                ignoredKeys[key.code] = nil
            }
            else {
                Log.maps.info("\(key) is ignored")
            }
            return (action, "ignored")
        }

        let chord = Chord(key: key, flags: flags)
        let gesture = Gesture(chord: chord, isKeyDown: type == .keyDown, isDupe: dupe)
        if Log.keys.enabled {
            Log.keys.info("got: \(gesture) = \(chord.key.code)")
        }
        
        if let bindings = appBindings, let action = bindings.receive(gesture) {
            Log.maps.info("  -> \(action) (\(bindings))")
            return (action, "by \(bindings)")
        }

        if let bindings = globalBindings, let action = bindings.receive(gesture) {
            Log.maps.info("  -> \(action) (\(bindings))")
            return (action, "by \(bindings)")
        }

        Log.maps.info("  -> pass (fell through)")
        return (PassKey(), "unbound")
    }
}

/// This class holds the normal and leader key mappings for global bindings, or for a single application.

class Bindings: CustomStringConvertible {
    let description: String                // for debugging
    let engine: Engine

    // Action for each non-prefixed key
    private var normalMap: [Chord: Action] = [:]

    // Sub-bindings for each leader key
    private var leaderMap: [Chord: [Chord: Action]] = [:]

    // This is non-nil when a key is pressed
    private var followerMap: [Chord: Action]? = nil
    
    init(desc: String, engine: Engine) {
        self.description = desc
        self.engine = engine
    }

    /**
        Bind a key to an action.
        - Parameters:
            - leader: if non-nil, the leader key for this binding
            - chord: key chord to trigger the action
            - action: action to trigger
     */

    func bind(_ leader: Chord?, _ chord: Chord, _ action: Action) {
        if let leader = leader {
            if leaderMap[leader] == nil {
                leaderMap[leader] = [:] as [Chord: Action]
            }
            leaderMap[leader]![chord] = action
        }
        else {
            normalMap[chord] = action
        }
    }

    /// Returns true if `bind()` was already used with this leader and chord.

    func has(_ leader: Chord?, _ chord: Chord) -> Bool {
        if let leader = leader {
            if leaderMap[leader] == nil {
                return false
            }
            return leaderMap[leader]![chord] != nil
        }
        return normalMap[chord] != nil
    }

    /// Process a single key event.  This handles special casing for key down, key repeat, and key up, while
    /// process(), below, handles key-specific details.

    func receive(_ gesture: Gesture) -> Action? {
        if gesture.isDupe {
            let action = process(gesture)
            // Only repeat KeyActions on repeated keys, not (for example) moving windows
            return action == nil || action is KeyAction ? action : DiscardKey()
        }
        else if gesture.isKeyDown {
            engine.activeKeys[gesture.chord.key.code] = self
            return process(gesture)
        }
        else {
            engine.activeKeys[gesture.chord.key.code] = nil
            let action = process(gesture)
            // Only take KeyActions for key ups, not (for example) moving windows
            return action == nil || action is KeyAction ? action : DiscardKey()
        }
    }
    
    /// See comment for receive(), above.

    private func process(_ gesture: Gesture) -> Action? {
        if let keyMap = followerMap {
            // A leader key is in effect, so consult its follower map.  We take action only on key down, no repeats,
            // and only once.  If it's not bound in the follower map, the next receiver gets the key.
            followerMap = nil
            let action = keyMap[gesture.chord]
            engine.ignoredKeys[gesture.chord.key.code] = action == nil ? PassKey() : DiscardKey()
            return action
        }
        else if let keyMap = leaderMap[gesture.chord] {
            // A leader key was typed, so establish its follower map and discard it.
            followerMap = keyMap
            engine.ignoredKeys[gesture.chord.key.code] = DiscardKey()
            return DiscardKey()
        }
        else {
            // Consult normal bindings, else pass to next receiver.
            return normalMap[gesture.chord]
        }
    }
}

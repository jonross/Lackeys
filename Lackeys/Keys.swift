/// Descriptions of all virtual keys we care about (class `Key`) + knows how to combine non-modifier
/// keys with one or more modifiers like Control and Shift (class `Chord`).

import Foundation
import Carbon.HIToolbox

class Key: Equatable, Hashable, CustomStringConvertible {
    
    let name: String
    let code: Int
    let flags: CGEventFlags
    
    /**
        This equality check works because the keys we care about comparing equally are non-modifiers.  For purposes of key mapping,
        we should be able to treat left shift and right shift "equally", but we never create bindings for them, so this is OK.
     */
    
    static func == (lhs: Key, rhs: Key) -> Bool {
        let ret = lhs.code == rhs.code
        return ret
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }

    var description: String {
        return name
    }
    
    static private var name2key: [String: Key] = [:]
    static private var code2key: [Int: Key] = [:]
    
    // These left-side modifier keys have visible definitions so we can easily get at their names and flag
    // bits, but they're otherwise no different from the right side ones set up later on.
    
    static let SHIFT = Key(named: "Shift", hasCode: kVK_Shift, andFlags: .maskShift)
    static let CONTROL = Key(named: "Control", hasCode: kVK_Control, andFlags: .maskControl)
    static let OPTION = Key(named: "Option", hasCode: kVK_Option, andFlags: .maskAlternate)
    static let COMMAND = Key(named: "Command", hasCode: kVK_Command, andFlags: .maskCommand)
    
    static let MODIFIERS = [SHIFT, CONTROL, OPTION, COMMAND]
    static let allModifierFlags = CGEventFlags(MODIFIERS.map({ return $0.flags }))
    
    class func setup() {
        Key(named: "A", hasCode: kVK_ANSI_A)
        Key(named: "B", hasCode: kVK_ANSI_B)
        Key(named: "C", hasCode: kVK_ANSI_C)
        Key(named: "D", hasCode: kVK_ANSI_D)
        Key(named: "E", hasCode: kVK_ANSI_E)
        Key(named: "F", hasCode: kVK_ANSI_F)
        Key(named: "G", hasCode: kVK_ANSI_G)
        Key(named: "H", hasCode: kVK_ANSI_H)
        Key(named: "I", hasCode: kVK_ANSI_I)
        Key(named: "J", hasCode: kVK_ANSI_J)
        Key(named: "K", hasCode: kVK_ANSI_K)
        Key(named: "L", hasCode: kVK_ANSI_L)
        Key(named: "M", hasCode: kVK_ANSI_M)
        Key(named: "N", hasCode: kVK_ANSI_N)
        Key(named: "O", hasCode: kVK_ANSI_O)
        Key(named: "P", hasCode: kVK_ANSI_P)
        Key(named: "Q", hasCode: kVK_ANSI_Q)
        Key(named: "R", hasCode: kVK_ANSI_R)
        Key(named: "S", hasCode: kVK_ANSI_S)
        Key(named: "T", hasCode: kVK_ANSI_T)
        Key(named: "U", hasCode: kVK_ANSI_U)
        Key(named: "V", hasCode: kVK_ANSI_V)
        Key(named: "W", hasCode: kVK_ANSI_W)
        Key(named: "X", hasCode: kVK_ANSI_X)
        Key(named: "Y", hasCode: kVK_ANSI_Y)
        Key(named: "Z", hasCode: kVK_ANSI_Z)
        
        Key(named: "0", hasCode: kVK_ANSI_0)
        Key(named: "1", hasCode: kVK_ANSI_1)
        Key(named: "2", hasCode: kVK_ANSI_2)
        Key(named: "3", hasCode: kVK_ANSI_3)
        Key(named: "4", hasCode: kVK_ANSI_4)
        Key(named: "5", hasCode: kVK_ANSI_5)
        Key(named: "6", hasCode: kVK_ANSI_6)
        Key(named: "7", hasCode: kVK_ANSI_7)
        Key(named: "8", hasCode: kVK_ANSI_8)
        Key(named: "9", hasCode: kVK_ANSI_9)
        
        Key(named: "Grave", hasCode: kVK_ANSI_Grave)
        Key(named: "Minus", hasCode: kVK_ANSI_Minus)
        Key(named: "Equal", hasCode: kVK_ANSI_Equal)
        
        Key(named: "LeftBracket", hasCode: kVK_ANSI_LeftBracket)
        Key(named: "RightBracket", hasCode: kVK_ANSI_RightBracket)
        Key(named: "Backslash", hasCode: kVK_ANSI_Backslash)
        
        Key(named: "Semicolon", hasCode: kVK_ANSI_Semicolon)
        Key(named: "Quote", hasCode: kVK_ANSI_Quote)
        
        Key(named: "Comma", hasCode: kVK_ANSI_Comma)
        Key(named: "Period", hasCode: kVK_ANSI_Period)
        Key(named: "Slash", hasCode: kVK_ANSI_Slash)
        
        Key(named: "Escape", hasCode: kVK_Escape)
        Key(named: "Delete", hasCode: kVK_Delete)
        Key(named: "Tab", hasCode: kVK_Tab)
        Key(named: "Return", hasCode: kVK_Return)
        Key(named: "Space", hasCode: kVK_Space)
        
        Key(named: "UpArrow", hasCode: kVK_UpArrow)
        Key(named: "DownArrow", hasCode: kVK_DownArrow)
        Key(named: "LeftArrow", hasCode: kVK_LeftArrow)
        Key(named: "RightArrow", hasCode: kVK_RightArrow)
        
        // Lets are lazy so touch them to force modifier key init.
        
        _ = MODIFIERS
        
        // These entries are only for logging / debugging.  Modifier keys aren't bindable in keymaps,
        // so we needn't worry that a mapping, say, works with Shift but not with RightShift (although
        // in theory you could write ".bind Command Shift_R K" in .lackeyrc and it would work.)
        
        Key(named: "Shift_R", hasCode: kVK_RightShift, andFlags: .maskShift)
        Key(named: "Control_R", hasCode: kVK_RightControl, andFlags: .maskControl)
        Key(named: "Option_R", hasCode: kVK_RightOption, andFlags: .maskAlternate)
        Key(named: "Command_R", hasCode: kVK_RightCommand, andFlags: .maskCommand)
    }
    
    @discardableResult
    private init(named: String, hasCode: Int, andFlags: CGEventFlags?) {
        self.name = named
        self.code = hasCode
        self.flags = andFlags ?? CGEventFlags([])
        Key.name2key[self.name.lowercased()] = self
        Key.code2key[self.code] = self
    }
    
    @discardableResult
    private convenience init(named: String, hasCode: Int) {
        self.init(named: named, hasCode: hasCode, andFlags: nil)
    }
    
    class func findByName(name: String) -> Key? {
        return Key.name2key[name.lowercased()]
    }
    
    class func findByCode(code: Int) -> Key? {
        return Key.code2key[code]
    }
}

/// A Chord describes a non-modifier key pressed in combination with zero or more modifiers (control, shift etc), which are represented
/// using `CGEventFlags` (it comes in the `CGEvent` and it's conveniently an `OptionSet`)

struct Chord: Equatable, Hashable, CustomStringConvertible {
    
    let key: Key
    let flags: CGEventFlags
    
    static func == (lhs: Chord, rhs: Chord) -> Bool {
        let ret = lhs.key == rhs.key && lhs.flags == rhs.flags
        return ret
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(flags.rawValue)
    }
    
    /**
        - Returns: Description in a form optimal for debugging e.g. `"[Command Shift] K (31)"`
     */
    
    var revealed: String {
        return flags.isEmpty ? "\(key.name) (\(key.code))" : "[\(modNames)] \(key.name) (\(key.code))"
    }
    
    /**
        - Returns: Description in a form usuable by `Chord.parseFrom` e.g. `"Command Shift K"`
            (if all modifiers are known)
     */
    
    var description: String {
        return flags.isEmpty ? key.name : "\(modNames) \(key)"
    }
    
    /**
        - Returns:Just the names of the modifier keys e.g. `"Command Shift"`.  NOTE: this may contain modifiers we don't
            handle, so it isn't guaranteed to work with `parseFrom`.
     */
    
    private var modNames: String {
        var buf: [String] = []
        if flags.contains(.maskAlphaShift) { buf.append("AlphaShift") }
        if flags.contains(.maskShift) { buf.append("Shift") }
        if flags.contains(.maskControl) { buf.append("Control") }
        if flags.contains(.maskAlternate) { buf.append("Option") }
        if flags.contains(.maskCommand) { buf.append("Command") }
        if flags.contains(.maskHelp) { buf.append("Help") }
        if flags.contains(.maskSecondaryFn) { buf.append("Secondary") }
        if flags.contains(.maskNumericPad) { buf.append("Numeric") }
        if flags.contains(.maskNonCoalesced) { buf.append("NonCoalesced") }
        return buf.joined(separator: " ")
    }
    
    /**
        Parse a human-readable form of a Chord as used for debugging or configuration.  The input may have any number of modifier key names and must end in the name of a key that isn't a modifier.
     
        - Parameters:
            - desc: e.g. `"Command Shift K"`
     
        - Returns: Optional `Chord`, or `nil` if parsing failed.
     */
    
    static func parseFrom(_ desc: String) -> Chord? {
        return parseWithErrorFrom(desc).0
    }
    
    /**
        This is the same as `parseFrom(String)` except that it also returns an optional error, for unit testing.
     
        - Parameters:
            - desc: e.g. `"Command Shift K"`
     
        - Returns: Optional `Chord`, and optional error string
     */
    
    static func parseWithErrorFrom(_ desc: String) -> (Chord?, String?) {
        var parts = desc.split(separator: " ", omittingEmptySubsequences: true).map({ return String($0) })
        if parts.count == 0 {
            return (nil, emptyChordError)
        }
        let keyName = parts.removeLast()
        guard let key = Key.findByName(name: keyName) else {
            return (nil, unknownKeyError(keyName))
        }
        if !key.flags.isEmpty {
            return (nil, mustEndWithKeyError)
        }
        let flagKeys = parts.map({ return Key.findByName(name: $0)})
        for (flagName, flagKey) in zip(parts, flagKeys) {
            if flagKey == nil {
                return (nil, unknownModifierError(flagName))
            }
            if flagKey!.flags.isEmpty {
                return (nil, mustBeModifiersError)
            }
        }
        let flags = CGEventFlags(flagKeys.map({ return $0!.flags }))
        return (Chord(key: key, flags: flags), nil)
    }
    
    // Parsing errors are defined as class fields so they're usable in unit tests.
    
    static let emptyChordError = "empty chord"
    static let unknownKeyError = { (name: String) in return "unknown key: \(name)" }
    static let unknownModifierError = { (name: String) in return "unknown modifier key: \(name)" }
    static let mustEndWithKeyError = "a key chord must not end with a modifier key"
    static let mustBeModifiersError = "all keys in a chord except the last must be modifier keys"
}

extension String {
    /// For use internally (like in unit tests) when we know a Chord description is parseable.
    var asChord: Chord {
        return Chord.parseFrom(self)!
    }
}

/// This combines the Chord of a known keystroke with additional information about the type of motion.

struct Gesture: CustomStringConvertible {
    let chord: Chord
    let isKeyDown: Bool
    let isDupe: Bool
    var description: String {
        return "\(isKeyDown ? "down" : "up")\(isDupe ? " dupe" : "") \(chord)"
    }
}


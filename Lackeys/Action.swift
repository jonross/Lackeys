/// Engine.swift maps keyboard events to these.
/// Key-related actions are handed back to the KeyTap for processing.
/// Other actions are executed directly by the Engine.

import Foundation

protocol Action: CustomStringConvertible {
}

/// A `KeyAction` is when we map one key to another, discard the key event, or give it back
/// to the O/S unmodified.

protocol KeyAction: Action {
}

/// Pass the received key event on to the next handler.

struct PassKey: KeyAction {
    var description: String {
        return "pass"
    }
}

/// Discard the received key event.

struct DiscardKey: KeyAction {
    var description: String {
        return "discard"
    }
}

/// Substitute a new key for the received key event.

struct SendKey: KeyAction {
    let chord: Chord
    init(_ chord: Chord) {
        self.chord = chord
    }
    var description: String {
        return "send " + chord.description
    }
}

/// Open an app

struct OpenApp: Action {
    let appName: String
    init(_ appName: String) {
        self.appName = appName
    }
    var description: String {
        return "open " + appName
    }
}

/// Run an externally handled command.

struct DoCommand: Action {
    let command: String
    init(_ command: String) {
        self.command = command
    }
    var description: String {
        return "run " + command
    }
}

/// Same as DoCommand but take the text from an alert dialog.

struct Prompt: Action {
    var description: String {
        return "prompt"
    }
}

/// Resize a window.

struct Resize: Action {
    let tweaks: Tweaks
    init(_ tweaks: Tweaks) {
        self.tweaks = tweaks
    }
    var description: String {
        return "resize \(tweaks)"
    }
}

/// Move a window to the next screen.

struct NextScreen: Action {
    var description: String {
        return "next"
    }
}

extension String {

    /// Attempt to parse an action as a string e.g `"resize 0 0 50% 50%"`; return the
    /// `Action` subclass if successful, else `nil`.

    func asAction() -> Action? {
        return asActionWithError().0
    }

    /// Like `asAction` but also provide error detail.  Either the `Action` or error string
    /// element of the returned tuple will be set.

    func asActionWithError() -> (Action?, String?) {
        let (name, args) = self.cleave(" ")
        if ["next", "prompt"].contains(name) {
            if args.count != 0 {
                return (nil, "the \(name) action takes no additional information")
            }
            switch name {
                case "next":
                    return (NextScreen(), nil)
                case "prompt":
                    return (Prompt(), nil)
                default:
                    break
            }
        }
        else if ["send", "resize", "open", "order"].contains(name) {
            if args.count == 0 {
                return (nil, "the '\(name)' action needs more information")
            }
            switch name {
                case "send":
                    let (chord, error) = Chord.parseWithErrorFrom(args)
                    return chord != nil ? (SendKey(chord!), nil) : (nil, error)
                case "resize":
                    let tweaks = Tweaks.parse(args)
                    return tweaks != nil ? (Resize(tweaks!), nil) : (nil, "invalid syntax for resize: \(args)")
                case "order":
                    return (DoCommand(args), nil)
                case "open":
                    return (OpenApp(args), nil)
                default:
                    break
            }
        }
        return (nil, "unknown action: '\(name)'")
    }
}

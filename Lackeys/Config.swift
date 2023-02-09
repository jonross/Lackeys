import Foundation

/// Parser for ~/.lackeys
/// Note, a `Config` is highly stateful and self-modifies as it parses.

class Config {

    private let engine: Engine
    // Lines read from .lackeys
    private var lines: [String] = []
    // What line is being processed
    private var index: Int = 0
    // Errors accumulated so far
    var errors: [String] = []
    // Index from "L1" ... "L9" to actual key chords
    private var leaders: [String:Chord] = [:]
    // What apps are we parsing bindings for; public for testing
    var scopes: [String?] = [nil]

    init(forEngine: Engine) {
        engine = forEngine
    }

    /**
        Reload ~/.lackeyrc and apply it to the key `Engine`.
        TODO: Clear the engine state so this can be used more than once.

        - Returns: `true` if successful, `false` otherwise; errors may be retrieved from the `.errors` field.
     */

    func readAndApply() -> Bool {
        errors = []
        guard let home = ProcessInfo.processInfo.environment["HOME"] else {
            errors.append("HOME environment variable isn't set")
            return false
        }
        let configPath = "\(home)/.lackeys"
        let fm = FileManager.default
        // Create it if it doesn't exist yet
        if !fm.fileExists(atPath: configPath) {
            if !fm.createFile(atPath: configPath, contents: "".data(using: .utf8)!, attributes: nil) {
                errors.append("Can't create \(configPath)")
                return false
            }
            return true
        }
        do {
            let contents = try String(contentsOfFile: configPath)
            Log.main.info("Applying configuration from \(configPath)")
            apply(contents)
        }
        catch {
            errors.append("Can't read \(configPath): \(error)")
            return false
        }
        return errors.count == 0
    }

    /**
        Apply a configuration to the engine.

        - Parameter text: If specified, the configuration text; if not, we assume it's already been
            read in from ~/.lackeys
     */

    func apply(_ text: String?) {
        if let text = text {
            lines = text.split(separator: "\n").map({ return $0.str.strip() })
        }
        for (i, line) in lines.enumerated() {
            index = i + 1
            if line.count == 0 || line.first == Character("#") {
                continue
            }
            let (command, args) = line.cleave(" ")
            switch command {
                case "in":
                    doScope(args)
                case "bind":
                    doBind(args)
                case "leader":
                    doLeader(args)
                default:
                    oops("unrecognized configuration command: \(command)")
            }
        }
    }

    /// Process the "in" command.

    private func doScope(_ args: String) -> Void? {
        if args.count == 0 {
            return oops("missing list of application names")
        }
        scopes = args.split(separator: ",").map({ return $0.str.strip() })
        return nil
    }

    /// Process a "bind" command.  This is done incrementally with string sectioning, rather than a
    /// regexp, so we can provide more accurate error messaages.

    private func doBind(_ args: String) -> Void? {

        // Split e.g. "L1 Command G to send Command L"
        // into "L1 Command G" and "send Command L"
        if args.match(#"\bto\b"#) == nil {
            return oops("bind syntax is: bind [leader] <chord> to <action>")
        }
        let (eventStr, actionStr): (String, String) = args.cleave(" to ")
        if actionStr.count == 0 {
            return oops("bind command is missing action")
        }
        var chordStr = eventStr

        // Split the optional leader string from the chord and validate it.
        var leader: Chord? = nil
        if eventStr.match(#"^L[1-9]\b"#) != nil {
            let (leadStr, rest) = eventStr.cleave(" ")
            leader = leaders[leadStr]
            if leader == nil {
                return oops("leader \(leadStr) is unset")
            }
            chordStr = rest
        }

        // Validate the key chord.
        if chordStr.count == 0 {
            return oops("bind command is missing a key chord")
        }
        guard let chord = Chord.parseFrom(chordStr) else {
            return oops("\(chordStr) is not a valid key combination")
        }

        // Validate the action.
        let (action, error) = actionStr.asActionWithError()
        if action == nil {
            return oops(error!)
        }

        // Bind the leader and chord to the action in each active scope.
        for scope in scopes {
            let bindings = engine.bindings(scope: scope)
            if bindings.has(leader, chord) {
                let whereBound = scope == nil ? "" : " in \(scope!)"
                oops("\(eventStr) is already bound\(whereBound)")
            }
            else {
                bindings.bind(leader, chord, action!)
            }
        }

        return nil
    }

    /// Process the "leader" command.

    private func doLeader(_ args: String) -> Void? {
        let (name, chordStr) = args.cleave(" ")
        if name.count == 0 || chordStr.count == 0 {
            return oops("leader command needs more information")
        }
        if name.match("^L[1-9]$") == nil {
            return oops("valid leader names are L1, L2 ... L9")
        }
        let (chord, error) = Chord.parseWithErrorFrom(chordStr)
        if error != nil {
            return oops(error!)
        }
        leaders[name] = chord!
        return nil
    }

    /// Issue an error for the current line in the config file.  This returns a discardale value so callers
    /// don't need a separate `return` statement after calling it.

    private func oops(_ message: String) -> Void? {
        errors.append("line \(index): \(message)")
        return nil
    }
}

/// A simple wrapper on OSLog, because I am not typing three keywords every time I want to log something.
///
/// TODO: rewrite this.  We don't need separate levels per logger, we need more specialized loggers.
/// One for key clicks, one for user errors, one for internal errors etc.

import Foundation
import OSLog

class Log {
    
    // Disable this before a release.
    private static let debugging = true
    
    // The log for key events and mapping.  Under normal operation, this won't do anything
    // because the volume of messages is too high.
    static let keys = CustomLog(category: "keys", enabled: debugging)
    
    // The log for everything else.
    static let main = CustomLog(category: "main", enabled: true)

    class CustomLog {
        let enabled: Bool
        private let log: OSLog
        
        init(category: String, enabled: Bool) {
            self.log = OSLog(subsystem: subsystem(), category: category)
            self.enabled = enabled
        }
        
        func info(_ message: String) {
            if enabled {
                os_log("%s", log: self.log, type: .info, message)
            }
        }
        
        func error(_ message: String) {
            if enabled {
                os_log("%s", log: self.log, type: .error, message)
            }
        }
    }
    
    private class func subsystem() -> String {
        return Bundle.main.bundleIdentifier ?? "unknown"
    }
}

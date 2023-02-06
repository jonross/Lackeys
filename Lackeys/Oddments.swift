/// This is mostly extensions to standard types, for reducing boilerplate code.

import Foundation
import Cocoa

extension String {

    /// I would prefer this to not return an optional, but that's not possible.
    var asRegex: NSRegularExpression? {
        do {
            return try NSRegularExpression(pattern: self)
        }
        catch {
            return nil
        }
    }

    /// Calling this is the same as
    /// `pattern.asRegex!.match(self)
    func match(_ pattern: String) -> MatchResult? {
        return pattern.asRegex!.match(self)
    }

    /// Like `str.strip()` in Python.
    func strip() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines) 
    }

    /// Split a string into two trimmed parts on a separator.  This assumes the separator is present; if not, the
    /// second element of the tuple will be an empty string.
    func cleave(_ separator: String) -> (String, String) {
        if let range = self.range(of: separator) {
            return (self[self.startIndex..<range.lowerBound].str, self[range.upperBound..<self.endIndex].str)
        }
        else {
            return (self, "")
        }
    }
}

extension Substring {
    /// Convert a subsequence back into a normal string without having to wrap it in a cast.
    var str: String {
        return String(self)
    }
}

/// Make regular expressions more Pythonic.

extension NSRegularExpression {
    /// Similar to Python `re.match`
    func match(_ s: String) -> MatchResult? {
        let nsRange = NSRange(s.startIndex..<s.endIndex, in: s)
        return self.firstMatch(in: s, options: [], range: nsRange)
            .map({ return MatchResult(target: s, check: $0) })
    }
}

struct MatchResult {
    let target: String
    let check: NSTextCheckingResult
    func group(_ named: String) -> String? {
        let nsRange = check.range(withName: named)
        if nsRange.location != NSNotFound, let range = Range(nsRange, in: target) {
            return String(target[range])
        }
        return nil
    }
}


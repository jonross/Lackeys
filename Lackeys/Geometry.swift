/// Helpers for Foundation geometry types that are relevant to window management.
/// These make calling code easier to read.

import Foundation

extension CGFloat {
    /// Convenient shortcut to max float
    static var max: CGFloat { return CGFloat.greatestFiniteMagnitude }
}

extension String {
    func asCGFloat() -> CGFloat? {
        if let value = Float(self) {
            return CGFloat(value)
        }
        return nil
    }
}

extension CGPoint {
    /// Caldulate distance between points.
    func distanceTo(_ other: CGPoint) -> CGFloat {
        return hypot(self.x - other.x, self.y - other.y)
    }

    /// Scale point by a constant factor.
    func scale(_ factor: CGFloat) -> CGPoint {
        return CGPoint(x: x * factor, y: y * factor)
    }
}

extension CGSize {
    /// Area calculation
    var area: CGFloat { return width * height }

    /// Scale size by a constant factor.
    func scale(_ factor: CGFloat) -> CGSize {
        return CGSize(width: width * factor, height: height * factor)
    }
}

extension CGRect: CustomStringConvertible {
    /// CGRect already defines the center point but not as a CGPoint; fix that.
    var center: CGPoint { return CGPoint(x: self.midX, y: self.midY) }

    /// Reduce typing in CGRect construction.
    init (_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) {
        self.init(origin: CGPoint(x: x, y: y), size: CGSize(width: width, height: height))
    }

    /// For debugging and testing.
    public var description: String {
        return "\(Int(self.minX)) \(Int(self.minY)) \(Int(self.width)) \(Int(self.height))"
    }

    /// For debugging and testing; construct a CGRect from our description format.
    static func parse(_ s: String) -> CGRect? {
        let parts = s.split(separator: " ", omittingEmptySubsequences: true).map({ return String($0).asCGFloat() })
        if parts.count != 4 || !parts.allSatisfy({ return $0 != nil }) {
            return nil
        }
        return CGRect(parts[0]!, parts[1]!, parts[2]!, parts[3]!)
    }

    /// Given a list of rectangles, return the index + rectangle with the most overlap (largest area.)
    /// Returns nil if the list is empty.
    func bestOverlap(_ list: [CGRect]) -> (Int, CGRect)? {
        if list.count == 0 {
             return nil
        }
        let sorted = list
            .map({ return $0.intersection(self).area })
            .enumerated()
            .sorted(by: { (a, b) in return b.1 < a.1 })
        let index = sorted[0].0
        return (index, list[index])
    }

    /// Area calculation
    var area: CGFloat { return size.area }

    /// Scale origin and size by a constant factor
    func scale(_ factor: CGFloat) -> CGRect {
        return CGRect(origin: origin.scale(factor), size: size.scale(factor))
    }
}

/**
    This represents a number that can be

    - a literal window setting, like "10" (pixels)
    - a percent of a window dimension, like "20%" 
*/

enum Amount: CustomStringConvertible {
    case literal(_ value: CGFloat)
    case percent(_ percent: Int)

    var raw: CGFloat {
        switch self {
            case let .literal(value): return value
            case let .percent(percent): return CGFloat(percent) / 100
        }
    }

    /// Return the coordinate value relative to another value, which is the original value for `.literal`, and a
    /// percentage of the window dimension if `.percent`.
    func actual(_ base: CGFloat, _ dim: CGFloat) -> CGFloat {
        switch self {
            case let .literal(value): return value
            case let .percent(_): return base + self.raw * dim
        }
    }

    /// Return dimensino the value relative to another value, which is the original value for `.literal`, and a
    /// percentage of the window dimension if `.percent`.
    func actual(_ dim: CGFloat) -> CGFloat {
        switch self {
            case let .literal(value): return value
            case let .percent(percent): return self.raw * dim
        }
    }

    /// For debugging and config file support: parse an `Amount` from a string.
    static func parse(_ s: String) -> Amount? {
        if s == "*" {
            return Amount.percent(100)
        }
        if let last = s.last, last == "%" {
            if let percent = Int(String(s.dropLast())) {
                return Amount.percent(percent)
            }
            return nil
        }
        return s.asCGFloat().map({ return Amount.literal($0) })
    }

    var description: String {
        switch self {
            case let .literal(value): return "\(value)"
            case let .percent(percent): return "\(percent)%"
        }
    }
}

/**
    This represents a change to a window setting, either absolute, like setting it to "100", or a delta, like ".+100" 
    or ".-100", or an edge offset, like "*-100.  Any of these may also be percentages.  Combined with three other 
    instances, this is used to implement the `resize` command.
 */

enum Tweak: CustomStringConvertible {
    case set(_ new: Amount)
    case delta(_ delta: Amount)
    case offset(_ offset: Amount)

    // Given a coordinate value and the equivalent base coordinate & dimension of a target rectangle,
    // alter the value relative to the target.

    func tweak(_ value: CGFloat, base: CGFloat, dim: CGFloat) -> CGFloat {
        switch (self) {
            case let .set(new): return new.actual(base, dim)
            case let .delta(delta): return value + delta.actual(base, dim)
            case let .offset(offset): return dim + offset.actual(base, dim)
        }
    }

    // Given a dimension and the equivalent & dimension of a target rectangle,
    // alter the dimension relative to the target.

    func tweak(_ value: CGFloat, dim: CGFloat) -> CGFloat {
        switch (self) {
            case let .set(new): return new.actual(dim)
            case let .delta(delta): return value + delta.actual(dim)
            case let .offset(offset): return dim + offset.actual(dim)
        }
    }

    /// For debugging: parse a `Tweak` from a string.
    static func parse(_ s: String) -> Tweak? {
        if s.first == nil {
            return nil
        }
        if s == "." {
            // zero delta from current value
            return Tweak.delta(Amount.literal(0))
        }
        if s.first == Character(".") {
            // parse delta from current value
            return Amount.parse(String(s.dropFirst())).map({ return Tweak.delta($0) })
        }
        if s == "*" {
            // zero offset from maximum value
            return Tweak.offset(Amount.literal(0))
        }
        if s.first == Character("*") {
            // parse offset from maximum value
            return Amount.parse(String(s.dropFirst())).map({ return Tweak.offset($0) })
        }
        // parse new value
        return Amount.parse(s).map({ return Tweak.set($0) })
    }

    /// For debugging
    var description: String {
        switch self {
            case let .set(new): return "\(new.raw)"
            case let .delta(delta): return ".\(delta.raw < 0 ? "" : "+")\(delta.raw)"
            case let .offset(offset): return "*\(offset.raw < 0 ? "" : "+")\(offset.raw)"
        }
    }
}

/// Combined tweaks to the origin and size of a rectangle.
/// This is used to implement the `resize` command.

struct Tweaks {
    let x, y, width, height: Tweak

    /**
        Apply one tweak to each of the origin X, origin Y, width and height of a rectangle,
        relative to a larger containing rectangle.
     */

    func tweak(_ rect: CGRect, within: CGRect) -> CGRect {
        return CGRect(x.tweak(rect.minX, base: within.minX, dim: within.width),
                      y.tweak(rect.minY, base: within.minY, dim: within.height),
                      width.tweak(rect.width, dim: within.width),
                      height.tweak(rect.height, dim: within.height))
    }

    /// For debugging: parse four `Tweak`s from a string.
    static func parse(_ s: String) -> Tweaks? {
        let parts = s.split(separator: " ", omittingEmptySubsequences: true)
            .map({ return Tweak.parse(String($0)) })
        if parts.count != 4 || !parts.allSatisfy({ return $0 != nil }) {
            return nil
        }
        return Tweaks(x: parts[0]!, y: parts[1]!, width: parts[2]!, height: parts[3]!)
    }

    /// For debugging
    var description: String {
        return "\(x) \(y) \(width) \(height)"
    }
}

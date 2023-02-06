/**
    Here we hide our experiences with the Accessibility API, which is, to be frank, painful.

    Many AX calls return a status.  In all cases below where an optional value is returned, we've logged that
    status if the return is nil.
 */

import Foundation
import AppKit

/**
    - Returns: the `AXUIElement` representing the frontmost application window, or `nil` if this could not be
      determined.
 */

func frontmostWindow() -> AXUIElement? {
    let frontApp = NSWorkspace.shared.frontmostApplication
    guard let frontPID = frontApp?.processIdentifier else {
        Log.main.error("Unable to get frontmost app PID")
        return nil
    }
    let frontmostApplicationElement = AXUIElementCreateApplication(frontPID)
    var frontmostValue: AnyObject?
    let status = AXUIElementCopyAttributeValue(frontmostApplicationElement, kAXFocusedWindowAttribute as CFString, &frontmostValue)
    if status != .success {
        Log.main.error("Error retrieving frontmost: \(status)")
        return nil
    }
    return (frontmostValue as! AXUIElement)
}

extension AXUIElement {

    /**
        - Returns: the bounds of a window's `AXUIElement`, or `nil` if this could not be determined.
          This merely combines `origin()` and `size()`.
     */

    func bounds() -> CGRect? {
        if let origin = self.origin(), let size = self.size() {
            return CGRect(origin: origin, size: size)
        }
        return nil
    }

    /**
        - Returns: the top left corner coordinate of a window's `AXUIElement`, or `nil` if this could not be
          determined.
     */

    func origin() -> CGPoint? {
        var originValue: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(self, kAXPositionAttribute as CFString, &originValue)
        if status != .success {
            Log.main.error("Error retrieving position: \(status)")
            return nil
        }
        let axValue = originValue as! AXValue
        var origin: CGPoint = .zero
        if !AXValueGetValue(axValue, .cgPoint, &origin) {
            Log.main.error("Cannot extract CGPoint from AXValue")
            return nil
        }
        return origin
    }

    /**
        - Returns: the size of a window's `AXUIElement`, or `nil` if this could not be determined.
     */

    func size() -> CGSize? {
        var sizeValue: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(self, kAXSizeAttribute as CFString, &sizeValue)
        if status != .success {
            Log.main.error("Error retrieving size: \(status)")
            return nil
        }
        let axValue = sizeValue as! AXValue
        var size: CGSize = .zero
        if !AXValueGetValue(axValue, .cgSize, &size) {
            Log.main.error("Cannot extract CGSize from AXValue")
            return nil
        }
        return size
    }

    /**
        Alter the rectangle occupied by a window's `AXUIElement`.
        This merely combines `setOrigin()` and `setSize()`.
     */

    func setBounds(_ bounds: CGRect) {
        self.setOrigin(bounds.origin)
        self.setSize(bounds.size)
    }

    /**
        Alter the top left corner coordinate of a window's `AXUIElement`.
     */

    func setOrigin(_ origin: CGPoint) {
        var mutableOrigin = origin
        guard let axOrigin = AXValueCreate(AXValueType.cgPoint, &mutableOrigin) else {
            Log.main.error("Cannot extract CGPoint from AXValue")
            return
        }
        AXUIElementSetAttributeValue(self, kAXPositionAttribute as CFString, axOrigin)
    }

    /**
        Alter the size of a window's `AXUIElement`.
     */

    func setSize(_ size: CGSize) {
        var mutableSize = size
        guard let axSize = AXValueCreate(AXValueType.cgSize, &mutableSize) else {
            Log.main.error("Cannot extract CGSize from AXValue")
            return
        }
        AXUIElementSetAttributeValue(self, kAXSizeAttribute as CFString, axSize)
    }
}

// For debugging, because AXError doesn't seem to have a string representation.  :(

extension AXError: CustomStringConvertible {
    public var description: String {
        switch self {
            case .success:
                return "success"
            case .failure:
                return "failure"
            case .illegalArgument:
                return "illegal argument"
            case .invalidUIElement:
                return "invalid UIElement"
            case .invalidUIElementObserver:
                return "invalid UIElementObserver"
            case .cannotComplete:
                return "cannot complete"
            case .attributeUnsupported:
                return "attribute unsupported"
            case .actionUnsupported:
                return "action unsupported"
            case .notificationUnsupported:
                return "notification unsupported"
            case .notImplemented:
                return "not implemented"
            case .notificationAlreadyRegistered:
                return "notification already registered"
            case .notificationNotRegistered:
                return "notification not registered"
            case .apiDisabled:
                return "API disabled"
            case .noValue:
                return "no value"
            case .parameterizedAttributeUnsupported:
                return "parameterized attribute unsupported"
            case .notEnoughPrecision:
                return "not enough precision"
            @unknown default:
                return "unknown"
        }
    }
}


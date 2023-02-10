/// Watch keyboard events.
/// Heartfelt thanks to these authors for lighting the way.
///
/// https://github.com/ZevEisenberg/Keyb/blob/main/Packages/Sources/EventHandler/EventHandler.swift
/// https://github.com/ZevEisenberg/Keyb/blob/main/Packages/Sources/KeyProcessor/KeyProcessor.swift
/// https://github.com/habibalamin/Metalt/blob/master/Metalt/AltToMetaTransformer.swift

import Foundation
import Carbon.HIToolbox
import ApplicationServices.HIServices

class KeyTap {
    
    enum TapState {
        case manuallyDisabled
        case disabledPendingAccess
        case disabledDueToError
        case enabled
    }
    
    private let tapData: TapData
    private var _state = TapState.manuallyDisabled
    private var tap: CFMachPort?
    
    /// TODO: We should not have an instance of AppControl.

    init(engine: Engine, controls: AppControl) {
        self.tapData = TapData(engine, controls)
    }
    
    /// TODO: reread property docs; do I need a separate variable for this?
    
    var state: TapState {
        get { return _state }
    }
    
    /// Create and enable the key event tap, if it doesn't already exist.  The result of the attempt is left in the
    /// `.state` property.
    
    func enable() {
        if _state == .enabled {
            return
        }
        if canEnable() {
            // Should be able to start the event tap
            if createAndEnable(haveAccess: true) {
                // All is well
                _state = .enabled
            } else {
                // Something went wrong
                _state = .disabledDueToError
            }
        } else {
            // Try to start so the user is prompted for accessibility.  If there is no system
            // prompt, the source code has changed since it was last granted, so run:
            //      tccutil reset Accessibility com.github.jonross.Lackey
            if createAndEnable(haveAccess: false) {
                // Could be it was just granted, albeit unlikely
                _state = .enabled
            } else {
                _state = .disabledPendingAccess
            }
        }
    }
    
    /// Disable the tap, but don't remove it.  Calling enable() will re-enable it.
    
    func disable() {
    }
    
    /// Ask the accessibility API if we have access.
    
    func canEnable() -> Bool {
        let promptFlag = kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString
        return AXIsProcessTrustedWithOptions([promptFlag: false] as CFDictionary)
    }
    
    /// Create the keyboard tap and enable it.  This is where all the magic happens.
    /// This is what will break when OS X is upgraded.  Or for a dozen other reasons I can't even imagine.
    
    private func createAndEnable(haveAccess: Bool) -> Bool {
        
        let mask: CGEventMask =
            1 << CGEventType.keyDown.rawValue |
            1 << CGEventType.keyUp.rawValue |
            1 << CGEventType.flagsChanged.rawValue
        
        let callback: CGEventTapCallBack = {
            (proxy: CGEventTapProxy, type: CGEventType,
             event: CGEvent, userInfo: UnsafeMutableRawPointer?) in
            
            do {
                guard let userInfo = userInfo else {
                    // Should never happen because the arg to tapCreate is never nil.
                    return Unmanaged.passUnretained(event)
                }
                
                // Split the flags into those we care about and those we don't, or we'll fail to match
                // Chords in keymaps (mainly due to CGEventFlags.maskNonCoalesced)
                let wantedFlags = event.flags.intersection(Key.allModifierFlags)
                let setAsideFlags = event.flags.symmetricDifference(wantedFlags)
                
                // TODO: autorepeat for apps that don't support it?

                let keycode = Int(event.getIntegerValueField(.keyboardEventKeycode))
                let repeated = Int(event.getIntegerValueField(.keyboardEventAutorepeat))
                let tapData = Unmanaged<TapData>.fromOpaque(userInfo).takeUnretainedValue()
                let action = try tapData.engine.handle(type: type, keycode: keycode, dupe: repeated > 0, flags: wantedFlags).0
                
                // TODO: make a way to collect key events from actions and add a true action handling method,
                // removing this switch statement.

                switch action {
                    case _ as PassKey:
                        break
                    case _ as DiscardKey:
                        return nil
                    case let send as SendKey:
                        // I tried to construct these events using CGEvent(:EventSource:CGKeyCode:Bool) but that doesn't work.
                        // Even after altering the flags in a copied event and generating a source, the flags post unchanged.
                        // Calling setSource after surgery on a copied event does work.
                        let source = CGEventSource(event: event)
                        if let newEvent = event.copy() {
                            newEvent.type = type
                            newEvent.setIntegerValueField(.keyboardEventKeycode, value: Int64(send.chord.key.code))
                            newEvent.flags = setAsideFlags.union(send.chord.flags)
                            newEvent.setSource(source)
                            newEvent.tapPostEvent(proxy)
                            return nil
                        }
                    case _ as Prompt:
                        tapData.controls.prompt()
                        Log.main.info("Done prompting")
                        return nil
                    case let app as OpenApp:
                        tapData.controls.openApp(name: app.appName)
                        return nil
                    case let cmd as DoCommand:
                        tapData.controls.doExternal(command: cmd.command)
                        return nil
                    case let resize as Resize:
                        resizeFrontmost(resize.tweaks)
                        return nil
                    case _ as NextScreen:
                        nextScreen()
                        return nil
                    default:
                        Log.keys.info("unhandled action")
                        break
                }
            }
            catch {
                Log.main.error("Internal error: \(error)")
            }
            
            return Unmanaged.passUnretained(event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            // Cannot capture engine with a closure because the callback is from C; do this instead.
            userInfo: Unmanaged.passUnretained(tapData).toOpaque()
        ) else {
            if haveAccess {
                Log.main.error("failed to tap")
            }
            return false
        }
        
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, CFRunLoopMode.commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }
}

/// This defines the bundle of information given to the tap as userInfo.

class TapData {
    let engine: Engine
    let controls: AppControl

    init(_ engine: Engine, _ controls: AppControl) {
        self.engine = engine
        self.controls = controls
    }
}


// This file is a mess.
// Most of this will get rewritten.

import Foundation
import Cocoa

class AppControl {

    private let engine: Engine
    private let statusItem: NSStatusItem

    private let popover: NSPopover
    private let alert: NSAlert
    private let textField: NSTextField
    private let delegate: NSPopoverDelegate

    init(engine: Engine, statusItem: NSStatusItem) {
        popover = NSPopover()
        alert = NSAlert()
        textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        
        self.engine = engine
        self.statusItem = statusItem
        let notificationCenter = NSWorkspace.shared.notificationCenter
        notificationCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: nil) { (notification) in
            if let user = notification.userInfo,
                let app = user[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                let name = app.localizedName {
                Log.main.info("Frontmost application changed to: \(name)")
                engine.setApp(name: name)
            }
        }

        alert.messageText = "Text Prompt"
        alert.informativeText = "Enter some text:"
        textField.placeholderString = "Text here..."
        alert.accessoryView = textField
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")

        delegate = MyPopoverDelegate(textField)
        popover.contentViewController = alert.window.contentViewController
        popover.delegate = delegate
        popover.animates = false
        // popover.show(relativeTo: <#NSRect#>, of: <#NSView#>, preferredEdge: <#NSRectEdge#>)
    }

    func openApp(name: String) {
        if let filePath = NSWorkspace.shared.fullPath(forApplication: name) {
            let url = URL(fileURLWithPath: filePath)
            do {
                try NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
            } 
            catch {
                print("Error opening application: \(error)")
            }
        } 
        else {
            print("Application not found: \(name)")
        }
    }        

    func doExternal(command: String) {
        let fm = FileManager.default
        let filePath = fm.homeDirectoryForCurrentUser.appendingPathComponent(".lackeydo").path
        /*
        do {
            let appSupportURL = try fm.url(for: .documentDirectory, in: .userDomainMask, 
                                           appropriateFor: nil, create: true)
            let fileURL = appSupportURL.appendingPathComponent("xfeed")
            var filePath = fileURL.path
            filePath = "/tmp/xfeed"
            */
            if !fm.fileExists(atPath: filePath) {
                if !fm.createFile(atPath: filePath, contents: "".data(using: .utf8)!, attributes: nil) {
                    Log.main.error("Can't create \(filePath)")
                    return
                }
            }
            if let fileHandle = FileHandle(forWritingAtPath: filePath) {
                fileHandle.seekToEndOfFile()
                if let data = (command + "\n").data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            }
            else {
                Log.main.error("Can't write to \(filePath)")
            }
        /*
        }
        catch {
            Log.main.error("Unable to write in documentDirectory: \(error)")
        }
        */
    }
    
    func prompt() {
        if let window = statusItem.button?.window {
            alert.beginSheetModal(for: window) { (response) in
                if response == .alertFirstButtonReturn {
                    // The "OK" button was pressed
                    let text = self.textField.stringValue
                    Log.main.info("got \(text)")
                    self.doExternal(command: text)
                }
                self.popover.performClose(nil)
            }
        }
    }
    
}

// This helper class allows the text field in the popover to take the cursor focus when it appears.

class MyPopoverDelegate: NSObject, NSPopoverDelegate {

    let textField: NSTextField

    init(_ textField: NSTextField) {
        self.textField = textField
    }

    func popoverDidShow(_ notification: Notification) {
        Log.main.info("popover showed")
        textField.becomeFirstResponder()
    }
}

func resizeFrontmost(_ tweaks: Tweaks) {
    if let frontmost = frontmostWindow(), let bounds = frontmost.bounds() {
        let frames = NSScreen.screens.map({ return $0.frame })
        let newBounds = tweaks.tweak(bounds, within: frames[0])
        frontmost.setBounds(newBounds)
    }
}

func nextScreen() {
    if let frontmost = frontmostWindow(), let bounds = frontmost.bounds() {
        // Get the current display frames and sort them left to right, top to bottom
        let frames = NSScreen.screens.map({ return $0.frame })
            .sorted(by: { (a, b) in return a.minY < b.minY || (a.minY == b.minY) && a.minX < b.minX })
        // let frames = ["0 0 500 400", "500 0 500 400", "0 400 500 400", "500 400 500 400"].map({ return CGRect.parse($0)! })
        // Find the one with the biggest overlap and set the target frame to the next one
        let (index, frame) = bounds.bestOverlap(frames)!
        let target = frames[index + 1 < frames.count ? index + 1 : 0]
        // Set the new origin based on the offset of the old origin within the old frame
        let nx = target.minX + target.width * ((bounds.minX - frame.minX) / frame.width)
        let ny = target.minY + target.height * ((bounds.minY - frame.minY) / frame.height)
        // Set the new bounds based on the ratio of the old bounds to its old frame
        let nw = target.width * (bounds.width / frame.width)
        let nh = target.height * (bounds.height / frame.height)
        // Create a tweak that resizes the window into the new frame
        let tweaks = Tweaks(x: Tweak.set(Amount.literal(nx)), 
                            y: Tweak.set(Amount.literal(ny)),
                            width: Tweak.set(Amount.literal(nw)),
                            height: Tweak.set(Amount.literal(nh)))
        let newBounds = tweaks.tweak(bounds, within: target)
        frontmost.setBounds(newBounds)
    }
}


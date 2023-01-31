//
//  AppDelegate.swift
//  Lackeys
//
//  Created by jon.ross on 1/25/23.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var window: NSWindow!
    @IBOutlet weak var menu: NSMenu!
    private var statusItem : NSStatusItem!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        initStatusBar()
        updateStatusBar()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }
    
    /// Called during initialization to set up the status bar.

    private func initStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: -1)
        statusItem.menu = self.menu
        statusItem.highlightMode = true
    }

    /// Called whenever there is a state change that requires changing the status bar.
    
    private func updateStatusBar() {
        statusItem.button?.title = "M?"
        /*
        switch keyTap.state {
            case .manuallyDisabled:
                statusItem.button?.title = "L-"
            case .disabledPendingAccess:
                statusItem.button?.title = "L?"
            case .disabledDueToError:
                statusItem.button?.title = "L!"
            case .enabled:
                statusItem.button?.title = "L+"
        }
        */
    }
    
   @IBAction func enableFromMenu(_ sender: Any) {
        print("enabled")
        updateStatusBar()
    }
    
    @IBAction func disableFromMenu(_ sender: Any) {
        print("disabled")
        updateStatusBar()
    }
    
    @IBAction func quitFromMenu(_ sender: Any) {
        NSApplication.shared.terminate(nil)
    }
}


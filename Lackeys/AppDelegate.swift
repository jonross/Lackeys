/// Contains only enough code to initialize the app and handle UI events.

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var window: NSWindow?
    @IBOutlet weak var menu: NSMenu!
    private var statusItem : NSStatusItem!
    
    private var keyTap: KeyTap!
    private var appControl: AppControl!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        initStatusBar()
        Key.setup()
        let engine = Engine()
        let c = Config(forEngine: engine)
        c.readAndApply()
        // TODO: surface configuration errors
        for error in c.errors {
            Log.main.error(error)
        }
        appControl = AppControl(engine: engine, statusItem: statusItem)
        keyTap = KeyTap(engine: engine, controls: appControl)
        keyTap.enable()
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
    }
    
    /// Called from the "Enable" menu item.  Why manually?  After reading about issues with
    /// background timers, I want the table enabled on the main thread.
    
   @IBAction func enableFromMenu(_ sender: Any) {
        keyTap.enable()
        updateStatusBar()
    }
    
    /// Called from the "Disable" menu item; disable the tap and update status.
    
    @IBAction func disableFromMenu(_ sender: Any) {
        keyTap.disable()
        updateStatusBar()
    }
    
    /// Called from the "Quit" menu item.
    
    @IBAction func quitFromMenu(_ sender: Any) {
        NSApplication.shared.terminate(nil)
    }
}


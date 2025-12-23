import Cocoa
import UserNotifications

protocol BundleInfoProviding {
    var bundleIdentifier: String? { get }
    var bundleURL: URL { get }
}

extension Bundle: BundleInfoProviding {}

@main
class PetApp: NSApplication {
    static func main() {
        _ = PetApp.shared
        _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
    }
    
    private var windowController: PetWindowController?
    private var menuBarController: MenuBarController?
    private var preferencesController: PreferencesWindowController?
    private let settingsManager = SettingsManager.shared
    
    override func finishLaunching() {
        super.finishLaunching()
        
        requestNotificationPermissionsIfNeeded()
        
        // Create and show the pet window
        windowController = PetWindowController(settingsManager: settingsManager)
        windowController?.showWindow(nil)
        
        // Initialize all services and integrate
        windowController?.initializeServices()
        
        // Preferences
        preferencesController = PreferencesWindowController(settingsManager: settingsManager)
        
        // Menu bar
        if let windowController = windowController {
            menuBarController = MenuBarController(
                windowController: windowController,
                settingsManager: settingsManager,
                preferencesHandler: { [weak self] in
                    self?.preferencesController?.show()
                }
            )
        }
    }
    
    static func isRunningFromAppBundle(bundle: BundleInfoProviding = Bundle.main) -> Bool {
        guard bundle.bundleURL.pathExtension == "app" else { return false }
        guard let identifier = bundle.bundleIdentifier, !identifier.isEmpty else { return false }
        return true
    }
    
    private func requestNotificationPermissionsIfNeeded(bundle: BundleInfoProviding = Bundle.main) {
        guard Self.isRunningFromAppBundle(bundle: bundle) else {
            NSLog("Skipping notification permission request because app is not running from a bundled .app (bundleURL: \(bundle.bundleURL))")
            return
        }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
}

import Cocoa
import SwiftUI

final class PreferencesWindowController: NSWindowController {
    private let viewModel: SettingsViewModel
    
    init(settingsManager: SettingsManager) {
        self.viewModel = SettingsViewModel(settingsManager: settingsManager)
        
        let hosting = NSHostingController(rootView: PreferencesView(viewModel: viewModel))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 480),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Preferences"
        window.contentViewController = hosting
        window.center()
        
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

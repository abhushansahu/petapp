import Cocoa

final class MenuBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private weak var windowController: PetWindowController?
    private let settingsManager: SettingsManager
    private var preferencesHandler: (() -> Void)?
    
    init(windowController: PetWindowController, settingsManager: SettingsManager, preferencesHandler: (() -> Void)?) {
        self.windowController = windowController
        self.settingsManager = settingsManager
        self.preferencesHandler = preferencesHandler
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configureStatusItem()
    }
    
    private func configureStatusItem() {
        if let button = statusItem.button {
            button.title = "🐾"
            button.toolTip = "Tamagotchi"
        }
        statusItem.menu = buildMenu()
    }
    
    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        
        menu.addItem(makeTitleItem())
        menu.addItem(.separator())
        menu.addItem(makeStatusItem())
        menu.addItem(makeHealthItem())
        menu.addItem(makeHappinessItem())
        menu.addItem(.separator())
        menu.addItem(makePersonalityItem())
        menu.addItem(.separator())
        menu.addItem(makeMemoryItem())
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Feed", action: #selector(feed), keyEquivalent: "f"))
        menu.addItem(NSMenuItem(title: "Play", action: #selector(play), keyEquivalent: "p"))
        menu.addItem(NSMenuItem(title: "Sleep", action: #selector(sleep), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Wake Up", action: #selector(wake), keyEquivalent: "w"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Show Pet", action: #selector(showPet), keyEquivalent: "0"))
        menu.addItem(NSMenuItem(title: "Preferences…", action: #selector(openPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        
        menu.items.forEach { $0.target = self }
        return menu
    }
    
    // MARK: - Menu Delegate
    func menuWillOpen(_ menu: NSMenu) {
        refreshDynamicItems(menu)
    }
    
    private func refreshDynamicItems(_ menu: NSMenu) {
        guard let pet = windowController?.getPetEntity() else { return }
        
        menu.item(at: 0)?.title = "\(settingsManager.settings.petName)"
        menu.item(at: 2)?.title = "Status: \(pet.state.displayName)"
        menu.item(at: 3)?.title = "Health: \(percent(pet.health)) \(barString(pet.health))"
        menu.item(at: 4)?.title = "Happiness: \(percent(pet.happiness)) \(barString(pet.happiness))"
        menu.item(at: 6)?.title = makePersonalityDisplay(pet.personality)
        menu.item(at: 8)?.title = makeMemoryDisplay()
    }
    
    // MARK: - Menu Items
    private func makeTitleItem() -> NSMenuItem {
        let item = NSMenuItem()
        item.title = settingsManager.settings.petName
        item.isEnabled = false
        return item
    }
    
    private func makeStatusItem() -> NSMenuItem {
        let item = NSMenuItem()
        item.title = "Status: Idle"
        item.isEnabled = false
        return item
    }
    
    private func makeHealthItem() -> NSMenuItem {
        let item = NSMenuItem()
        item.title = "Health: 100%"
        item.isEnabled = false
        return item
    }
    
    private func makeHappinessItem() -> NSMenuItem {
        let item = NSMenuItem()
        item.title = "Happiness: 100%"
        item.isEnabled = false
        return item
    }
    
    // MARK: - Actions
    @objc private func feed() {
        windowController?.getPetEntity().setState(.eating)
    }
    
    @objc private func play() {
        windowController?.getPetEntity().setState(.playing)
    }
    
    @objc private func sleep() {
        windowController?.getPetEntity().setState(.sleeping)
    }
    
    @objc private func wake() {
        windowController?.getPetEntity().setState(.idle)
    }
    
    @objc private func showPet() {
        windowController?.showWindow(nil)
        windowController?.window?.orderFrontRegardless()
    }
    
    @objc private func openPreferences() {
        preferencesHandler?()
    }
    
    @objc private func quit() {
        NSApp.terminate(nil)
    }
    
    // MARK: - Helpers
    private func percent(_ value: Double) -> String {
        let clamped = max(0.0, min(1.0, value))
        let pct = Int((clamped * 100).rounded())
        return "\(pct)%"
    }
    
    private func barString(_ value: Double) -> String {
        let clamped = max(0.0, min(1.0, value))
        let filled = Int(clamped * 10)
        let empty = 10 - filled
        return String(repeating: "█", count: filled) + String(repeating: "░", count: empty)
    }
    
    private func makePersonalityDisplay(_ personality: PetPersonality) -> String {
        let traits = [
            ("Play", personality.playfulness),
            ("Curious", personality.curiosity),
            ("Sleepy", personality.sleepiness),
            ("Social", personality.sociability),
            ("Energy", personality.energy)
        ]
        return traits.map { "\($0.0): \(Int($0.1 * 100))%" }.joined(separator: " | ")
    }
    
    private func makeMemoryDisplay() -> String {
        let memoryManager = MemoryManager.shared
        let interactions = memoryManager.getInteractionMemories().count
        let locations = memoryManager.getFavoriteLocations().count
        let patterns = memoryManager.getTimePatterns(for: "playing").count + 
                      memoryManager.getTimePatterns(for: "resting").count
        
        if interactions + locations + patterns == 0 {
            return "Memories: None yet"
        }
        
        return "Memories: \(interactions) interactions, \(locations) locations, \(patterns) patterns"
    }
    
    private func makePersonalityItem() -> NSMenuItem {
        let item = NSMenuItem()
        item.title = "Personality: Loading..."
        item.isEnabled = false
        return item
    }
    
    private func makeMemoryItem() -> NSMenuItem {
        let item = NSMenuItem()
        item.title = "Memories: Loading..."
        item.isEnabled = false
        return item
    }
}

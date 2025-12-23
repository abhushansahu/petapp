import Cocoa
import Combine

class AppMonitor {
    private var workspace: NSWorkspace
    private var notificationObservers: [NSObjectProtocol] = []
    private var currentApp: NSRunningApplication?
    private var focusApps: Set<String> = []
    
    @Published var isFocusing: Bool = false
    @Published var currentAppName: String = ""
    
    var onFocusStateChanged: ((Bool) -> Void)?
    var onActiveAppChanged: ((String) -> Void)?
    
    init() {
        self.workspace = NSWorkspace.shared
        
        // Default focus apps (common productivity apps)
        focusApps = [
            "Xcode",
            "Code",
            "Visual Studio Code",
            "Sublime Text",
            "TextEdit",
            "Pages",
            "Numbers",
            "Keynote",
            "Microsoft Word",
            "Microsoft Excel",
            "Microsoft PowerPoint",
            "Google Chrome",
            "Safari",
            "Firefox",
            "Slack",
            "Discord",
            "Terminal",
            "iTerm2"
        ]
        
        setupObservers()
        updateCurrentApp()
    }
    
    private func setupObservers() {
        // Observe app activation
        let activationObserver = NotificationCenter.default.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAppActivation(notification)
        }
        notificationObservers.append(activationObserver)
        
        // Observe app launch
        let launchObserver = NotificationCenter.default.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAppActivation(notification)
        }
        notificationObservers.append(launchObserver)
        
        // Observe app termination
        let terminateObserver = NotificationCenter.default.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateCurrentApp()
        }
        notificationObservers.append(terminateObserver)
    }
    
    private func handleAppActivation(_ notification: Notification) {
        updateCurrentApp()
    }
    
    private func updateCurrentApp() {
        let activeApp = workspace.frontmostApplication
        currentApp = activeApp
        
        if let app = activeApp, let bundleId = app.bundleIdentifier {
            let appName = app.localizedName ?? bundleId
            currentAppName = appName
            
            // Check if it's a focus app
            let isFocusApp = focusApps.contains(appName) || 
                           bundleId.contains("com.apple.dt.Xcode") ||
                           bundleId.contains("com.microsoft.VSCode") ||
                           bundleId.contains("com.sublimetext") ||
                           bundleId.contains("com.google.Chrome") ||
                           bundleId.contains("com.apple.Safari") ||
                           bundleId.contains("com.mozilla.firefox")
            
            let wasFocusing = isFocusing
            isFocusing = isFocusApp
            
            if wasFocusing != isFocusing {
                onFocusStateChanged?(isFocusing)
            }
            
            // Notify app change
            onActiveAppChanged?(appName)
        } else {
            currentAppName = ""
            let wasFocusing = isFocusing
            isFocusing = false
            
            if wasFocusing != isFocusing {
                onFocusStateChanged?(isFocusing)
            }
        }
    }
    
    // MARK: - Focus App Management
    func addFocusApp(_ appName: String) {
        focusApps.insert(appName)
        updateCurrentApp()
    }
    
    func removeFocusApp(_ appName: String) {
        focusApps.remove(appName)
        updateCurrentApp()
    }
    
    func getFocusApps() -> Set<String> {
        return focusApps
    }
    
    func setFocusApps(_ apps: Set<String>) {
        focusApps = apps
        updateCurrentApp()
    }
    
    // MARK: - Video App Detection
    func isVideoApp() -> Bool {
        guard let app = currentApp,
              let bundleId = app.bundleIdentifier else {
            return false
        }
        
        let videoApps = [
            "com.apple.QuickTimePlayerX",
            "com.apple.QuickTimePlayer",
            "com.videolan.vlc",
            "com.spotify.client",
            "com.apple.Music",
            "com.google.YouTube",
            "com.netflix.Netflix",
            "com.hulu.plus",
            "com.amazon.aiv.AIVApp",
            "com.apple.TV",
            "com.plexapp.plexmediaserver",
            "com.plex.desktop"
        ]
        
        return videoApps.contains(bundleId) || 
               bundleId.contains("youtube") ||
               bundleId.contains("netflix") ||
               bundleId.contains("video")
    }
    
    func getCurrentWindow() -> [String: Any]? {
        // Try to get information about the current window
        // Note: This requires Accessibility permissions for full functionality
        // For now, we'll use app-level detection
        return nil
    }
    
    deinit {
        notificationObservers.forEach {
            NotificationCenter.default.removeObserver($0)
        }
    }
}

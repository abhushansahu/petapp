import Cocoa
import QuartzCore

enum WindowMode {
    case alwaysOnTop
    case clickThrough
    case desktopLevel
}

class PetWindowController: NSWindowController {
    private var petEntity: PetEntity
    private var petView: PetView?
    private var currentMode: WindowMode = .desktopLevel
    private var movementTimer: Timer?
    private var targetScreen: NSScreen?
    private var velocity: CGVector = .zero
    private let settingsManager: SettingsManager
    
    // Services
    private var appMonitor: AppMonitor?
    private var audioAnalyzer: AudioAnalyzer?
    private var reminderManager: ReminderManager?
    private var activityManager: ActivityManager?
    private var interactionHandler: InteractionHandler?
    private var videoDetection: VideoDetection?
    private let memoryManager = MemoryManager.shared
    
    // Window configuration
    private var petSize: CGFloat
    private let walkSpeed: CGFloat = 3.0
    private let runSpeed: CGFloat = 6.0
    private let velocityDamping: CGFloat = 0.86
    
    init(settingsManager: SettingsManager = .shared) {
        self.settingsManager = settingsManager
        self.petSize = CGFloat(settingsManager.settings.validated().petSize)
        
        // Initialize pet with personality from settings
        let personality = PetPersonality(
            playfulness: settingsManager.settings.personality.playfulness,
            curiosity: settingsManager.settings.personality.curiosity,
            sleepiness: settingsManager.settings.personality.sleepiness,
            sociability: settingsManager.settings.personality.sociability,
            energy: settingsManager.settings.personality.energy
        )
        self.petEntity = PetEntity(personality: personality)
        
        // Create window
        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: petSize, height: petSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .desktopIcon
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.ignoresMouseEvents = false
        
        super.init(window: window)
        
        setupPetView()
        setupWindowMode(.desktopLevel)
        setupMovement()
        setupSettingsObserver()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        // Center on primary screen initially
        if let screen = NSScreen.main ?? NSScreen.screens.first {
            centerOnScreen(screen)
        }
    }
    
    private func setupPetView() {
        guard let window = window else { return }
        
        let viewFrame = NSRect(origin: .zero, size: window.frame.size)
        let view = PetView(petEntity: petEntity, frame: viewFrame)
        view.autoresizingMask = [.width, .height]
        
        window.contentView = view
        petView = view
    }
    
    // MARK: - Window Mode Management
    func setupWindowMode(_ mode: WindowMode) {
        currentMode = mode
        guard let window = window else { return }
        
        switch mode {
        case .alwaysOnTop:
            window.level = .floating
            window.ignoresMouseEvents = false
            window.collectionBehavior = [.canJoinAllSpaces, .stationary]
            
        case .clickThrough:
            window.level = .floating
            window.ignoresMouseEvents = true
            window.collectionBehavior = [.canJoinAllSpaces, .stationary]
            
        case .desktopLevel:
            window.level = .desktopIcon
            window.ignoresMouseEvents = false
            window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        }
    }
    
    func switchMode(_ mode: WindowMode) {
        setupWindowMode(mode)
    }
    
    // MARK: - Multi-Screen Support
    func centerOnScreen(_ screen: NSScreen) {
        guard let window = window else { return }
        
        let screenFrame = screen.frame
        let windowSize = window.frame.size
        let centerX = screenFrame.midX - windowSize.width / 2
        let centerY = screenFrame.midY - windowSize.height / 2
        
        window.setFrameOrigin(NSPoint(x: centerX, y: centerY))
        targetScreen = screen
    }
    
    func moveToScreen(_ screen: NSScreen, animated: Bool = true) {
        guard let window = window else { return }
        
        if animated {
            let screenFrame = screen.frame
            let windowSize = window.frame.size
            let targetX = screenFrame.midX - windowSize.width / 2
            let targetY = screenFrame.midY - windowSize.height / 2
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.5
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                window.animator().setFrameOrigin(NSPoint(x: targetX, y: targetY))
            } completionHandler: {
                self.targetScreen = screen
            }
        } else {
            centerOnScreen(screen)
        }
    }
    
    func getCurrentScreen() -> NSScreen? {
        guard let window = window else { return nil }
        
        let windowFrame = window.frame
        let windowCenter = NSPoint(
            x: windowFrame.midX,
            y: windowFrame.midY
        )
        
        // Find screen containing window center
        for screen in NSScreen.screens {
            if screen.frame.contains(windowCenter) {
                return screen
            }
        }
        
        return NSScreen.main
    }
    
    func moveToRandomScreen() {
        let screens = NSScreen.screens
        guard screens.count > 1 else { return }
        
        let currentScreen = getCurrentScreen()
        let otherScreens = screens.filter { $0 != currentScreen }
        
        if let randomScreen = otherScreens.randomElement() {
            moveToScreen(randomScreen, animated: true)
        }
    }
    
    // MARK: - Window Movement
    private func setupMovement() {
        // Periodic movement for walking state - optimized frequency
        // Use display link for smoother, power-efficient updates
        movementTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            self?.updatePosition()
        }
        movementTimer?.tolerance = 0.05 // Allow timer coalescing for power efficiency
    }
    
    private func updatePosition() {
        guard let window = window,
              let screen = getCurrentScreen() else { return }
        
        let state = petEntity.state
        let screenFrame = screen.visibleFrame
        let windowSize = window.frame.size
        var origin = window.frame.origin
        
        switch state {
        case .walking, .running:
            // Semi-directed walk/run with bounded speed
            let jitterRange: ClosedRange<CGFloat> = state == .running ? -1.5...1.5 : -1.0...1.0
            let maxSpeed = state == .running ? runSpeed : walkSpeed
            
            velocity.dx += CGFloat.random(in: jitterRange)
            velocity.dy += CGFloat.random(in: jitterRange)
            velocity = limitedVelocity(velocity, maxSpeed: maxSpeed)
            
            origin.x += velocity.dx
            origin.y += velocity.dy
            
            // Check if pet should move to another screen (multi-screen support)
            checkAndMoveToOtherScreen()
            
        case .dancing, .playing:
            // Slight jitter during playful states
            origin.x += CGFloat.random(in: -1...1)
            origin.y += CGFloat.random(in: -1...1)
            velocity = dampVelocity(velocity)
            
        case .eating:
            // Minor bob while eating, no drift
            origin.y += CGFloat.random(in: -0.4...0.4)
            velocity = dampVelocity(velocity)
            
        case .dragging:
            // No movement from timer while user drags; damp to zero
            velocity = dampVelocity(.zero)
            
        case .dropped:
            // Small settle after drop
            origin.y += CGFloat.random(in: -0.5...0.5)
            velocity = dampVelocity(velocity)
            
        case .idle, .sitting, .watching, .sleeping:
            velocity = dampVelocity(velocity)
        }
        
        // Clamp to visible screen and bounce lightly on edges
        let clamped = clampedOrigin(for: origin, size: windowSize, within: screenFrame, velocity: velocity, invertingVelocityOnHit: true)
        window.setFrameOrigin(clamped.origin)
        velocity = clamped.velocity
        
        // Record location memory periodically (every 30 seconds)
        let now = Date()
        if let lastLocationRecord = lastLocationRecordTime {
            if now.timeIntervalSince(lastLocationRecord) >= 30.0 {
                recordLocationMemory(screen: screen, position: clamped.origin)
                lastLocationRecordTime = now
            }
        } else {
            recordLocationMemory(screen: screen, position: clamped.origin)
            lastLocationRecordTime = now
        }
    }
    
    private var lastScreenSwitchTime: Date?
    private let minScreenSwitchInterval: TimeInterval = 30.0 // Minimum 30 seconds between screen switches
    
    private func checkAndMoveToOtherScreen() {
        let screens = NSScreen.screens
        guard screens.count > 1 else { return }
        
        // Don't switch too frequently
        let now = Date()
        if let lastSwitch = lastScreenSwitchTime {
            guard now.timeIntervalSince(lastSwitch) >= minScreenSwitchInterval else { return }
        }
        
        guard let currentScreen = getCurrentScreen(),
              let window = window else { return }
        
        let windowFrame = window.frame
        let screenFrame = currentScreen.visibleFrame
        
        // Check if pet is near edge of screen (within 50 pixels)
        let edgeThreshold: CGFloat = 50.0
        let nearLeftEdge = windowFrame.minX <= screenFrame.minX + edgeThreshold
        let nearRightEdge = windowFrame.maxX >= screenFrame.maxX - edgeThreshold
        let nearTopEdge = windowFrame.maxY >= screenFrame.maxY - edgeThreshold
        let nearBottomEdge = windowFrame.minY <= screenFrame.minY + edgeThreshold
        
        // If near edge and moving in that direction, consider switching screens
        if (nearRightEdge && velocity.dx > 0) || (nearLeftEdge && velocity.dx < 0) ||
           (nearTopEdge && velocity.dy > 0) || (nearBottomEdge && velocity.dy < 0) {
            
            // Random chance to switch (30% when near edge)
            if Double.random(in: 0...1) < 0.3 {
                let otherScreens = screens.filter { $0 != currentScreen }
                if let randomScreen = otherScreens.randomElement() {
                    moveToScreen(randomScreen, animated: true)
                    lastScreenSwitchTime = now
                }
            }
        }
    }
    
    private var lastLocationRecordTime: Date?
    
    private func recordLocationMemory(screen: NSScreen, position: CGPoint) {
        let screenIndex = NSScreen.screens.firstIndex(of: screen) ?? 0
        memoryManager.recordLocation(screenIndex: screenIndex, position: position)
    }

    func clampedOrigin(for origin: NSPoint, size: CGSize, within frame: NSRect, velocity: CGVector, invertingVelocityOnHit: Bool = false) -> (origin: NSPoint, velocity: CGVector) {
        var newOrigin = origin
        var newVelocity = velocity
        
        if origin.x < frame.minX {
            newOrigin.x = frame.minX
            if invertingVelocityOnHit { newVelocity.dx = abs(newVelocity.dx) * 0.6 }
        } else if origin.x > frame.maxX - size.width {
            newOrigin.x = frame.maxX - size.width
            if invertingVelocityOnHit { newVelocity.dx = -abs(newVelocity.dx) * 0.6 }
        }
        
        if origin.y < frame.minY {
            newOrigin.y = frame.minY
            if invertingVelocityOnHit { newVelocity.dy = abs(newVelocity.dy) * 0.6 }
        } else if origin.y > frame.maxY - size.height {
            newOrigin.y = frame.maxY - size.height
            if invertingVelocityOnHit { newVelocity.dy = -abs(newVelocity.dy) * 0.6 }
        }
        
        return (newOrigin, newVelocity)
    }
    
    func limitedVelocity(_ velocity: CGVector, maxSpeed: CGFloat) -> CGVector {
        let magnitude = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
        guard magnitude > maxSpeed, magnitude > 0 else { return velocity }
        let scale = maxSpeed / magnitude
        return CGVector(dx: velocity.dx * scale, dy: velocity.dy * scale)
    }
    
    private func dampVelocity(_ velocity: CGVector) -> CGVector {
        var damped = CGVector(dx: velocity.dx * velocityDamping, dy: velocity.dy * velocityDamping)
        if abs(damped.dx) < 0.05 { damped.dx = 0 }
        if abs(damped.dy) < 0.05 { damped.dy = 0 }
        return damped
    }
    
    // MARK: - Window Sitting
    func sitOnWindow(_ targetWindow: NSWindow) {
        guard let window = window else { return }
        
        let targetFrame = targetWindow.frame
        let windowSize = window.frame.size
        
        // Position pet on top of target window
        let sitX = targetFrame.midX - windowSize.width / 2
        let sitY = targetFrame.maxY - windowSize.height - 10
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            window.animator().setFrameOrigin(NSPoint(x: sitX, y: sitY))
        }
        
        // Switch to sitting state
        petEntity.setState(.sitting)
    }
    
    // MARK: - Service Integration
    func initializeServices() {
        // Initialize App Monitor
        appMonitor = AppMonitor()
        appMonitor?.onFocusStateChanged = { [weak self] isFocusing in
            if isFocusing {
                self?.petEntity.setState(.sitting)
            } else if self?.petEntity.state == .sitting {
                self?.petEntity.setState(.idle)
            }
        }
        appMonitor?.onActiveAppChanged = { [weak self] appName in
            // Record app preference - positive if pet sits (focus mode), neutral otherwise
            let preference: Double = self?.petEntity.state == .sitting ? 0.3 : 0.0
            MemoryManager.shared.recordAppPreference(appName: appName, preference: preference)
        }
        if let apps = appMonitor {
            apps.setFocusApps(Set(settingsManager.settings.focusApps))
        }
        
        // Initialize Audio Analyzer
        audioAnalyzer = AudioAnalyzer()
        audioAnalyzer?.onMusicDetected = { [weak self] isMusicDetected in
            if isMusicDetected {
                self?.petEntity.setState(.dancing)
            } else if self?.petEntity.state == .dancing {
                self?.petEntity.setState(.idle)
            }
        }
        audioAnalyzer?.onBeatDetected = { [weak self] intensity in
            if self?.petEntity.state == .dancing {
                self?.petView?.updateDanceIntensity(intensity)
            }
        }
        audioAnalyzer?.startAnalysis()
        
        // Initialize Reminder Manager
        reminderManager = ReminderManager()
        reminderManager?.setPetEntity(petEntity)
        reminderManager?.onReminderTriggered = { reminder in
            // Pet animation is handled in ReminderManager
            print("Reminder triggered: \(reminder.id)")
        }
        
        // Initialize Activity Manager
        activityManager = ActivityManager(petEntity: petEntity)
        activityManager?.onActivityTriggered = { activity in
            print("Activity triggered: \(activity)")
        }
        
        // Initialize Interaction Handler
        interactionHandler = InteractionHandler(windowController: self)
        interactionHandler?.setProximityThreshold(CGFloat(settingsManager.settings.interactionProximity))
        interactionHandler?.onInteractionTriggered = { mode in
            print("Interaction: \(mode)")
        }
        
        // Initialize Video Detection
        if let appMonitor = appMonitor {
            videoDetection = VideoDetection(appMonitor: appMonitor, windowController: self)
            videoDetection?.onVideoDetected = { [weak self] isWatching in
                if isWatching {
                    self?.petEntity.setState(.watching)
                } else if self?.petEntity.state == .watching {
                    self?.petEntity.setState(.idle)
                }
            }
        }
    }
    
    // MARK: - Public Access
    func getPetEntity() -> PetEntity {
        return petEntity
    }
    
    func getPetView() -> PetView? {
        return petView
    }
    
    func getAppMonitor() -> AppMonitor? {
        return appMonitor
    }
    
    func getAudioAnalyzer() -> AudioAnalyzer? {
        return audioAnalyzer
    }
    
    func getReminderManager() -> ReminderManager? {
        return reminderManager
    }
    
    func getActivityManager() -> ActivityManager? {
        return activityManager
    }
    
    func getInteractionHandler() -> InteractionHandler? {
        return interactionHandler
    }
    
    func getVideoDetection() -> VideoDetection? {
        return videoDetection
    }
    
    // MARK: - Settings Observer
    private func setupSettingsObserver() {
        NotificationCenter.default.addObserver(
            forName: SettingsManager.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleSettingsChange()
        }
    }
    
    private func handleSettingsChange() {
        let settings = settingsManager.settings
        
        // Update pet personality when settings change
        let newPersonality = PetPersonality(
            playfulness: settings.personality.playfulness,
            curiosity: settings.personality.curiosity,
            sleepiness: settings.personality.sleepiness,
            sociability: settings.personality.sociability,
            energy: settings.personality.energy
        )
        petEntity.updatePersonality(newPersonality)
        
        // Update activity manager frequency if it exists
        if let activityMgr = activityManager {
            activityMgr.updateActivityFrequency(minutes: settings.behavior.activityFrequencyMinutes)
        }
        
        // Update interaction proximity
        interactionHandler?.setProximityThreshold(CGFloat(settings.interactionProximity))
        
        // Update pet size if changed
        let newSize = CGFloat(settings.petSize)
        if abs(newSize - petSize) > 1.0 {
            petSize = newSize
            if let window = window {
                let currentOrigin = window.frame.origin
                window.setFrame(NSRect(origin: currentOrigin, size: CGSize(width: petSize, height: petSize)), display: true)
            }
        }
        
        // Update focus apps
        appMonitor?.setFocusApps(Set(settings.focusApps))
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        movementTimer?.invalidate()
        audioAnalyzer?.stopAnalysis()
    }
}


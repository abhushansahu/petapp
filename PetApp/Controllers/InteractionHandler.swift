import Cocoa
import Combine

enum InteractionMode {
    case follow
    case avoid
    case chase
    case hide
    case none
}

class InteractionHandler {
    private var windowController: PetWindowController
    private var petView: PetView?
    private var mouseTrackingTimer: Timer?
    private var lastMousePosition: NSPoint = .zero
    private var interactionMode: InteractionMode = .none
    private var proximityThreshold: CGFloat = 100.0
    
    var onInteractionTriggered: ((InteractionMode) -> Void)?
    
    init(windowController: PetWindowController) {
        self.windowController = windowController
        self.petView = windowController.getPetView()
        
        setupMouseTracking()
    }
    
    private func setupMouseTracking() {
        // Track mouse position periodically - optimized frequency
        mouseTrackingTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.updateMouseTracking()
            self?.checkForWindowToSitOn()
        }
    }
    
    private func updateMouseTracking() {
        guard let window = windowController.window else { return }
        
        let mouseLocation = NSEvent.mouseLocation
        lastMousePosition = mouseLocation
        
        // Convert to window coordinates
        let windowFrame = window.frame
        let windowCenter = NSPoint(
            x: windowFrame.midX,
            y: windowFrame.midY
        )
        
        let distance = sqrt(
            pow(mouseLocation.x - windowCenter.x, 2) +
            pow(mouseLocation.y - windowCenter.y, 2)
        )
        
        // Check proximity
        if distance < proximityThreshold {
            handleProximityInteraction(distance: distance, mouseLocation: mouseLocation, windowCenter: windowCenter)
        } else {
            // Reset interaction mode if far away
            if interactionMode != .none {
                interactionMode = .none
            }
        }
    }
    
    private func handleProximityInteraction(distance: CGFloat, mouseLocation: NSPoint, windowCenter: NSPoint) {
        let petEntity = windowController.getPetEntity()
        let state = petEntity.state
        
        // Don't interact during certain states
        guard state != .sleeping && state != .dancing && state != .watching else {
            return
        }
        
        // Determine interaction mode based on distance and randomness
        let normalizedDistance = distance / proximityThreshold
        let randomFactor = Double.random(in: 0...1)
        
        if normalizedDistance < 0.3 {
            // Very close - playful interaction
            if randomFactor < 0.5 {
                interactionMode = .chase
                chaseCursor(mouseLocation: mouseLocation, windowCenter: windowCenter)
            } else {
                interactionMode = .hide
                avoidCursor(mouseLocation: mouseLocation, windowCenter: windowCenter)
            }
        } else if normalizedDistance < 0.6 {
            // Medium distance - follow or avoid
            if randomFactor < 0.6 {
                interactionMode = .follow
                followCursor(mouseLocation: mouseLocation, windowCenter: windowCenter)
            } else {
                interactionMode = .avoid
                avoidCursor(mouseLocation: mouseLocation, windowCenter: windowCenter)
            }
        } else {
            // Far but within threshold - gentle follow
            interactionMode = .follow
            followCursor(mouseLocation: mouseLocation, windowCenter: windowCenter, intensity: 0.3)
        }
        
        onInteractionTriggered?(interactionMode)
        
        // Record interaction memory
        let interactionType: String
        switch interactionMode {
        case .follow: interactionType = "follow"
        case .avoid: interactionType = "avoid"
        case .chase: interactionType = "chase"
        case .hide: interactionType = "hide"
        case .none: return
        }
        MemoryManager.shared.recordInteraction(type: interactionType, location: mouseLocation)
    }
    
    private func followCursor(mouseLocation: NSPoint, windowCenter: NSPoint, intensity: CGFloat = 1.0) {
        guard let window = windowController.window,
              let screen = windowController.getCurrentScreen() else { return }
        
        let screenFrame = screen.visibleFrame
        let windowSize = window.frame.size
        
        // Calculate direction to mouse
        let dx = (mouseLocation.x - windowCenter.x) * intensity * 0.5
        let dy = (mouseLocation.y - windowCenter.y) * intensity * 0.5
        
        let newX = window.frame.origin.x + dx
        let newY = window.frame.origin.y + dy
        
        // Clamp to screen bounds
        let clampedX = max(screenFrame.minX, min(screenFrame.maxX - windowSize.width, newX))
        let clampedY = max(screenFrame.minY, min(screenFrame.maxY - windowSize.height, newY))
        
        window.setFrameOrigin(NSPoint(x: clampedX, y: clampedY))
        
        // Set state to walking if not already
        let petEntity = windowController.getPetEntity()
        if petEntity.state == .idle {
            petEntity.setState(.walking)
        }
    }
    
    private func avoidCursor(mouseLocation: NSPoint, windowCenter: NSPoint) {
        guard let window = windowController.window,
              let screen = windowController.getCurrentScreen() else { return }
        
        let screenFrame = screen.visibleFrame
        let windowSize = window.frame.size
        
        // Calculate direction away from mouse
        let dx = windowCenter.x - mouseLocation.x
        let dy = windowCenter.y - mouseLocation.y
        let distance = sqrt(dx * dx + dy * dy)
        
        guard distance > 0 else { return }
        
        // Normalize and move away
        let normalizedDx = dx / distance
        let normalizedDy = dy / distance
        
        let moveDistance: CGFloat = 5.0
        let newX = window.frame.origin.x + normalizedDx * moveDistance
        let newY = window.frame.origin.y + normalizedDy * moveDistance
        
        // Clamp to screen bounds
        let clampedX = max(screenFrame.minX, min(screenFrame.maxX - windowSize.width, newX))
        let clampedY = max(screenFrame.minY, min(screenFrame.maxY - windowSize.height, newY))
        
        window.setFrameOrigin(NSPoint(x: clampedX, y: clampedY))
        
        // Set state to walking
        let petEntity = windowController.getPetEntity()
        petEntity.setState(.walking)
    }
    
    private func chaseCursor(mouseLocation: NSPoint, windowCenter: NSPoint) {
        guard let window = windowController.window,
              let screen = windowController.getCurrentScreen() else { return }
        
        let screenFrame = screen.visibleFrame
        let windowSize = window.frame.size
        
        // Move more aggressively towards cursor
        let dx = (mouseLocation.x - windowCenter.x) * 0.8
        let dy = (mouseLocation.y - windowCenter.y) * 0.8
        
        let newX = window.frame.origin.x + dx
        let newY = window.frame.origin.y + dy
        
        // Clamp to screen bounds
        let clampedX = max(screenFrame.minX, min(screenFrame.maxX - windowSize.width, newX))
        let clampedY = max(screenFrame.minY, min(screenFrame.maxY - windowSize.height, newY))
        
        window.setFrameOrigin(NSPoint(x: clampedX, y: clampedY))
        
        // Set state to walking
        let petEntity = windowController.getPetEntity()
        petEntity.setState(.walking)
        petEntity.adjustHappiness(0.05) // Playing makes pet happy
    }
    
    // MARK: - Window Sitting
    func sitOnWindow(_ targetWindow: NSWindow) {
        windowController.sitOnWindow(targetWindow)
    }
    
    func findWindowsToSitOn() -> [NSWindow] {
        // Try to find windows using NSApplication
        // Note: This only finds windows from our app and some system windows
        // Full window detection requires Accessibility API permissions
        let windows: [NSWindow] = []
        
        // Get windows from all running applications
        let runningApps = NSWorkspace.shared.runningApplications
        
        for app in runningApps {
            // Skip our own app to avoid sitting on our own window
            if app.bundleIdentifier == Bundle.main.bundleIdentifier {
                continue
            }
            
            // Try to get windows - this is limited without Accessibility API
            // For now, we'll use a heuristic: if an app is active and has windows, consider it
            if app.isActive {
                // We can't directly access other apps' windows without Accessibility API
                // But we can trigger window sitting based on app detection
                // This will be handled by the window controller
            }
        }
        
        return windows
    }
    
    func checkForWindowToSitOn() {
        let petEntity = windowController.getPetEntity()
        
        // Only try to sit when idle or walking
        guard petEntity.state == .idle || petEntity.state == .walking else { return }
        
        // Random chance to look for windows to sit on (5% chance per check)
        guard Double.random(in: 0...1) < 0.05 else { return }
        
        // Check if there's an active window we could sit on
        if let appMonitor = windowController.getAppMonitor(),
           appMonitor.isFocusing {
            // There's a focus app active - pet might want to sit on it
            // Trigger sitting behavior
            petEntity.setState(.sitting)
        }
    }
    
    // MARK: - Configuration
    func setInteractionMode(_ mode: InteractionMode) {
        interactionMode = mode
    }
    
    func setProximityThreshold(_ threshold: CGFloat) {
        proximityThreshold = threshold
    }
    
    func getInteractionMode() -> InteractionMode {
        return interactionMode
    }
    
    deinit {
        mouseTrackingTimer?.invalidate()
    }
}

import Cocoa
import Combine

class VideoDetection {
    private var appMonitor: AppMonitor
    private var windowController: PetWindowController
    private var videoCheckTimer: Timer?
    private var isWatchingVideo: Bool = false
    private var videoWindow: NSWindow?
    
    var onVideoDetected: ((Bool) -> Void)?
    
    init(appMonitor: AppMonitor, windowController: PetWindowController) {
        self.appMonitor = appMonitor
        self.windowController = windowController
        
        setupVideoDetection()
    }
    
    private func setupVideoDetection() {
        // Check for video periodically
        videoCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkForVideo()
        }
    }
    
    private func checkForVideo() {
        let wasWatching = isWatchingVideo
        
        // Enhanced video detection with multiple checks
        var detectedVideo = false
        
        // Check if current app is a video app
        if appMonitor.isVideoApp() {
            detectedVideo = true
            handleVideoDetected()
        } else {
            // Check for video windows (even if returns nil, might still be browser video)
            if let videoWindow = findVideoWindow() {
                detectedVideo = true
                self.videoWindow = videoWindow
                handleVideoDetected(videoWindow: videoWindow)
            } else {
                // Additional check: if browser is active and has been for a while, might be watching video
                // This is a heuristic since we can't detect actual video playback without Accessibility API
                if let frontmostApp = NSWorkspace.shared.frontmostApplication,
                   let bundleId = frontmostApp.bundleIdentifier {
                    let browserIds = [
                        "com.google.Chrome",
                        "com.apple.Safari",
                        "com.mozilla.firefox",
                        "com.microsoft.edgemac"
                    ]
                    
                    if browserIds.contains(bundleId) {
                        // Browser is active - could be watching video
                        // Use a conservative approach: only mark as watching if we were already watching
                        // (to avoid false positives)
                        if wasWatching {
                            detectedVideo = true
                            handleVideoDetected()
                        }
                    }
                }
                
                if !detectedVideo {
                    isWatchingVideo = false
                    videoWindow = nil
                    handleVideoStopped()
                }
            }
        }
        
        if detectedVideo {
            isWatchingVideo = true
        }
        
        if wasWatching != isWatchingVideo {
            onVideoDetected?(isWatchingVideo)
        }
    }
    
    private func findVideoWindow() -> NSWindow? {
        // Enhanced video window detection
        // Note: Full window access requires Accessibility API permissions
        // This uses app-level detection combined with heuristics
        
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication,
              let bundleId = frontmostApp.bundleIdentifier else {
            return nil
        }
        
        // Check if it's a known video app
        if appMonitor.isVideoApp() {
            // For video apps, we can't directly access their windows without Accessibility API
            // But we can position the pet near the center of the screen where video typically plays
            // Return a dummy window reference to trigger positioning
            // In a full implementation with Accessibility API, we would:
            // 1. Get all windows from the frontmost app
            // 2. Find the largest window (likely the video player)
            // 3. Position pet near that window
            
            // For now, return nil to use screen center positioning
            return nil
        }
        
        // Check for browser-based video (YouTube, Netflix, etc.)
        let browserVideoIds = [
            "com.google.Chrome",
            "com.apple.Safari",
            "com.mozilla.firefox",
            "com.microsoft.edgemac"
        ]
        
        if browserVideoIds.contains(bundleId) {
            // Browser is active - might be playing video
            // Without Accessibility API, we can't detect if a video is actually playing
            // But we can position pet near screen center as a heuristic
            return nil
        }
        
        return nil
    }
    
    private func handleVideoDetected(videoWindow: NSWindow? = nil) {
        let petEntity = windowController.getPetEntity()
        
        // Set pet to watching state
        if petEntity.state != .watching {
            petEntity.setState(.watching)
        }
        
        // Position pet near video window
        if let videoWindow = videoWindow {
            positionNearVideoWindow(videoWindow)
        } else {
            // Position near center of current screen
            if let screen = windowController.getCurrentScreen() {
                positionNearScreenCenter(screen)
            }
        }
    }
    
    private func handleVideoStopped() {
        let petEntity = windowController.getPetEntity()
        
        // Return to idle if was watching
        if petEntity.state == .watching {
            petEntity.setState(.idle)
        }
    }
    
    private func positionNearVideoWindow(_ videoWindow: NSWindow) {
        guard let window = windowController.window else { return }
        
        let videoFrame = videoWindow.frame
        let windowSize = window.frame.size
        
        // Position pet to the side or bottom of video window
        let positions: [(x: CGFloat, y: CGFloat)] = [
            (videoFrame.minX - windowSize.width - 10, videoFrame.midY - windowSize.height / 2), // Left side
            (videoFrame.maxX + 10, videoFrame.midY - windowSize.height / 2), // Right side
            (videoFrame.midX - windowSize.width / 2, videoFrame.minY - windowSize.height - 10), // Below
            (videoFrame.midX - windowSize.width / 2, videoFrame.maxY + 10) // Above
        ]
        
        // Find a position that's on screen
        if let screen = windowController.getCurrentScreen() {
            let screenFrame = screen.visibleFrame
            
            for position in positions {
                let testFrame = NSRect(
                    x: position.x,
                    y: position.y,
                    width: windowSize.width,
                    height: windowSize.height
                )
                
                if screenFrame.intersects(testFrame) {
                    NSAnimationContext.runAnimationGroup { context in
                        context.duration = 0.5
                        context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                        window.animator().setFrameOrigin(NSPoint(x: position.x, y: position.y))
                    }
                    return
                }
            }
        }
        
        // Fallback: position near video window center
        let centerX = videoFrame.midX - windowSize.width / 2
        let centerY = videoFrame.midY - windowSize.height / 2
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.5
            window.animator().setFrameOrigin(NSPoint(x: centerX, y: centerY))
        }
    }
    
    private func positionNearScreenCenter(_ screen: NSScreen) {
        guard let window = windowController.window else { return }
        
        let screenFrame = screen.visibleFrame
        let windowSize = window.frame.size
        
        // Position slightly off-center
        let centerX = screenFrame.midX - windowSize.width / 2 + CGFloat.random(in: -50...50)
        let centerY = screenFrame.midY - windowSize.height / 2 + CGFloat.random(in: -50...50)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.5
            window.animator().setFrameOrigin(NSPoint(x: centerX, y: centerY))
        }
    }
    
    func getIsWatchingVideo() -> Bool {
        return isWatchingVideo
    }
    
    deinit {
        videoCheckTimer?.invalidate()
    }
}

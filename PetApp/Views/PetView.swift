import Cocoa
import QuartzCore
import Combine

class PetView: NSView {
    private var petEntity: PetEntity
    private var renderer: PetRenderer
    private var animationLayer: CALayer
    private var feedbackLayer: CAShapeLayer
    private var cancellables = Set<AnyCancellable>()
    
    // Animation properties
    private var currentAnimation: CAAnimation?
    private var positionAnimation: CAAnimation?
    
    init(petEntity: PetEntity, frame: CGRect) {
        self.petEntity = petEntity
        self.renderer = PetRenderer(size: frame.size)
        self.animationLayer = CALayer()
        self.feedbackLayer = CAShapeLayer()
        
        super.init(frame: frame)
        
        setupView()
        setupObservers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        wantsLayer = true
        layer = CALayer()
        layer?.backgroundColor = NSColor.clear.cgColor
        
        // Add pet layer
        let petLayer = renderer.getLayer()
        petLayer.frame = bounds
        animationLayer.addSublayer(petLayer)
        layer?.addSublayer(animationLayer)
        
        feedbackLayer.frame = bounds
        feedbackLayer.fillColor = NSColor.clear.cgColor
        feedbackLayer.strokeColor = NSColor.white.withAlphaComponent(0.8).cgColor
        feedbackLayer.lineWidth = 2.0
        feedbackLayer.opacity = 0.0
        layer?.addSublayer(feedbackLayer)
        
        // Accessibility support
        setAccessibilityLabel("Pet: \(petEntity.state.displayName)")
        setAccessibilityRole(.image)
        
        // Initial render
        updateForState()
    }
    
    private func setupObservers() {
        // Observe state changes - debounced for performance
        petEntity.$state
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateForState()
            }
            .store(in: &cancellables)
        
        // Observe age changes - update less frequently for performance
        var lastAgeUpdate: Date = Date()
        petEntity.$age
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                let now = Date()
                // Only update every 5 minutes
                if now.timeIntervalSince(lastAgeUpdate) >= 300 {
                    lastAgeUpdate = now
                    self?.updateForState()
                }
            }
            .store(in: &cancellables)
        
        // Observe health/happiness changes - debounced
        petEntity.$health
            .combineLatest(petEntity.$happiness)
            .removeDuplicates { $0.0 == $1.0 && $0.1 == $1.1 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateForState()
            }
            .store(in: &cancellables)
    }
    
    override func layout() {
        super.layout()
        animationLayer.frame = bounds
        renderer.updateShape(size: bounds.size)
        feedbackLayer.frame = bounds
    }
    
    private func updateForState() {
        // Reset any stray transforms from prior animations to avoid cumulative scaling
        // Especially important when transitioning away from dancing state
        animationLayer.removeAnimation(forKey: "danceIntensity")
        animationLayer.removeAllAnimations()
        
        // Explicitly reset transform to identity to prevent cumulative scaling
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        animationLayer.transform = CATransform3DIdentity
        CATransaction.commit()
        
        renderer.updateForState(
            petEntity.state,
            age: petEntity.age,
            health: petEntity.health,
            happiness: petEntity.happiness
        )
        
        // Update accessibility label
        setAccessibilityLabel("Pet: \(petEntity.state.displayName), Health: \(Int(petEntity.health * 100))%, Happiness: \(Int(petEntity.happiness * 100))%")
        
        // Animate state transition
        animateStateTransition()
    }
    
    private func animateStateTransition() {
        // Remove existing animations
        animationLayer.removeAllAnimations()
        
        // Ensure transform is reset before applying new animations
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        animationLayer.transform = CATransform3DIdentity
        CATransaction.commit()
        
        let state = petEntity.state
        
        switch state {
        case .idle:
            animateIdle()
        case .running:
            animateRunning()
        case .walking:
            animateWalking()
        case .eating:
            animateEating()
        case .playing:
            animatePlaying()
        case .dragging:
            animateDragging()
        case .dropped:
            animateDropped()
        case .dancing:
            animateDancing()
        case .watching:
            animateWatching()
        case .sitting:
            animateSitting()
        case .sleeping:
            animateSleeping()
        }
    }
    
    private func animateIdle() {
        let bob = CAKeyframeAnimation(keyPath: "position.y")
        bob.values = [bounds.midY, bounds.midY - 2, bounds.midY]
        bob.duration = 1.2
        bob.repeatCount = .greatestFiniteMagnitude
        bob.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animationLayer.add(bob, forKey: "idle")
    }
    
    private func animateWalking() {
        let bounce = CAKeyframeAnimation(keyPath: "position.y")
        bounce.values = [bounds.midY, bounds.midY - 3, bounds.midY]
        bounce.duration = 0.35
        bounce.repeatCount = .greatestFiniteMagnitude
        bounce.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animationLayer.add(bounce, forKey: "walking")
        
        let tilt = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        tilt.values = [-0.05, 0.05, -0.05]
        tilt.duration = 0.7
        tilt.repeatCount = .greatestFiniteMagnitude
        tilt.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animationLayer.add(tilt, forKey: "walkTilt")
    }
    
    private func animateRunning() {
        let bounce = CAKeyframeAnimation(keyPath: "position.y")
        bounce.values = [bounds.midY, bounds.midY - 5, bounds.midY - 1]
        bounce.duration = 0.25
        bounce.repeatCount = .greatestFiniteMagnitude
        bounce.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animationLayer.add(bounce, forKey: "runningBounce")
        
        let tilt = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        tilt.values = [-0.08, 0.08, -0.08]
        tilt.duration = 0.5
        tilt.repeatCount = .greatestFiniteMagnitude
        tilt.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animationLayer.add(tilt, forKey: "runningTilt")
    }
    
    private func animateEating() {
        let bob = CAKeyframeAnimation(keyPath: "position.y")
        bob.values = [bounds.midY, bounds.midY - 2, bounds.midY]
        bob.duration = 0.6
        bob.repeatCount = .greatestFiniteMagnitude
        bob.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animationLayer.add(bob, forKey: "eatingBob")
    }
    
    private func animatePlaying() {
        let bounce = CAKeyframeAnimation(keyPath: "position.y")
        bounce.values = [bounds.midY, bounds.midY - 4, bounds.midY + 1, bounds.midY - 4, bounds.midY]
        bounce.duration = 0.4
        bounce.repeatCount = .greatestFiniteMagnitude
        bounce.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animationLayer.add(bounce, forKey: "playingBounce")
        
        let wiggle = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        wiggle.values = [-0.06, 0.06, -0.06]
        wiggle.duration = 0.35
        wiggle.repeatCount = .greatestFiniteMagnitude
        wiggle.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animationLayer.add(wiggle, forKey: "playingWiggle")
    }
    
    private func animateDragging() {
        let stretch = CAKeyframeAnimation(keyPath: "transform.scale")
        stretch.values = [
            CATransform3DIdentity,
            CATransform3DMakeScale(1.05, 0.95, 1.0),
            CATransform3DIdentity
        ]
        stretch.duration = 0.4
        stretch.repeatCount = .greatestFiniteMagnitude
        stretch.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animationLayer.add(stretch, forKey: "dragStretch")
    }
    
    private func animateDropped() {
        let squash = CAKeyframeAnimation(keyPath: "transform.scale")
        squash.values = [
            CATransform3DMakeScale(1.08, 0.92, 1.0),
            CATransform3DIdentity,
            CATransform3DMakeScale(1.02, 0.98, 1.0),
            CATransform3DIdentity
        ]
        squash.duration = 0.35
        squash.repeatCount = 1
        squash.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animationLayer.add(squash, forKey: "dropSquash")
    }
    
    private func animateDancing() {
        // Ensure transform is identity before starting dance animation
        // This guarantees the animation starts at the same dimension as normal state
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        animationLayer.transform = CATransform3DIdentity
        CATransaction.commit()
        
        let bounce = CAKeyframeAnimation(keyPath: "position.y")
        bounce.values = [bounds.midY, bounds.midY - 5, bounds.midY + 2, bounds.midY - 5, bounds.midY]
        bounce.duration = 0.45
        bounce.repeatCount = .greatestFiniteMagnitude
        bounce.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animationLayer.add(bounce, forKey: "danceBounce")
        
        let rotate = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        rotate.values = [-0.12, 0.12, -0.12]
        rotate.duration = 0.35
        rotate.repeatCount = .greatestFiniteMagnitude
        rotate.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animationLayer.add(rotate, forKey: "danceRotate")
    }
    
    private func animateWatching() {
        let pulse = CAKeyframeAnimation(keyPath: "transform.scale")
        pulse.values = [1.0, 1.03, 1.0]
        pulse.duration = 1.4
        pulse.repeatCount = .greatestFiniteMagnitude
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animationLayer.add(pulse, forKey: "watching")
    }
    
    private func animateSitting() {
        let bob = CAKeyframeAnimation(keyPath: "position.y")
        bob.values = [bounds.midY, bounds.midY - 1.5, bounds.midY]
        bob.duration = 1.0
        bob.repeatCount = .greatestFiniteMagnitude
        bob.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animationLayer.add(bob, forKey: "sitting")
    }
    
    private func animateSleeping() {
        let breathe = CAKeyframeAnimation(keyPath: "position.y")
        breathe.values = [bounds.midY, bounds.midY - 1, bounds.midY]
        breathe.duration = 2.4
        breathe.repeatCount = .greatestFiniteMagnitude
        breathe.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animationLayer.add(breathe, forKey: "sleeping")
    }
    
    func updateDanceIntensity(_ intensity: Double) {
        // No size changes - keep everything at fixed dimensions
        // The dancing animation (bounce/rotate) is handled by animateDancing()
        // This function is kept for API compatibility but does not change dimensions
        guard petEntity.state == .dancing else {
            // If state changed, ensure transform is reset to identity
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                animationLayer.removeAnimation(forKey: "danceIntensity")
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                animationLayer.transform = CATransform3DIdentity
                CATransaction.commit()
            }
            return
        }
        
        // Ensure transform remains at identity - no scaling
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard self.petEntity.state == .dancing else {
                // State changed, clean up
                self.animationLayer.removeAnimation(forKey: "danceIntensity")
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                self.animationLayer.transform = CATransform3DIdentity
                CATransaction.commit()
                return
            }
            
            // Ensure transform is always identity - no dimension changes
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            animationLayer.transform = CATransform3DIdentity
            CATransaction.commit()
        }
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        triggerClickFlash(at: point)
        
        // Record click interaction memory
        MemoryManager.shared.recordInteraction(type: "click", location: point)
        
        super.mouseDown(with: event)
    }
    
    private func triggerClickFlash(at point: CGPoint) {
        let size: CGFloat = 14.0
        let rect = CGRect(x: point.x - size / 2, y: point.y - size / 2, width: size, height: size)
        let path = NSBezierPath(ovalIn: rect)
        feedbackLayer.path = path.cgPath
        feedbackLayer.opacity = 0.8
        feedbackLayer.strokeColor = NSColor.white.withAlphaComponent(0.9).cgColor
        
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 0.8
        fade.toValue = 0.0
        fade.duration = 0.25
        fade.fillMode = .forwards
        fade.isRemovedOnCompletion = false
        feedbackLayer.add(fade, forKey: "flash")
    }
}

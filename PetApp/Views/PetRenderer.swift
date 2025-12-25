import Cocoa
import QuartzCore

/// Clean, appealing cat design with smooth animations
private struct CatPalette {
    // Warm orange tabby cat colors
    let furBase = NSColor(calibratedRed: 0.95, green: 0.75, blue: 0.50, alpha: 1.0) // warm orange
    let furDark = NSColor(calibratedRed: 0.80, green: 0.55, blue: 0.35, alpha: 1.0) // darker orange (stripes)
    let furLight = NSColor(calibratedWhite: 0.98, alpha: 1.0) // cream belly
    let nose = NSColor(calibratedRed: 0.95, green: 0.65, blue: 0.75, alpha: 1.0) // pink nose
    let eyeColor = NSColor(calibratedRed: 0.20, green: 0.60, blue: 0.90, alpha: 1.0) // bright blue eyes
    let pupil = NSColor(calibratedWhite: 0.05, alpha: 1.0) // black pupil
    let mouth = NSColor(calibratedWhite: 0.15, alpha: 1.0) // dark mouth
}

class PetRenderer {
    private var petLayer: CALayer
    
    // Cat body parts
    private var headLayer: CAShapeLayer
    private var bodyLayer: CAShapeLayer
    private var tailLayer: CAShapeLayer
    private var earLayers: [CAShapeLayer] // 2 ears
    private var eyeLayers: [CAShapeLayer] // 2 eyes
    private var pupilLayers: [CAShapeLayer] // 2 pupils
    private var noseLayer: CAShapeLayer
    private var mouthLayer: CAShapeLayer
    private var whiskerLayers: [CAShapeLayer] // 4 whiskers (2 per side)
    private var pawLayers: [CAShapeLayer] // 4 paws
    private var bellyLayer: CAShapeLayer // light colored belly
    
    // Accessories for states
    private var accessoryLayers: [CAShapeLayer]
    
    private let palette = CatPalette()
    private var size: CGSize = .zero
    
    private var currentState: PetState = .idle
    private var currentHappiness: Double = 1.0
    
    init(size: CGSize) {
        self.size = size
        
        petLayer = CALayer()
        petLayer.frame = CGRect(origin: .zero, size: size)
        
        // Head (rounded, cat-like)
        headLayer = CAShapeLayer()
        headLayer.fillColor = palette.furBase.cgColor
        headLayer.strokeColor = palette.furDark.cgColor
        headLayer.lineWidth = 1.5
        petLayer.addSublayer(headLayer)
        
        // Body (sleek, cat-like)
        bodyLayer = CAShapeLayer()
        bodyLayer.fillColor = palette.furBase.cgColor
        bodyLayer.strokeColor = palette.furDark.cgColor
        bodyLayer.lineWidth = 1.5
        petLayer.addSublayer(bodyLayer)
        
        // Belly (lighter color)
        bellyLayer = CAShapeLayer()
        bellyLayer.fillColor = palette.furLight.cgColor
        bellyLayer.strokeColor = NSColor.clear.cgColor
        petLayer.addSublayer(bellyLayer)
        
        // Tail (expressive)
        tailLayer = CAShapeLayer()
        tailLayer.fillColor = palette.furBase.cgColor
        tailLayer.strokeColor = palette.furDark.cgColor
        tailLayer.lineWidth = 1.5
        petLayer.addSublayer(tailLayer)
        
        // Ears (triangular, cat-like)
        earLayers = []
        for _ in 0..<2 {
            let ear = CAShapeLayer()
            ear.fillColor = palette.furBase.cgColor
            ear.strokeColor = palette.furDark.cgColor
            ear.lineWidth = 1.5
            petLayer.addSublayer(ear)
            earLayers.append(ear)
        }
        
        // Eyes (large, expressive)
        eyeLayers = []
        for _ in 0..<2 {
            let eye = CAShapeLayer()
            eye.fillColor = palette.eyeColor.cgColor
            eye.strokeColor = palette.pupil.cgColor
            eye.lineWidth = 1.0
            petLayer.addSublayer(eye)
            eyeLayers.append(eye)
        }
        
        // Pupils
        pupilLayers = []
        for _ in 0..<2 {
            let pupil = CAShapeLayer()
            pupil.fillColor = palette.pupil.cgColor
            petLayer.addSublayer(pupil)
            pupilLayers.append(pupil)
        }
        
        // Nose (small triangle)
        noseLayer = CAShapeLayer()
        noseLayer.fillColor = palette.nose.cgColor
        noseLayer.strokeColor = palette.furDark.cgColor
        noseLayer.lineWidth = 0.5
        petLayer.addSublayer(noseLayer)
        
        // Mouth (simple line or curve)
        mouthLayer = CAShapeLayer()
        mouthLayer.fillColor = NSColor.clear.cgColor
        mouthLayer.strokeColor = palette.mouth.cgColor
        mouthLayer.lineWidth = 1.5
        mouthLayer.lineCap = .round
        petLayer.addSublayer(mouthLayer)
        
        // Whiskers (4 total, 2 per side)
        whiskerLayers = []
        for _ in 0..<4 {
            let whisker = CAShapeLayer()
            whisker.fillColor = NSColor.clear.cgColor
            whisker.strokeColor = palette.mouth.cgColor
            whisker.lineWidth = 1.0
            whisker.lineCap = .round
            petLayer.addSublayer(whisker)
            whiskerLayers.append(whisker)
        }
        
        // Paws (4 total)
        pawLayers = []
        for _ in 0..<4 {
            let paw = CAShapeLayer()
            paw.fillColor = palette.furBase.cgColor
            paw.strokeColor = palette.furDark.cgColor
            paw.lineWidth = 1.0
            petLayer.addSublayer(paw)
            pawLayers.append(paw)
        }
        
        accessoryLayers = []
        
        updateShape(size: size)
    }
    
    func updateShape(size: CGSize) {
        self.size = size
        petLayer.frame = CGRect(origin: .zero, size: size)
        
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let scale = min(size.width, size.height) / 100.0 // Base scale
        
        // Head (rounded, positioned at top) - flip Y to fix upside-down
        let headSize = scale * 35
        let headY = center.y + scale * 15 // Changed from - to + to flip
        let headRect = CGRect(
            x: center.x - headSize / 2,
            y: headY - headSize / 2,
            width: headSize,
            height: headSize
        )
        headLayer.path = createRoundedRectPath(rect: headRect, cornerRadius: headSize * 0.4).cgPath
        headLayer.frame = petLayer.bounds
        
        // Ears (triangular, on top of head)
        let earSize = scale * 12
        let earY = headY + headSize / 2 + earSize * 0.3 // Flip: changed - to +
        for (index, ear) in earLayers.enumerated() {
            let earX = center.x + (index == 0 ? -headSize * 0.25 : headSize * 0.25)
            let earPath = createTrianglePath(
                center: CGPoint(x: earX, y: earY),
                size: CGSize(width: earSize, height: earSize * 1.2),
                pointingUp: false // Flip: changed true to false (pointing down now means pointing up visually)
            )
            ear.path = earPath.cgPath
            ear.frame = petLayer.bounds
        }
        
        // Body (oval, sleek)
        let bodyWidth = scale * 40
        let bodyHeight = scale * 50
        let bodyY = center.y - scale * 10 // Flip: changed + to -
        let bodyRect = CGRect(
            x: center.x - bodyWidth / 2,
            y: bodyY - bodyHeight / 2,
            width: bodyWidth,
            height: bodyHeight
        )
        bodyLayer.path = createRoundedRectPath(rect: bodyRect, cornerRadius: bodyWidth * 0.3).cgPath
        bodyLayer.frame = petLayer.bounds
        
        // Belly (lighter, on body)
        let bellyWidth = bodyWidth * 0.6
        let bellyHeight = bodyHeight * 0.5
        let bellyRect = CGRect(
            x: center.x - bellyWidth / 2,
            y: bodyY + bellyHeight * 0.3, // Flip: changed - to +
            width: bellyWidth,
            height: bellyHeight
        )
        bellyLayer.path = createRoundedRectPath(rect: bellyRect, cornerRadius: bellyWidth * 0.2).cgPath
        bellyLayer.frame = petLayer.bounds
        
        // Tail (curved, expressive)
        updateTail(center: center, scale: scale, state: currentState)
        
        // Eyes (large, expressive) - set anchor point for animations
        let eyeSize = scale * 8
        let eyeY = headY + scale * 3 // Flip: changed - to +
        let eyeSpacing = scale * 12
        for (index, eye) in eyeLayers.enumerated() {
            let eyeX = center.x + (index == 0 ? -eyeSpacing / 2 : eyeSpacing / 2)
            let eyeRect = CGRect(
                x: eyeX - eyeSize / 2,
                y: eyeY - eyeSize / 2,
                width: eyeSize,
                height: eyeSize
            )
            eye.path = NSBezierPath(ovalIn: eyeRect).cgPath
            eye.frame = petLayer.bounds
            
            // Set anchor point to center of eye for proper scaling animations
            eye.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            eye.position = CGPoint(x: eyeX, y: eyeY)
        }
        
        // Pupils (adjust based on state)
        let pupilSize = scale * 4
        let watchOffset: CGFloat = currentState == .watching ? scale * 3 : 0
        for (index, pupil) in pupilLayers.enumerated() {
            let eyeX = center.x + (index == 0 ? -eyeSpacing / 2 : eyeSpacing / 2)
            let pupilX = eyeX + watchOffset
            let pupilRect = CGRect(
                x: pupilX - pupilSize / 2,
                y: eyeY - pupilSize / 2,
                width: pupilSize,
                height: pupilSize
            )
            pupil.path = NSBezierPath(ovalIn: pupilRect).cgPath
            pupil.frame = petLayer.bounds
        }
        
        // Nose (small triangle, below eyes)
        let noseSize = scale * 4
        let noseY = headY - scale * 5 // Flip: changed + to -
        let nosePath = createTrianglePath(
            center: CGPoint(x: center.x, y: noseY),
            size: CGSize(width: noseSize, height: noseSize * 0.8),
            pointingUp: true // Flip: changed false to true
        )
        noseLayer.path = nosePath.cgPath
        noseLayer.frame = petLayer.bounds
        
        // Mouth (simple curve or line)
        updateMouth(center: center, noseY: noseY, scale: scale, state: currentState, happiness: currentHappiness)
        
        // Whiskers (4 total, 2 per side)
        let whiskerLength = scale * 15
        let whiskerY = noseY - scale * 2 // Flip: changed + to -
        for (index, whisker) in whiskerLayers.enumerated() {
            let isLeft = index < 2
            let isUpper = index % 2 == 0
            let whiskerX = center.x + (isLeft ? -scale * 8 : scale * 8)
            let angle: CGFloat = isUpper ? 0.3 : -0.3 // Flip angles
            let endX = whiskerX + (isLeft ? -whiskerLength : whiskerLength) * cos(angle)
            let endY = whiskerY + whiskerLength * sin(angle)
            
            let whiskerPath = NSBezierPath()
            whiskerPath.move(to: CGPoint(x: whiskerX, y: whiskerY))
            whiskerPath.line(to: CGPoint(x: endX, y: endY))
            whisker.path = whiskerPath.cgPath
            whisker.frame = petLayer.bounds
        }
        
        // Paws (4 total, positioned at body corners) - make them more 3D looking
        let pawSize = scale * 7
        let pawPositions: [(CGFloat, CGFloat)] = [
            (center.x - bodyWidth * 0.3, bodyY - bodyHeight * 0.4), // front left (flip Y)
            (center.x + bodyWidth * 0.3, bodyY - bodyHeight * 0.4), // front right
            (center.x - bodyWidth * 0.25, bodyY - bodyHeight * 0.45), // back left
            (center.x + bodyWidth * 0.25, bodyY - bodyHeight * 0.45)  // back right
        ]
        for (index, paw) in pawLayers.enumerated() {
            let (pawX, pawY) = pawPositions[index]
            // Make paws rounded rectangles for more cat-like appearance
            let pawRect = CGRect(
                x: pawX - pawSize / 2,
                y: pawY - pawSize / 2,
                width: pawSize,
                height: pawSize * 1.2
            )
            paw.path = createRoundedRectPath(rect: pawRect, cornerRadius: pawSize * 0.4).cgPath
            paw.frame = petLayer.bounds
            
            // Set anchor point for rotation animations
            paw.anchorPoint = CGPoint(x: 0.5, y: 1.0) // Anchor at top of paw
            paw.position = CGPoint(x: pawX, y: pawY - pawSize * 0.6)
        }
        
        applyBlinkIfNeeded()
    }
    
    private func updateTail(center: CGPoint, scale: CGFloat, state: PetState) {
        let tailWidth = scale * 6
        let tailLength = scale * 25
        
        // Tail position and curve based on state (flip Y coordinates)
        let tailBaseX = center.x + scale * 15
        let tailBaseY = center.y - scale * 15 // Flip: changed + to -
        
        var endPoint: CGPoint
        var control1: CGPoint
        var control2: CGPoint
        
        switch state {
        case .playing, .dancing:
            // Curved up (happy) - flip all Y coordinates
            endPoint = CGPoint(x: tailBaseX + scale * 10, y: tailBaseY + tailLength)
            control1 = CGPoint(x: tailBaseX + scale * 5, y: tailBaseY + tailLength * 0.3)
            control2 = CGPoint(x: tailBaseX + scale * 8, y: tailBaseY + tailLength * 0.7)
        case .sleeping:
            // Curled around body
            endPoint = CGPoint(x: tailBaseX - scale * 8, y: tailBaseY + tailLength * 0.6)
            control1 = CGPoint(x: tailBaseX - scale * 3, y: tailBaseY + tailLength * 0.2)
            control2 = CGPoint(x: tailBaseX - scale * 6, y: tailBaseY + tailLength * 0.4)
        case .watching:
            // Slightly raised, curious
            endPoint = CGPoint(x: tailBaseX + scale * 5, y: tailBaseY + tailLength * 0.7)
            control1 = CGPoint(x: tailBaseX + scale * 2, y: tailBaseY + tailLength * 0.3)
            control2 = CGPoint(x: tailBaseX + scale * 4, y: tailBaseY + tailLength * 0.5)
        default:
            // Natural curve down
            endPoint = CGPoint(x: tailBaseX + scale * 3, y: tailBaseY - tailLength * 0.8)
            control1 = CGPoint(x: tailBaseX + scale * 2, y: tailBaseY - tailLength * 0.3)
            control2 = CGPoint(x: tailBaseX + scale * 2.5, y: tailBaseY - tailLength * 0.6)
        }
        
        // Create tail as a simple curved rounded rectangle
        // Use a path that follows the curve
        let tailPath = NSBezierPath()
        
        // Start with base (wider)
        let baseWidth = tailWidth * 1.2
        let baseRect = CGRect(
            x: tailBaseX - baseWidth / 2,
            y: tailBaseY - baseWidth / 2,
            width: baseWidth,
            height: baseWidth
        )
        tailPath.append(NSBezierPath(roundedRect: baseRect, xRadius: baseWidth / 2, yRadius: baseWidth / 2))
        
        // End with tip (narrower)
        let tipWidth = tailWidth * 0.7
        let tipRect = CGRect(
            x: endPoint.x - tipWidth / 2,
            y: endPoint.y - tipWidth / 2,
            width: tipWidth,
            height: tipWidth
        )
        tailPath.append(NSBezierPath(roundedRect: tipRect, xRadius: tipWidth / 2, yRadius: tipWidth / 2))
        
        // Add connecting curve (this will be drawn with line width)
        let curve = NSBezierPath()
        curve.move(to: CGPoint(x: tailBaseX, y: tailBaseY))
        curve.curve(to: endPoint, controlPoint1: control1, controlPoint2: control2)
        curve.lineWidth = tailWidth
        tailPath.append(curve)
        
        tailLayer.path = tailPath.cgPath
        tailLayer.frame = petLayer.bounds
    }
    
    private func updateMouth(center: CGPoint, noseY: CGFloat, scale: CGFloat, state: PetState, happiness: Double) {
        let mouthY = noseY - scale * 3 // Flip: changed + to -
        let mouthWidth = scale * 8
        
        let mouthPath = NSBezierPath()
        
        switch state {
        case .playing, .dancing:
            // Happy smile - flip Y for control points
            mouthPath.move(to: CGPoint(x: center.x - mouthWidth / 2, y: mouthY))
            mouthPath.curve(
                to: CGPoint(x: center.x + mouthWidth / 2, y: mouthY),
                controlPoint1: CGPoint(x: center.x - mouthWidth / 4, y: mouthY - scale * 2),
                controlPoint2: CGPoint(x: center.x + mouthWidth / 4, y: mouthY - scale * 2)
            )
        case .eating:
            // Open mouth (small circle)
            let mouthRect = CGRect(
                x: center.x - mouthWidth / 3,
                y: mouthY - mouthWidth / 3,
                width: mouthWidth * 2/3,
                height: mouthWidth * 2/3
            )
            mouthPath.append(NSBezierPath(ovalIn: mouthRect))
            mouthLayer.fillColor = palette.mouth.cgColor
        case .sleeping:
            // Closed, just a line
            mouthPath.move(to: CGPoint(x: center.x - mouthWidth / 3, y: mouthY))
            mouthPath.line(to: CGPoint(x: center.x + mouthWidth / 3, y: mouthY))
        case .watching:
            // Small "o" (curious)
            let mouthRect = CGRect(
                x: center.x - mouthWidth / 3,
                y: mouthY - mouthWidth / 4,
                width: mouthWidth * 2/3,
                height: mouthWidth / 2
            )
            mouthPath.append(NSBezierPath(ovalIn: mouthRect))
            mouthLayer.fillColor = palette.mouth.cgColor
        default:
            // Neutral or happy based on happiness
            if happiness > 0.6 {
                mouthPath.move(to: CGPoint(x: center.x - mouthWidth / 2, y: mouthY))
                mouthPath.curve(
                    to: CGPoint(x: center.x + mouthWidth / 2, y: mouthY),
                    controlPoint1: CGPoint(x: center.x - mouthWidth / 4, y: mouthY - scale * 1.5),
                    controlPoint2: CGPoint(x: center.x + mouthWidth / 4, y: mouthY - scale * 1.5)
                )
            } else {
                mouthPath.move(to: CGPoint(x: center.x - mouthWidth / 2, y: mouthY))
                mouthPath.line(to: CGPoint(x: center.x + mouthWidth / 2, y: mouthY))
            }
        }
        
        if state != .eating && state != .watching {
            mouthLayer.fillColor = NSColor.clear.cgColor
        }
        mouthLayer.path = mouthPath.cgPath
        mouthLayer.frame = petLayer.bounds
    }
    
    func updateForState(_ state: PetState, age: Double, health: Double, happiness: Double) {
        currentState = state
        currentHappiness = happiness
        
        // Update colors based on happiness (subtle)
        let colorFactor = max(0.0, min(1.0, happiness))
        let bodyColor = interpolateColor(
            from: palette.furDark,
            to: palette.furBase,
            factor: 0.3 + colorFactor * 0.7
        )
        
        headLayer.fillColor = bodyColor.cgColor
        bodyLayer.fillColor = bodyColor.cgColor
        tailLayer.fillColor = bodyColor.cgColor
        earLayers.forEach { $0.fillColor = bodyColor.cgColor }
        pawLayers.forEach { $0.fillColor = bodyColor.cgColor }
        
        // Update accessories
        updateAccessories(state: state, center: CGPoint(x: size.width / 2, y: size.height / 2))
        
        // Update shape (for tail, mouth, etc.)
        updateShape(size: size)
        
        // Apply state-specific animations
        applyStateAnimations(for: state)
    }
    
    private func updateAccessories(state: PetState, center: CGPoint) {
        // Remove old accessories
        accessoryLayers.forEach { $0.removeFromSuperlayer() }
        accessoryLayers.removeAll()
        
        switch state {
        case .sleeping:
            addSleepZzz(center: center)
        case .playing:
            addPlaySparkles(center: center)
        case .dancing:
            addMusicNotes(center: center)
        case .eating:
            addFoodBowl(center: center)
        default:
            break
        }
    }
    
    private func addSleepZzz(center: CGPoint) {
        let scale = min(size.width, size.height) / 100.0
        for i in 0..<3 {
            let zzz = CATextLayer()
            zzz.string = "z"
            zzz.fontSize = scale * (8 - CGFloat(i) * 1.5)
            zzz.foregroundColor = palette.furDark.withAlphaComponent(0.6).cgColor
            zzz.alignmentMode = .center
            zzz.frame = CGRect(
                x: center.x + scale * 25 + CGFloat(i) * scale * 8,
                y: center.y - scale * 10 - CGFloat(i) * scale * 5,
                width: scale * 10,
                height: scale * 10
            )
            
            let float = CABasicAnimation(keyPath: "position.y")
            float.byValue = -scale * 3
            float.duration = 2.0 + Double(i) * 0.3
            float.autoreverses = true
            float.repeatCount = .greatestFiniteMagnitude
            zzz.add(float, forKey: "float")
            
            petLayer.addSublayer(zzz)
            // Note: CATextLayer is not a CAShapeLayer, so we don't add it to accessoryLayers
        }
    }
    
    private func addPlaySparkles(center: CGPoint) {
        let scale = min(size.width, size.height) / 100.0
        for i in 0..<4 {
            let sparkle = CAShapeLayer()
            let angle = Double(i) * .pi * 2.0 / 4.0
            let radius = scale * 20
            let sparkleX = center.x + CGFloat(cos(angle)) * radius
            let sparkleY = center.y - scale * 15 + CGFloat(sin(angle)) * radius
            
            let sparkleSize = scale * 3
            let sparklePath = NSBezierPath()
            sparklePath.move(to: CGPoint(x: sparkleX, y: sparkleY - sparkleSize))
            sparklePath.line(to: CGPoint(x: sparkleX, y: sparkleY + sparkleSize))
            sparklePath.move(to: CGPoint(x: sparkleX - sparkleSize, y: sparkleY))
            sparklePath.line(to: CGPoint(x: sparkleX + sparkleSize, y: sparkleY))
            
            sparkle.path = sparklePath.cgPath
            sparkle.strokeColor = palette.eyeColor.cgColor
            sparkle.lineWidth = 1.5
            sparkle.frame = petLayer.bounds
            
            let rotate = CABasicAnimation(keyPath: "transform.rotation.z")
            rotate.fromValue = 0
            rotate.toValue = CGFloat.pi * 2
            rotate.duration = 1.5
            rotate.repeatCount = .greatestFiniteMagnitude
            sparkle.add(rotate, forKey: "rotate")
            
            petLayer.addSublayer(sparkle)
            accessoryLayers.append(sparkle)
        }
    }
    
    private func addMusicNotes(center: CGPoint) {
        let scale = min(size.width, size.height) / 100.0
        for i in 0..<2 {
            let note = CATextLayer()
            note.string = "♪"
            note.fontSize = scale * 10
            note.foregroundColor = palette.furDark.cgColor
            note.alignmentMode = .center
            note.frame = CGRect(
                x: center.x - scale * 10 + CGFloat(i) * scale * 15,
                y: center.y - scale * 20,
                width: scale * 12,
                height: scale * 12
            )
            
            let bounce = CABasicAnimation(keyPath: "position.y")
            bounce.byValue = scale * 4
            bounce.duration = 0.6
            bounce.autoreverses = true
            bounce.repeatCount = .greatestFiniteMagnitude
            bounce.beginTime = CACurrentMediaTime() + CFTimeInterval(i) * 0.3
            note.add(bounce, forKey: "bounce")
            
            petLayer.addSublayer(note)
        }
    }
    
    private func addFoodBowl(center: CGPoint) {
        let scale = min(size.width, size.height) / 100.0
        let bowl = CAShapeLayer()
        let bowlWidth = scale * 20
        let bowlHeight = scale * 6
        let bowlRect = CGRect(
            x: center.x - bowlWidth / 2,
            y: center.y + scale * 30,
            width: bowlWidth,
            height: bowlHeight
        )
        bowl.path = createRoundedRectPath(rect: bowlRect, cornerRadius: scale * 2).cgPath
        bowl.fillColor = palette.furDark.withAlphaComponent(0.8).cgColor
        bowl.strokeColor = palette.furDark.cgColor
        bowl.lineWidth = 1.0
        bowl.frame = petLayer.bounds
        
        petLayer.addSublayer(bowl)
        accessoryLayers.append(bowl)
    }
    
    private func applyStateAnimations(for state: PetState) {
        clearStateAnimations()
        
        switch state {
        case .idle:
            addIdleBreathing()
        case .walking:
            addWalkCycle()
        case .running:
            addRunCycle()
        case .sleeping:
            addSleepBreathing()
        case .eating:
            addEatAnimation()
        case .playing:
            addPlayBounce()
        case .sitting:
            addSitAnimation()
        case .watching:
            addWatchAnimation()
        case .dancing:
            addDanceAnimation()
        default:
            break
        }
    }
    
    private func clearStateAnimations() {
        let layersToClear: [CALayer] = [petLayer, headLayer, bodyLayer, tailLayer] + earLayers + pawLayers
        layersToClear.forEach { $0.removeAllAnimations() }
        applyBlinkIfNeeded()
    }
    
    private func addIdleBreathing() {
        let breathe = CABasicAnimation(keyPath: "transform.scale")
        breathe.fromValue = CATransform3DIdentity
        breathe.toValue = CATransform3DMakeScale(1.02, 1.02, 1.0)
        breathe.duration = 2.5
        breathe.autoreverses = true
        breathe.repeatCount = .greatestFiniteMagnitude
        breathe.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        bodyLayer.add(breathe, forKey: "breathe")
        
        // Tail gentle sway with 3D effect
        let tailSway = CABasicAnimation(keyPath: "transform.rotation.z")
        tailSway.fromValue = -CGFloat.pi / 60
        tailSway.toValue = CGFloat.pi / 60
        tailSway.duration = 3.0
        tailSway.autoreverses = true
        tailSway.repeatCount = .greatestFiniteMagnitude
        tailSway.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        tailLayer.add(tailSway, forKey: "tail-sway")
        
        // Tail tip curl (3D effect)
        let tailCurl = CABasicAnimation(keyPath: "transform.scale.x")
        tailCurl.fromValue = 0.98
        tailCurl.toValue = 1.02
        tailCurl.duration = 2.0
        tailCurl.autoreverses = true
        tailCurl.repeatCount = .greatestFiniteMagnitude
        tailCurl.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        tailLayer.add(tailCurl, forKey: "tail-curl")
        
        // Occasional paw twitch for realism
        for (index, paw) in pawLayers.enumerated() {
            let twitch = CABasicAnimation(keyPath: "transform.rotation.z")
            twitch.fromValue = 0
            twitch.toValue = CGFloat.pi / 40
            twitch.duration = 0.3
            twitch.autoreverses = true
            twitch.repeatCount = .greatestFiniteMagnitude
            twitch.beginTime = CACurrentMediaTime() + CFTimeInterval(index) * 1.5 + 2.0
            paw.add(twitch, forKey: "paw-twitch")
        }
    }
    
    private func addWalkCycle() {
        let bob = CABasicAnimation(keyPath: "transform.translation.y")
        bob.byValue = min(size.width, size.height) * 0.02
        bob.duration = 0.5
        bob.autoreverses = true
        bob.repeatCount = .greatestFiniteMagnitude
        petLayer.add(bob, forKey: "walk-bob")
        
        // Enhanced 3D paw movement - alternating front and back paws
        for (index, paw) in pawLayers.enumerated() {
            // Lift animation (up and down)
            let lift = CABasicAnimation(keyPath: "transform.translation.y")
            lift.byValue = min(size.width, size.height) * 0.05
            lift.duration = 0.5
            lift.autoreverses = true
            lift.repeatCount = .greatestFiniteMagnitude
            lift.beginTime = CACurrentMediaTime() + CFTimeInterval(index % 2) * 0.25
            lift.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            paw.add(lift, forKey: "paw-lift")
            
            // Rotation animation (forward and back swing)
            let swing = CABasicAnimation(keyPath: "transform.rotation.z")
            swing.fromValue = -CGFloat.pi / 20
            swing.toValue = CGFloat.pi / 20
            swing.duration = 0.5
            swing.autoreverses = true
            swing.repeatCount = .greatestFiniteMagnitude
            swing.beginTime = CACurrentMediaTime() + CFTimeInterval(index % 2) * 0.25
            swing.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            paw.add(swing, forKey: "paw-swing")
            
            // Scale animation (slight squash and stretch)
            let scale = CABasicAnimation(keyPath: "transform.scale")
            scale.fromValue = CATransform3DMakeScale(1.0, 1.0, 1.0)
            scale.toValue = CATransform3DMakeScale(1.1, 0.95, 1.0)
            scale.duration = 0.25
            scale.autoreverses = true
            scale.repeatCount = .greatestFiniteMagnitude
            scale.beginTime = CACurrentMediaTime() + CFTimeInterval(index % 2) * 0.25
            paw.add(scale, forKey: "paw-scale")
        }
        
        // Enhanced tail sway with more dynamic movement
        let tailSway = CABasicAnimation(keyPath: "transform.rotation.z")
        tailSway.fromValue = -CGFloat.pi / 25
        tailSway.toValue = CGFloat.pi / 25
        tailSway.duration = 0.5
        tailSway.autoreverses = true
        tailSway.repeatCount = .greatestFiniteMagnitude
        tailSway.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        tailLayer.add(tailSway, forKey: "tail-sway")
        
        // Add tail curl animation for more 3D effect
        let tailCurl = CABasicAnimation(keyPath: "transform.scale.x")
        tailCurl.fromValue = 0.95
        tailCurl.toValue = 1.05
        tailCurl.duration = 0.5
        tailCurl.autoreverses = true
        tailCurl.repeatCount = .greatestFiniteMagnitude
        tailLayer.add(tailCurl, forKey: "tail-curl")
    }
    
    private func addRunCycle() {
        let bob = CABasicAnimation(keyPath: "transform.translation.y")
        bob.byValue = min(size.width, size.height) * 0.04
        bob.duration = 0.25
        bob.autoreverses = true
        bob.repeatCount = .greatestFiniteMagnitude
        petLayer.add(bob, forKey: "run-bob")
        
        // Enhanced 3D paw movement for running - faster and more exaggerated
        for (index, paw) in pawLayers.enumerated() {
            // Faster lift
            let lift = CABasicAnimation(keyPath: "transform.translation.y")
            lift.byValue = min(size.width, size.height) * 0.07
            lift.duration = 0.2
            lift.autoreverses = true
            lift.repeatCount = .greatestFiniteMagnitude
            lift.beginTime = CACurrentMediaTime() + CFTimeInterval(index % 2) * 0.1
            lift.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            paw.add(lift, forKey: "paw-lift")
            
            // Faster swing
            let swing = CABasicAnimation(keyPath: "transform.rotation.z")
            swing.fromValue = -CGFloat.pi / 15
            swing.toValue = CGFloat.pi / 15
            swing.duration = 0.2
            swing.autoreverses = true
            swing.repeatCount = .greatestFiniteMagnitude
            swing.beginTime = CACurrentMediaTime() + CFTimeInterval(index % 2) * 0.1
            paw.add(swing, forKey: "paw-swing")
            
            // More pronounced squash and stretch
            let scale = CABasicAnimation(keyPath: "transform.scale")
            scale.fromValue = CATransform3DMakeScale(1.0, 1.0, 1.0)
            scale.toValue = CATransform3DMakeScale(1.15, 0.9, 1.0)
            scale.duration = 0.15
            scale.autoreverses = true
            scale.repeatCount = .greatestFiniteMagnitude
            scale.beginTime = CACurrentMediaTime() + CFTimeInterval(index % 2) * 0.1
            paw.add(scale, forKey: "paw-scale")
        }
        
        // Body lean forward
        let lean = CABasicAnimation(keyPath: "transform.rotation.z")
        lean.fromValue = -CGFloat.pi / 40
        lean.toValue = CGFloat.pi / 40
        lean.duration = 0.25
        lean.autoreverses = true
        lean.repeatCount = .greatestFiniteMagnitude
        bodyLayer.add(lean, forKey: "run-lean")
        
        // Tail streaming behind with more dynamic movement
        let tailStream = CABasicAnimation(keyPath: "transform.rotation.z")
        tailStream.fromValue = -CGFloat.pi / 20
        tailStream.toValue = CGFloat.pi / 20
        tailStream.duration = 0.2
        tailStream.autoreverses = true
        tailStream.repeatCount = .greatestFiniteMagnitude
        tailLayer.add(tailStream, forKey: "tail-stream")
        
        // Tail whip effect
        let tailWhip = CABasicAnimation(keyPath: "transform.scale.y")
        tailWhip.fromValue = 0.9
        tailWhip.toValue = 1.1
        tailWhip.duration = 0.2
        tailWhip.autoreverses = true
        tailWhip.repeatCount = .greatestFiniteMagnitude
        tailLayer.add(tailWhip, forKey: "tail-whip")
    }
    
    private func addSleepBreathing() {
        let breathe = CABasicAnimation(keyPath: "transform.scale.y")
        breathe.fromValue = 0.98
        breathe.toValue = 1.02
        breathe.duration = 2.0
        breathe.autoreverses = true
        breathe.repeatCount = .greatestFiniteMagnitude
        breathe.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        bodyLayer.add(breathe, forKey: "sleep-breathe")
    }
    
    private func addEatAnimation() {
        let chomp = CABasicAnimation(keyPath: "transform.scale")
        chomp.fromValue = CATransform3DIdentity
        chomp.toValue = CATransform3DMakeScale(1.05, 0.98, 1.0)
        chomp.duration = 0.4
        chomp.autoreverses = true
        chomp.repeatCount = .greatestFiniteMagnitude
        headLayer.add(chomp, forKey: "eat-chomp")
    }
    
    private func addPlayBounce() {
        let bounce = CABasicAnimation(keyPath: "transform.translation.y")
        bounce.byValue = min(size.width, size.height) * 0.06
        bounce.duration = 0.4
        bounce.autoreverses = true
        bounce.repeatCount = .greatestFiniteMagnitude
        bounce.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        petLayer.add(bounce, forKey: "play-bounce")
        
        // Ears perk up
        for ear in earLayers {
            let perk = CABasicAnimation(keyPath: "transform.rotation.z")
            perk.fromValue = 0
            perk.toValue = CGFloat.pi / 20
            perk.duration = 0.3
            perk.autoreverses = true
            perk.repeatCount = .greatestFiniteMagnitude
            ear.add(perk, forKey: "ear-perk")
        }
        
        // Paws reach out playfully with 3D effect
        for (index, paw) in pawLayers.enumerated() {
            let reach = CABasicAnimation(keyPath: "transform.translation.y")
            reach.byValue = min(size.width, size.height) * 0.04
            reach.duration = 0.4
            reach.autoreverses = true
            reach.repeatCount = .greatestFiniteMagnitude
            reach.beginTime = CACurrentMediaTime() + CFTimeInterval(index % 2) * 0.2
            paw.add(reach, forKey: "paw-reach")
            
            // Paw rotation for playful batting
            let bat = CABasicAnimation(keyPath: "transform.rotation.z")
            bat.fromValue = -CGFloat.pi / 25
            bat.toValue = CGFloat.pi / 25
            bat.duration = 0.3
            bat.autoreverses = true
            bat.repeatCount = .greatestFiniteMagnitude
            bat.beginTime = CACurrentMediaTime() + CFTimeInterval(index % 2) * 0.2
            paw.add(bat, forKey: "paw-bat")
        }
        
        // Tail up and wagging excitedly
        let tailWag = CABasicAnimation(keyPath: "transform.rotation.z")
        tailWag.fromValue = -CGFloat.pi / 15
        tailWag.toValue = CGFloat.pi / 15
        tailWag.duration = 0.3
        tailWag.autoreverses = true
        tailWag.repeatCount = .greatestFiniteMagnitude
        tailLayer.add(tailWag, forKey: "tail-wag")
        
        // Tail bounce
        let tailBounce = CABasicAnimation(keyPath: "transform.scale.y")
        tailBounce.fromValue = 0.95
        tailBounce.toValue = 1.05
        tailBounce.duration = 0.3
        tailBounce.autoreverses = true
        tailBounce.repeatCount = .greatestFiniteMagnitude
        tailLayer.add(tailBounce, forKey: "tail-bounce")
    }
    
    private func addSitAnimation() {
        // Gentle breathing while sitting
        let breathe = CABasicAnimation(keyPath: "transform.scale")
        breathe.fromValue = CATransform3DIdentity
        breathe.toValue = CATransform3DMakeScale(1.01, 1.01, 1.0)
        breathe.duration = 3.0
        breathe.autoreverses = true
        breathe.repeatCount = .greatestFiniteMagnitude
        bodyLayer.add(breathe, forKey: "sit-breathe")
    }
    
    private func addWatchAnimation() {
        // Slight head movement (curious)
        let headMove = CABasicAnimation(keyPath: "transform.rotation.z")
        headMove.fromValue = -CGFloat.pi / 80
        headMove.toValue = CGFloat.pi / 80
        headMove.duration = 2.0
        headMove.autoreverses = true
        headMove.repeatCount = .greatestFiniteMagnitude
        headLayer.add(headMove, forKey: "watch-move")
        
        // Ears forward
        for ear in earLayers {
            let perk = CABasicAnimation(keyPath: "transform.rotation.z")
            perk.fromValue = 0
            perk.toValue = CGFloat.pi / 30
            perk.duration = 1.5
            perk.autoreverses = true
            perk.repeatCount = .greatestFiniteMagnitude
            ear.add(perk, forKey: "ear-forward")
        }
    }
    
    private func addDanceAnimation() {
        let wiggle = CABasicAnimation(keyPath: "transform.rotation.z")
        wiggle.fromValue = -CGFloat.pi / 20
        wiggle.toValue = CGFloat.pi / 20
        wiggle.duration = 0.3
        wiggle.autoreverses = true
        wiggle.repeatCount = .greatestFiniteMagnitude
        petLayer.add(wiggle, forKey: "dance-wiggle")
        
        // Paws dancing with alternating lifts and rotations
        for (index, paw) in pawLayers.enumerated() {
            let lift = CABasicAnimation(keyPath: "transform.translation.y")
            lift.byValue = min(size.width, size.height) * 0.04
            lift.duration = 0.3
            lift.autoreverses = true
            lift.repeatCount = .greatestFiniteMagnitude
            lift.beginTime = CACurrentMediaTime() + CFTimeInterval(index % 2) * 0.15
            paw.add(lift, forKey: "paw-dance-lift")
            
            let spin = CABasicAnimation(keyPath: "transform.rotation.z")
            spin.fromValue = -CGFloat.pi / 18
            spin.toValue = CGFloat.pi / 18
            spin.duration = 0.3
            spin.autoreverses = true
            spin.repeatCount = .greatestFiniteMagnitude
            spin.beginTime = CACurrentMediaTime() + CFTimeInterval(index % 2) * 0.15
            paw.add(spin, forKey: "paw-dance-spin")
        }
        
        // Tail up and swishing dramatically
        let tailMove = CABasicAnimation(keyPath: "transform.rotation.z")
        tailMove.fromValue = -CGFloat.pi / 12
        tailMove.toValue = CGFloat.pi / 12
        tailMove.duration = 0.35
        tailMove.autoreverses = true
        tailMove.repeatCount = .greatestFiniteMagnitude
        tailLayer.add(tailMove, forKey: "tail-dance")
        
        // Tail wave effect (3D)
        let tailWave = CABasicAnimation(keyPath: "transform.scale.x")
        tailWave.fromValue = 0.9
        tailWave.toValue = 1.1
        tailWave.duration = 0.35
        tailWave.autoreverses = true
        tailWave.repeatCount = .greatestFiniteMagnitude
        tailLayer.add(tailWave, forKey: "tail-wave")
    }
    
    private func applyBlinkIfNeeded() {
        guard currentState != .sleeping else {
            // Eyes closed when sleeping
            for eye in eyeLayers {
                eye.removeAnimation(forKey: "blink")
                eye.transform = CATransform3DMakeScale(1.0, 0.1, 1.0)
            }
            return
        }
        
        for eye in eyeLayers {
            guard eye.animation(forKey: "blink") == nil else { continue }
            
            let blink = CAKeyframeAnimation(keyPath: "transform.scale.y")
            blink.values = [1.0, 0.1, 0.1, 1.0]
            blink.keyTimes = [0.0, 0.3, 0.5, 1.0]
            blink.duration = 0.2
            blink.repeatCount = .greatestFiniteMagnitude
            blink.beginTime = CACurrentMediaTime() + CFTimeInterval.random(in: 2.0...4.0)
            blink.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            eye.add(blink, forKey: "blink")
        }
    }
    
    // MARK: - Helper Functions
    
    private func createRoundedRectPath(rect: CGRect, cornerRadius: CGFloat) -> NSBezierPath {
        return NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    }
    
    private func createTrianglePath(center: CGPoint, size: CGSize, pointingUp: Bool) -> NSBezierPath {
        let path = NSBezierPath()
        if pointingUp {
            path.move(to: CGPoint(x: center.x, y: center.y + size.height / 2))
            path.line(to: CGPoint(x: center.x - size.width / 2, y: center.y - size.height / 2))
            path.line(to: CGPoint(x: center.x + size.width / 2, y: center.y - size.height / 2))
        } else {
            path.move(to: CGPoint(x: center.x, y: center.y - size.height / 2))
            path.line(to: CGPoint(x: center.x - size.width / 2, y: center.y + size.height / 2))
            path.line(to: CGPoint(x: center.x + size.width / 2, y: center.y + size.height / 2))
        }
        path.close()
        return path
    }
    
    
    func getLayer() -> CALayer {
        return petLayer
    }
    
    func interpolateColor(from: NSColor, to: NSColor, factor: Double) -> NSColor {
        let clampedFactor = max(0.0, min(1.0, factor))
        
        guard
            let fromRGB = from.usingColorSpace(.deviceRGB),
            let toRGB = to.usingColorSpace(.deviceRGB)
        else {
            return from.blended(withFraction: CGFloat(clampedFactor), of: to) ?? from
        }
        
        var fromRed: CGFloat = 0, fromGreen: CGFloat = 0, fromBlue: CGFloat = 0, fromAlpha: CGFloat = 0
        var toRed: CGFloat = 0, toGreen: CGFloat = 0, toBlue: CGFloat = 0, toAlpha: CGFloat = 0
        
        fromRGB.getRed(&fromRed, green: &fromGreen, blue: &fromBlue, alpha: &fromAlpha)
        toRGB.getRed(&toRed, green: &toGreen, blue: &toBlue, alpha: &toAlpha)
        
        return NSColor(
            red: fromRed + (toRed - fromRed) * CGFloat(clampedFactor),
            green: fromGreen + (toGreen - fromGreen) * CGFloat(clampedFactor),
            blue: fromBlue + (toBlue - fromBlue) * CGFloat(clampedFactor),
            alpha: fromAlpha + (toAlpha - fromAlpha) * CGFloat(clampedFactor)
        )
    }
}

// Extension to convert NSBezierPath to CGPath
extension NSBezierPath {
    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        
        for i in 0..<elementCount {
            let type = element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .cubicCurveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .quadraticCurveTo:
                path.addQuadCurve(to: points[1], control: points[0])
            case .closePath:
                path.closeSubpath()
            @unknown default:
                break
            }
        }
        
        return path
    }
}

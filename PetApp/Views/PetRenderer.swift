import Cocoa
import QuartzCore

private struct PetPalette {
    let base = NSColor(calibratedRed: 0.10, green: 0.63, blue: 0.73, alpha: 1.0) // teal
    let shadow = NSColor(calibratedRed: 0.06, green: 0.39, blue: 0.48, alpha: 1.0) // deep teal
    let highlight = NSColor(calibratedRed: 0.77, green: 0.90, blue: 0.94, alpha: 1.0) // pale aqua
    let accent = NSColor(calibratedRed: 0.94, green: 0.74, blue: 0.33, alpha: 1.0) // amber
    let blush = NSColor(calibratedRed: 0.92, green: 0.53, blue: 0.55, alpha: 1.0) // coral
    let eyeWhite = NSColor(calibratedWhite: 0.95, alpha: 1.0)
    let eyeDark = NSColor(calibratedWhite: 0.07, alpha: 1.0)
}

class PetRenderer {
    private var petLayer: CALayer
    private var bodyLayer: CAShapeLayer
    private var eyeLayers: [CAShapeLayer]
    private var pupilLayers: [CAShapeLayer]
    private var mouthLayer: CAShapeLayer
    private var armLayers: [CAShapeLayer]
    private var legLayers: [CAShapeLayer]
    private var accessoryLayers: [CAShapeLayer]
    private var cheekLayers: [CAShapeLayer]
    private let palette = PetPalette()
    private var pixelSize: CGFloat

    private var currentState: PetState = .idle
    private var currentHappiness: Double = 1.0
    
    init(size: CGSize) {
        petLayer = CALayer()
        petLayer.frame = CGRect(origin: .zero, size: size)
        pixelSize = max(1.0, floor(min(size.width, size.height) / 40.0))
        
        // Body layer (retro rounded block)
        bodyLayer = CAShapeLayer()
        bodyLayer.fillColor = palette.base.cgColor
        bodyLayer.strokeColor = palette.shadow.cgColor
        bodyLayer.lineWidth = 1.0
        petLayer.addSublayer(bodyLayer)
        
        // Arms (left and right)
        armLayers = []
        for _ in 0..<2 {
            let arm = CAShapeLayer()
            arm.fillColor = palette.base.cgColor
            arm.strokeColor = palette.shadow.cgColor
            arm.lineWidth = 1.0
            petLayer.addSublayer(arm)
            armLayers.append(arm)
        }
        
        // Legs (left and right)
        legLayers = []
        for _ in 0..<2 {
            let leg = CAShapeLayer()
            leg.fillColor = palette.base.cgColor
            leg.strokeColor = palette.shadow.cgColor
            leg.lineWidth = 1.0
            petLayer.addSublayer(leg)
            legLayers.append(leg)
        }
        
        // Eyes (with whites)
        eyeLayers = []
        for _ in 0..<2 {
            let eye = CAShapeLayer()
            eye.fillColor = palette.eyeWhite.cgColor
            petLayer.addSublayer(eye)
            eyeLayers.append(eye)
        }
        
        // Pupils (black dots in eyes)
        pupilLayers = []
        for _ in 0..<2 {
            let pupil = CAShapeLayer()
            pupil.fillColor = NSColor.black.cgColor
            petLayer.addSublayer(pupil)
            pupilLayers.append(pupil)
        }
        
        // Mouth
        mouthLayer = CAShapeLayer()
        mouthLayer.fillColor = NSColor.black.cgColor
        mouthLayer.strokeColor = NSColor.clear.cgColor
        petLayer.addSublayer(mouthLayer)
        
        // Cheeks (for happy expressions)
        cheekLayers = []
        for _ in 0..<2 {
            let cheek = CAShapeLayer()
            cheek.fillColor = NSColor.systemPink.withAlphaComponent(0.4).cgColor
            petLayer.addSublayer(cheek)
            cheekLayers.append(cheek)
        }
        
        // Accessories (for different states)
        accessoryLayers = []
        
        updateShape(size: size)
    }
    
    func updateShape(size: CGSize) {
        petLayer.frame = CGRect(origin: .zero, size: size)
        pixelSize = max(1.0, floor(min(size.width, size.height) / 40.0))
        
        let center = CGPoint(x: snap(size.width / 2), y: snap(size.height / 2))
        let bodyWidth = snap(min(size.width, size.height) * 0.55)
        let bodyHeight = snap(bodyWidth * 1.05)
        
        // Body (blocky capsule)
        let bodyRect = pixelRect(
            center: CGPoint(x: center.x, y: center.y + snap(bodyHeight * 0.05)),
            size: CGSize(width: bodyWidth, height: bodyHeight),
            corner: pixelSize * 2
        )
        bodyLayer.path = bodyRect.cgPath
        bodyLayer.frame = petLayer.bounds
        
        // Arms
        let armWidth = snap(bodyWidth * 0.18)
        let armHeight = snap(bodyHeight * 0.45)
        let armY = snap(center.y + bodyHeight * 0.05)
        
        let leftArmX = snap(center.x - bodyWidth / 2 - armWidth * 0.15)
        armLayers[0].path = pixelRect(
            center: CGPoint(x: leftArmX, y: armY),
            size: CGSize(width: armWidth, height: armHeight),
            corner: pixelSize
        ).cgPath
        armLayers[0].frame = petLayer.bounds
        
        let rightArmX = snap(center.x + bodyWidth / 2 - armWidth * 0.15)
        armLayers[1].path = pixelRect(
            center: CGPoint(x: rightArmX, y: armY),
            size: CGSize(width: armWidth, height: armHeight),
            corner: pixelSize
        ).cgPath
        armLayers[1].frame = petLayer.bounds
        
        // Legs
        let legWidth = snap(bodyWidth * 0.22)
        let legHeight = snap(bodyHeight * 0.32)
        let legY = snap(center.y + bodyHeight * 0.52)
        
        let leftLegX = snap(center.x - bodyWidth * 0.25)
        legLayers[0].path = pixelRect(
            center: CGPoint(x: leftLegX, y: legY),
            size: CGSize(width: legWidth, height: legHeight),
            corner: pixelSize
        ).cgPath
        legLayers[0].frame = petLayer.bounds
        
        let rightLegX = snap(center.x + bodyWidth * 0.25)
        legLayers[1].path = pixelRect(
            center: CGPoint(x: rightLegX, y: legY),
            size: CGSize(width: legWidth, height: legHeight),
            corner: pixelSize
        ).cgPath
        legLayers[1].frame = petLayer.bounds
        
        // Eyes
        let eyeSize = snap(bodyWidth * 0.16)
        let eyeY = snap(center.y - bodyHeight * 0.12)
        let eyeSpacing = snap(bodyWidth * 0.30)
        for (index, eye) in eyeLayers.enumerated() {
            let eyeX = center.x + (index == 0 ? -eyeSpacing / 2 : eyeSpacing / 2)
            let eyePath = pixelRect(
                center: CGPoint(x: eyeX, y: eyeY),
                size: CGSize(width: eyeSize, height: eyeSize),
                corner: pixelSize
            )
            eye.path = eyePath.cgPath
            eye.frame = petLayer.bounds
        }
        
        // Pupils
        let pupilSize = snap(eyeSize * 0.45)
        let watchOffset = currentState == .watching ? snap(eyeSize * 0.2) : 0
        for (index, pupil) in pupilLayers.enumerated() {
            let eyeX = center.x + (index == 0 ? -eyeSpacing / 2 : eyeSpacing / 2)
            let pupilX = eyeX + watchOffset
            let pupilPath = pixelRect(
                center: CGPoint(x: pupilX, y: eyeY),
                size: CGSize(width: pupilSize, height: pupilSize),
                corner: 0
            )
            pupil.path = pupilPath.cgPath
            pupil.frame = petLayer.bounds
            pupil.fillColor = palette.eyeDark.cgColor
        }
        
        // Mouth
        updateMouth(state: currentState, happiness: currentHappiness, center: center, bodyWidth: bodyWidth)
        
        // Cheeks
        let cheekSize = snap(bodyWidth * 0.10)
        let cheekY = snap(center.y - bodyHeight * 0.02)
        let cheekSpacing = snap(bodyWidth * 0.40)
        for (index, cheek) in cheekLayers.enumerated() {
            let cheekX = center.x + (index == 0 ? -cheekSpacing / 2 : cheekSpacing / 2)
            let cheekPath = pixelRect(
                center: CGPoint(x: cheekX, y: cheekY),
                size: CGSize(width: cheekSize, height: cheekSize),
                corner: 0
            )
            cheek.path = cheekPath.cgPath
            cheek.frame = petLayer.bounds
            cheek.opacity = currentHappiness > 0.65 ? 1.0 : 0.0
            cheek.fillColor = palette.blush.withAlphaComponent(0.8).cgColor
        }
        
        applyBlinkIfNeeded()
    }
    
    private func updateMouth(state: PetState, happiness: Double, center: CGPoint, bodyWidth: CGFloat) {
        let mouthY = snap(center.y - bodyWidth * 0.16)
        let mouthWidth = snap(bodyWidth * 0.22)
        let mouthHeight = max(pixelSize, snap(bodyWidth * 0.07))
        
        let baseRect = CGRect(
            x: center.x - mouthWidth / 2,
            y: mouthY - mouthHeight / 2,
            width: mouthWidth,
            height: mouthHeight
        )
        
        switch state {
        case .idle, .walking, .sitting, .running:
            if happiness > 0.5 {
                mouthLayer.path = pixelSmile(rect: baseRect, lift: pixelSize).cgPath
            } else {
                mouthLayer.path = pixelLine(rect: baseRect).cgPath
            }
            mouthLayer.fillColor = NSColor.clear.cgColor
            mouthLayer.strokeColor = palette.eyeDark.cgColor
            mouthLayer.lineWidth = 1.0
            
        case .eating:
            let biteRect = baseRect.insetBy(dx: -pixelSize * 0.4, dy: -pixelSize * 0.4)
            mouthLayer.path = NSBezierPath(ovalIn: biteRect).cgPath
            mouthLayer.fillColor = palette.eyeDark.cgColor
            mouthLayer.strokeColor = NSColor.clear.cgColor
            
        case .playing:
            mouthLayer.path = pixelSmile(rect: baseRect, lift: pixelSize * 1.2).cgPath
            mouthLayer.fillColor = NSColor.clear.cgColor
            mouthLayer.strokeColor = palette.accent.cgColor
            mouthLayer.lineWidth = 1.0
            
        case .dragging, .dropped:
            mouthLayer.path = pixelLine(rect: baseRect).cgPath
            mouthLayer.fillColor = NSColor.clear.cgColor
            mouthLayer.strokeColor = palette.eyeDark.withAlphaComponent(0.8).cgColor
            mouthLayer.lineWidth = 1.0
            
        case .dancing:
            mouthLayer.path = pixelSmile(rect: baseRect.insetBy(dx: -pixelSize, dy: -pixelSize * 0.3), lift: pixelSize * 1.5).cgPath
            mouthLayer.fillColor = NSColor.clear.cgColor
            mouthLayer.strokeColor = palette.accent.cgColor
            mouthLayer.lineWidth = 1.0
            
        case .watching:
            let oRect = baseRect.insetBy(dx: mouthWidth * 0.2, dy: -mouthHeight * 0.2)
            mouthLayer.path = NSBezierPath(ovalIn: oRect).cgPath
            mouthLayer.fillColor = palette.eyeDark.cgColor
            mouthLayer.strokeColor = NSColor.clear.cgColor
            
        case .sleeping:
            mouthLayer.path = pixelLine(rect: baseRect).cgPath
            mouthLayer.fillColor = NSColor.clear.cgColor
            mouthLayer.strokeColor = palette.shadow.withAlphaComponent(0.7).cgColor
            mouthLayer.lineWidth = 1.0
        }
        
        mouthLayer.frame = petLayer.bounds
    }
    
    func updateForState(_ state: PetState, age: Double, health: Double, happiness: Double) {
        currentState = state
        currentHappiness = happiness
        
        // Reset any cumulative transforms before applying new state-driven transforms
        petLayer.transform = CATransform3DIdentity
        
        // Update colors based on happiness with limited palette
        let bodyColor = interpolateColor(
            from: palette.shadow,
            to: palette.base,
            factor: max(0.15, happiness * 0.8)
        )
        let strokeColor = interpolateColor(
            from: palette.shadow,
            to: palette.highlight,
            factor: 0.15
        )
        
        bodyLayer.fillColor = bodyColor.cgColor
        bodyLayer.strokeColor = strokeColor.cgColor
        
        for arm in armLayers {
            arm.fillColor = bodyColor.cgColor
            arm.strokeColor = strokeColor.cgColor
        }
        
        for leg in legLayers {
            leg.fillColor = bodyColor.cgColor
            leg.strokeColor = strokeColor.cgColor
        }
        
        // Keep size fixed - no dimension changes
        // All states render at the same consistent size
        petLayer.transform = CATransform3DIdentity
        
        // Update accessories for state
        updateAccessories(state: state, center: CGPoint(x: petLayer.bounds.midX, y: petLayer.bounds.midY))
        
        // Update shape to refresh mouth and pupils
        updateShape(size: petLayer.bounds.size)
        applyStateAnimations(for: state)
    }
    
    private func updateAccessories(state: PetState, center: CGPoint) {
        // Remove old accessories
        accessoryLayers.forEach { $0.removeFromSuperlayer() }
        accessoryLayers.removeAll()
        
        switch state {
        case .dancing:
            // Music notes
            addMusicNoteAccessories(center: center)
            // Add hearts when very happy
            if currentHappiness > 0.8 {
                addHeartAccessories(center: center)
            }
            
        case .sleeping:
            // Zzz bubbles
            addSleepAccessories(center: center)
            // Add cozy blanket/pillow
            addSleepComfortAccessory(center: center)
            
        case .watching:
            // Sparkle/star effects
            addWatchAccessories(center: center)
            // Add curious sparkles
            addCuriousSparkles(center: center)
            
        case .running:
            addRunTrailAccessories(center: center)
            // Add speed lines
            addSpeedLines(center: center)
            
        case .eating:
            addFoodBowlAccessory(center: center)
            // Add yummy hearts
            if currentHappiness > 0.7 {
                addHeartAccessories(center: center, count: 2)
            }
            
        case .playing:
            addPlayAccessory(center: center)
            // Add playful sparkles
            addPlayfulSparkles(center: center)
            // Add happy hearts if very happy
            if currentHappiness > 0.85 {
                addHeartAccessories(center: center, count: 3)
            }
            
        case .dropped:
            addLandingAccessory(center: center)
            // Add stars around head (dizzy effect)
            addDizzyStars(center: center)
            
        case .idle:
            // Occasionally show happy accessories when idle and happy
            if currentHappiness > 0.75 && Double.random(in: 0...1) < 0.3 {
                addIdleHappyAccessory(center: center)
            }
            
        case .sitting:
            // Add a cute hat or accessory when sitting
            if currentHappiness > 0.7 {
                addSittingAccessory(center: center)
            }
            
        case .walking:
            // Occasionally show a trail of sparkles when happy
            if currentHappiness > 0.8 && Double.random(in: 0...1) < 0.2 {
                addWalkingSparkles(center: center)
            }
            
        default:
            break
        }
    }
    
    private func addMusicNoteAccessories(center: CGPoint) {
        let noteSize = snap(pixelSize * 4)
        let spacing = snap(pixelSize * 8)
        for i in 0..<3 {
            let note = CAShapeLayer()
            let noteX = snap(center.x - spacing + CGFloat(i) * spacing)
            let noteY = snap(center.y + pixelSize * 12 + CGFloat(i))
            
            // 8-bit note: square head + stem
            let head = pixelRect(
                center: CGPoint(x: noteX, y: noteY),
                size: CGSize(width: noteSize, height: noteSize),
                corner: 0
            )
            let stem = NSBezierPath()
            stem.move(to: CGPoint(x: noteX + noteSize / 2, y: noteY))
            stem.line(to: CGPoint(x: noteX + noteSize / 2, y: noteY + noteSize * 1.5))
            
            head.append(stem)
            note.path = head.cgPath
            note.fillColor = palette.accent.cgColor
            note.strokeColor = palette.eyeDark.cgColor
            note.lineWidth = 1.0
            note.frame = petLayer.bounds
            petLayer.addSublayer(note)
            accessoryLayers.append(note)
        }
    }
    
    private func addSleepAccessories(center: CGPoint) {
        let zSize = snap(pixelSize * 4)
        let spacing = snap(pixelSize * 6)
        for i in 0..<3 {
            let zzz = CAShapeLayer()
            let zzzX = snap(center.x + pixelSize * 14 + CGFloat(i) * spacing)
            let zzzY = snap(center.y + pixelSize * 10 - CGFloat(i) * pixelSize * 2)
            
            let zPath = NSBezierPath()
            zPath.move(to: CGPoint(x: zzzX - zSize, y: zzzY + zSize))
            zPath.line(to: CGPoint(x: zzzX + zSize, y: zzzY + zSize))
            zPath.line(to: CGPoint(x: zzzX - zSize, y: zzzY - zSize))
            zPath.line(to: CGPoint(x: zzzX + zSize, y: zzzY - zSize))
            zPath.lineWidth = 1.0
            
            zzz.path = zPath.cgPath
            zzz.fillColor = NSColor.clear.cgColor
            zzz.strokeColor = palette.highlight.withAlphaComponent(0.7).cgColor
            zzz.frame = petLayer.bounds
            zzz.opacity = 0.65 - Float(i) * 0.15
            petLayer.addSublayer(zzz)
            accessoryLayers.append(zzz)
        }
    }
    
    private func addWatchAccessories(center: CGPoint) {
        let starSize = snap(pixelSize * 3)
        for i in 0..<4 {
            let star = CAShapeLayer()
            let angle = Double(i) * .pi * 2.0 / 4.0
            let radius = snap(pixelSize * 12)
            let starX = snap(center.x + CGFloat(cos(angle)) * radius)
            let starY = snap(center.y + pixelSize * 14 + CGFloat(sin(angle)) * radius * 0.5)
            
            let starPath = NSBezierPath()
            starPath.move(to: CGPoint(x: starX, y: starY - starSize))
            starPath.line(to: CGPoint(x: starX + starSize, y: starY))
            starPath.line(to: CGPoint(x: starX, y: starY + starSize))
            starPath.line(to: CGPoint(x: starX - starSize, y: starY))
            starPath.close()
            
            star.path = starPath.cgPath
            star.fillColor = palette.highlight.withAlphaComponent(0.85).cgColor
            star.strokeColor = palette.eyeDark.withAlphaComponent(0.4).cgColor
            star.frame = petLayer.bounds
            star.opacity = 0.55 + Float(i) * 0.1
            petLayer.addSublayer(star)
            accessoryLayers.append(star)
        }
    }
    
    private func addRunTrailAccessories(center: CGPoint) {
        let puffSize = snap(pixelSize * 3)
        for i in 0..<2 {
            let puff = CAShapeLayer()
            let xOffset = snap(-pixelSize * 10 - CGFloat(i) * pixelSize * 4)
            let yOffset = snap(pixelSize * 10 - CGFloat(i) * pixelSize * 2)
            let puffRect = pixelRect(
                center: CGPoint(x: center.x + xOffset, y: center.y + yOffset),
                size: CGSize(width: puffSize, height: puffSize * 0.8),
                corner: pixelSize
            )
            puff.path = puffRect.cgPath
            puff.fillColor = palette.shadow.withAlphaComponent(0.25).cgColor
            puff.strokeColor = NSColor.clear.cgColor
            puff.frame = petLayer.bounds
            
            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = 0.7
            fade.toValue = 0.0
            fade.duration = 0.6
            fade.repeatCount = .greatestFiniteMagnitude
            fade.beginTime = CACurrentMediaTime() + CFTimeInterval(0.1 * Double(i))
            puff.add(fade, forKey: "dust-fade")
            
            petLayer.addSublayer(puff)
            accessoryLayers.append(puff)
        }
    }
    
    private func addFoodBowlAccessory(center: CGPoint) {
        let bowlWidth = snap(pixelSize * 12)
        let bowlHeight = snap(pixelSize * 4)
        let bowl = CAShapeLayer()
        let bowlCenter = CGPoint(x: center.x, y: center.y + pixelSize * 14)
        let bowlRect = pixelRect(
            center: bowlCenter,
            size: CGSize(width: bowlWidth, height: bowlHeight),
            corner: pixelSize
        )
        bowl.path = bowlRect.cgPath
        bowl.fillColor = palette.accent.withAlphaComponent(0.9).cgColor
        bowl.strokeColor = palette.eyeDark.cgColor
        bowl.lineWidth = 1.0
        bowl.frame = petLayer.bounds
        
        let food = CAShapeLayer()
        let foodRect = pixelRect(
            center: CGPoint(x: bowlCenter.x, y: bowlCenter.y + bowlHeight * 0.6),
            size: CGSize(width: bowlWidth * 0.7, height: bowlHeight * 0.6),
            corner: pixelSize * 0.5
        )
        food.path = foodRect.cgPath
        food.fillColor = palette.shadow.withAlphaComponent(0.7).cgColor
        food.strokeColor = NSColor.clear.cgColor
        food.frame = petLayer.bounds
        
        petLayer.addSublayer(bowl)
        petLayer.addSublayer(food)
        accessoryLayers.append(contentsOf: [bowl, food])
    }
    
    private func addPlayAccessory(center: CGPoint) {
        let ballSize = snap(pixelSize * 5)
        let ball = CAShapeLayer()
        let ballCenter = CGPoint(x: center.x + pixelSize * 10, y: center.y + pixelSize * 10)
        let ballRect = pixelRect(
            center: ballCenter,
            size: CGSize(width: ballSize, height: ballSize),
            corner: ballSize / 2
        )
        ball.path = ballRect.cgPath
        ball.fillColor = palette.accent.cgColor
        ball.strokeColor = palette.eyeDark.cgColor
        ball.lineWidth = 1.0
        ball.frame = petLayer.bounds
        
        let bounce = CABasicAnimation(keyPath: "position.y")
        bounce.byValue = pixelSize * 2
        bounce.duration = 0.6
        bounce.autoreverses = true
        bounce.repeatCount = .greatestFiniteMagnitude
        ball.add(bounce, forKey: "toy-bounce")
        
        petLayer.addSublayer(ball)
        accessoryLayers.append(ball)
    }
    
    private func addLandingAccessory(center: CGPoint) {
        let pillowWidth = snap(pixelSize * 14)
        let pillowHeight = snap(pixelSize * 6)
        let pillow = CAShapeLayer()
        let pillowRect = pixelRect(
            center: CGPoint(x: center.x, y: center.y + pixelSize * 14),
            size: CGSize(width: pillowWidth, height: pillowHeight),
            corner: pixelSize * 1.2
        )
        pillow.path = pillowRect.cgPath
        pillow.fillColor = palette.highlight.withAlphaComponent(0.7).cgColor
        pillow.strokeColor = palette.eyeDark.withAlphaComponent(0.3).cgColor
        pillow.frame = petLayer.bounds
        
        let settle = CABasicAnimation(keyPath: "transform.scale")
        settle.fromValue = CATransform3DMakeScale(1.05, 0.95, 1.0)
        settle.toValue = CATransform3DIdentity
        settle.duration = 0.35
        settle.autoreverses = true
        pillow.add(settle, forKey: "pillow-settle")
        
        petLayer.addSublayer(pillow)
        accessoryLayers.append(pillow)
    }
    
    private func addHeartAccessories(center: CGPoint, count: Int = 4) {
        let heartSize = snap(pixelSize * 3)
        for i in 0..<count {
            let heart = CAShapeLayer()
            let angle = Double(i) * .pi * 2.0 / Double(count)
            let radius = snap(pixelSize * 10 + CGFloat(i) * pixelSize * 2)
            let heartX = snap(center.x + CGFloat(cos(angle)) * radius)
            let heartY = snap(center.y - pixelSize * 12 + CGFloat(sin(angle)) * radius * 0.6)
            
            // Simple heart shape (pixelated style)
            let heartPath = NSBezierPath()
            let topLeft = CGPoint(x: heartX - heartSize * 0.5, y: heartY + heartSize * 0.3)
            let topRight = CGPoint(x: heartX + heartSize * 0.5, y: heartY + heartSize * 0.3)
            let bottom = CGPoint(x: heartX, y: heartY - heartSize * 0.5)
            
            // Create a simple heart using rounded rectangles and triangle
            // Left rounded part
            let leftCircle = NSBezierPath(roundedRect: CGRect(
                x: topLeft.x - heartSize * 0.4,
                y: topLeft.y - heartSize * 0.2,
                width: heartSize * 0.8,
                height: heartSize * 0.8
            ), xRadius: heartSize * 0.4, yRadius: heartSize * 0.4)
            heartPath.append(leftCircle)
            
            // Right rounded part
            let rightCircle = NSBezierPath(roundedRect: CGRect(
                x: topRight.x - heartSize * 0.4,
                y: topRight.y - heartSize * 0.2,
                width: heartSize * 0.8,
                height: heartSize * 0.8
            ), xRadius: heartSize * 0.4, yRadius: heartSize * 0.4)
            heartPath.append(rightCircle)
            
            // Triangle bottom
            heartPath.move(to: topLeft)
            heartPath.line(to: topRight)
            heartPath.line(to: bottom)
            heartPath.close()
            
            heart.path = heartPath.cgPath
            heart.fillColor = palette.blush.cgColor
            heart.strokeColor = palette.eyeDark.withAlphaComponent(0.3).cgColor
            heart.lineWidth = 0.5
            heart.frame = petLayer.bounds
            
            // Float animation
            let float = CABasicAnimation(keyPath: "transform.translation.y")
            float.byValue = pixelSize * 2
            float.duration = 1.0 + Double(i) * 0.2
            float.autoreverses = true
            float.repeatCount = .greatestFiniteMagnitude
            float.beginTime = CACurrentMediaTime() + CFTimeInterval(i) * 0.1
            heart.add(float, forKey: "heart-float")
            
            // Fade in/out
            let pulse = CABasicAnimation(keyPath: "opacity")
            pulse.fromValue = 0.6
            pulse.toValue = 1.0
            pulse.duration = 1.5
            pulse.autoreverses = true
            pulse.repeatCount = .greatestFiniteMagnitude
            heart.add(pulse, forKey: "heart-pulse")
            
            petLayer.addSublayer(heart)
            accessoryLayers.append(heart)
        }
    }
    
    private func addCuriousSparkles(center: CGPoint) {
        let sparkleCount = 6
        for i in 0..<sparkleCount {
            let sparkle = CAShapeLayer()
            let angle = Double(i) * .pi * 2.0 / Double(sparkleCount)
            let radius = snap(pixelSize * 14)
            let sparkleX = snap(center.x + CGFloat(cos(angle)) * radius)
            let sparkleY = snap(center.y + pixelSize * 14 + CGFloat(sin(angle)) * radius * 0.5)
            
            let sparkleSize = snap(pixelSize * 2)
            let sparklePath = NSBezierPath()
            // Create a cross/star shape
            sparklePath.move(to: CGPoint(x: sparkleX, y: sparkleY - sparkleSize))
            sparklePath.line(to: CGPoint(x: sparkleX, y: sparkleY + sparkleSize))
            sparklePath.move(to: CGPoint(x: sparkleX - sparkleSize, y: sparkleY))
            sparklePath.line(to: CGPoint(x: sparkleX + sparkleSize, y: sparkleY))
            
            sparkle.path = sparklePath.cgPath
            sparkle.strokeColor = palette.accent.cgColor
            sparkle.lineWidth = 1.0
            sparkle.frame = petLayer.bounds
            
            // Rotate animation
            let rotate = CABasicAnimation(keyPath: "transform.rotation.z")
            rotate.fromValue = 0
            rotate.toValue = CGFloat.pi * 2
            rotate.duration = 2.0
            rotate.repeatCount = .greatestFiniteMagnitude
            rotate.beginTime = CACurrentMediaTime() + CFTimeInterval(i) * 0.1
            sparkle.add(rotate, forKey: "sparkle-rotate")
            
            // Pulse
            let pulse = CABasicAnimation(keyPath: "opacity")
            pulse.fromValue = 0.4
            pulse.toValue = 1.0
            pulse.duration = 1.0
            pulse.autoreverses = true
            pulse.repeatCount = .greatestFiniteMagnitude
            sparkle.add(pulse, forKey: "sparkle-pulse")
            
            petLayer.addSublayer(sparkle)
            accessoryLayers.append(sparkle)
        }
    }
    
    private func addPlayfulSparkles(center: CGPoint) {
        let sparkleCount = 4
        for i in 0..<sparkleCount {
            let sparkle = CAShapeLayer()
            let angle = Double(i) * .pi * 2.0 / Double(sparkleCount) + .pi / 4
            let radius = snap(pixelSize * 12)
            let sparkleX = snap(center.x + CGFloat(cos(angle)) * radius)
            let sparkleY = snap(center.y + pixelSize * 12 + CGFloat(sin(angle)) * radius * 0.5)
            
            let sparkleSize = snap(pixelSize * 2.5)
            let sparkleRect = pixelRect(
                center: CGPoint(x: sparkleX, y: sparkleY),
                size: CGSize(width: sparkleSize, height: sparkleSize),
                corner: 0
            )
            sparkle.path = sparkleRect.cgPath
            sparkle.fillColor = palette.highlight.cgColor
            sparkle.strokeColor = palette.accent.cgColor
            sparkle.lineWidth = 0.5
            sparkle.frame = petLayer.bounds
            
            // Bounce animation
            let bounce = CABasicAnimation(keyPath: "transform.scale")
            bounce.fromValue = 0.5
            bounce.toValue = 1.2
            bounce.duration = 0.6
            bounce.autoreverses = true
            bounce.repeatCount = .greatestFiniteMagnitude
            bounce.beginTime = CACurrentMediaTime() + CFTimeInterval(i) * 0.15
            sparkle.add(bounce, forKey: "playful-bounce")
            
            petLayer.addSublayer(sparkle)
            accessoryLayers.append(sparkle)
        }
    }
    
    private func addSpeedLines(center: CGPoint) {
        let lineCount = 3
        for i in 0..<lineCount {
            let line = CAShapeLayer()
            let xOffset = snap(-pixelSize * 12 - CGFloat(i) * pixelSize * 3)
            let yOffset = snap(pixelSize * 8 - CGFloat(i) * pixelSize * 1.5)
            
            let linePath = NSBezierPath()
            linePath.move(to: CGPoint(x: center.x + xOffset, y: center.y + yOffset))
            linePath.line(to: CGPoint(x: center.x + xOffset - pixelSize * 4, y: center.y + yOffset))
            
            line.path = linePath.cgPath
            line.strokeColor = palette.shadow.withAlphaComponent(0.4).cgColor
            line.lineWidth = 1.0
            line.frame = petLayer.bounds
            
            // Fade out animation
            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = 0.8
            fade.toValue = 0.0
            fade.duration = 0.4
            fade.repeatCount = .greatestFiniteMagnitude
            fade.beginTime = CACurrentMediaTime() + CFTimeInterval(i) * 0.1
            line.add(fade, forKey: "speed-fade")
            
            petLayer.addSublayer(line)
            accessoryLayers.append(line)
        }
    }
    
    private func addDizzyStars(center: CGPoint) {
        let starCount = 3
        for i in 0..<starCount {
            let star = CAShapeLayer()
            let angle = Double(i) * .pi * 2.0 / Double(starCount)
            let radius = snap(pixelSize * 8)
            let starX = snap(center.x + CGFloat(cos(angle)) * radius)
            let starY = snap(center.y - pixelSize * 10 + CGFloat(sin(angle)) * radius)
            
            let starSize = snap(pixelSize * 2.5)
            let starPath = NSBezierPath()
            starPath.move(to: CGPoint(x: starX, y: starY - starSize))
            starPath.line(to: CGPoint(x: starX + starSize, y: starY))
            starPath.line(to: CGPoint(x: starX, y: starY + starSize))
            starPath.line(to: CGPoint(x: starX - starSize, y: starY))
            starPath.close()
            
            star.path = starPath.cgPath
            star.fillColor = palette.accent.withAlphaComponent(0.7).cgColor
            star.strokeColor = palette.eyeDark.withAlphaComponent(0.5).cgColor
            star.lineWidth = 0.5
            star.frame = petLayer.bounds
            
            // Rotate and fade
            let rotate = CABasicAnimation(keyPath: "transform.rotation.z")
            rotate.fromValue = 0
            rotate.toValue = CGFloat.pi * 2
            rotate.duration = 1.0
            rotate.repeatCount = .greatestFiniteMagnitude
            star.add(rotate, forKey: "star-rotate")
            
            let pulse = CABasicAnimation(keyPath: "opacity")
            pulse.fromValue = 0.5
            pulse.toValue = 1.0
            pulse.duration = 0.8
            pulse.autoreverses = true
            pulse.repeatCount = .greatestFiniteMagnitude
            star.add(pulse, forKey: "star-pulse")
            
            petLayer.addSublayer(star)
            accessoryLayers.append(star)
        }
    }
    
    private func addIdleHappyAccessory(center: CGPoint) {
        // Add a small floating heart or sparkle when idle and happy
        if Double.random(in: 0...1) < 0.5 {
            addHeartAccessories(center: center, count: 1)
        } else {
            let sparkle = CAShapeLayer()
            let sparkleX = snap(center.x + pixelSize * 8)
            let sparkleY = snap(center.y - pixelSize * 10)
            let sparkleSize = snap(pixelSize * 2)
            
            let sparklePath = NSBezierPath()
            sparklePath.move(to: CGPoint(x: sparkleX, y: sparkleY - sparkleSize))
            sparklePath.line(to: CGPoint(x: sparkleX, y: sparkleY + sparkleSize))
            sparklePath.move(to: CGPoint(x: sparkleX - sparkleSize, y: sparkleY))
            sparklePath.line(to: CGPoint(x: sparkleX + sparkleSize, y: sparkleY))
            
            sparkle.path = sparklePath.cgPath
            sparkle.strokeColor = palette.accent.cgColor
            sparkle.lineWidth = 1.0
            sparkle.frame = petLayer.bounds
            
            let rotate = CABasicAnimation(keyPath: "transform.rotation.z")
            rotate.fromValue = 0
            rotate.toValue = CGFloat.pi * 2
            rotate.duration = 2.0
            rotate.repeatCount = .greatestFiniteMagnitude
            sparkle.add(rotate, forKey: "idle-sparkle")
            
            petLayer.addSublayer(sparkle)
            accessoryLayers.append(sparkle)
        }
    }
    
    private func addSittingAccessory(center: CGPoint) {
        // Add a cute hat when sitting
        let hat = CAShapeLayer()
        let hatWidth = snap(pixelSize * 10)
        let hatHeight = snap(pixelSize * 4)
        let hatY = snap(center.y - pixelSize * 18)
        
        // Hat brim
        let brimRect = pixelRect(
            center: CGPoint(x: center.x, y: hatY),
            size: CGSize(width: hatWidth, height: pixelSize * 1.5),
            corner: pixelSize * 0.5
        )
        
        // Hat top
        let topRect = pixelRect(
            center: CGPoint(x: center.x, y: hatY - hatHeight * 0.5),
            size: CGSize(width: hatWidth * 0.6, height: hatHeight),
            corner: pixelSize * 0.5
        )
        
        let hatPath = NSBezierPath()
        hatPath.append(brimRect)
        hatPath.append(topRect)
        
        hat.path = hatPath.cgPath
        hat.fillColor = palette.accent.cgColor
        hat.strokeColor = palette.eyeDark.cgColor
        hat.lineWidth = 0.5
        hat.frame = petLayer.bounds
        
        // Gentle bob
        let bob = CABasicAnimation(keyPath: "transform.translation.y")
        bob.byValue = pixelSize * 0.5
        bob.duration = 2.0
        bob.autoreverses = true
        bob.repeatCount = .greatestFiniteMagnitude
        hat.add(bob, forKey: "hat-bob")
        
        petLayer.addSublayer(hat)
        accessoryLayers.append(hat)
    }
    
    private func addSleepComfortAccessory(center: CGPoint) {
        // Add a cozy blanket
        let blanket = CAShapeLayer()
        let blanketWidth = snap(pixelSize * 16)
        let blanketHeight = snap(pixelSize * 8)
        let blanketRect = pixelRect(
            center: CGPoint(x: center.x, y: center.y + pixelSize * 16),
            size: CGSize(width: blanketWidth, height: blanketHeight),
            corner: pixelSize * 1.5
        )
        blanket.path = blanketRect.cgPath
        blanket.fillColor = palette.highlight.withAlphaComponent(0.6).cgColor
        blanket.strokeColor = palette.shadow.withAlphaComponent(0.3).cgColor
        blanket.lineWidth = 1.0
        blanket.frame = petLayer.bounds
        
        // Gentle breathing animation
        let breathe = CABasicAnimation(keyPath: "transform.scale.y")
        breathe.fromValue = 0.98
        breathe.toValue = 1.02
        breathe.duration = 2.5
        breathe.autoreverses = true
        breathe.repeatCount = .greatestFiniteMagnitude
        blanket.add(breathe, forKey: "blanket-breathe")
        
        petLayer.addSublayer(blanket)
        accessoryLayers.append(blanket)
    }
    
    private func addWalkingSparkles(center: CGPoint) {
        // Add sparkles trailing behind when walking happily
        let sparkleCount = 2
        for i in 0..<sparkleCount {
            let sparkle = CAShapeLayer()
            let xOffset = snap(-pixelSize * 8 - CGFloat(i) * pixelSize * 3)
            let yOffset = snap(pixelSize * 6 - CGFloat(i) * pixelSize * 2)
            
            let sparkleSize = snap(pixelSize * 1.5)
            let sparkleRect = pixelRect(
                center: CGPoint(x: center.x + xOffset, y: center.y + yOffset),
                size: CGSize(width: sparkleSize, height: sparkleSize),
                corner: 0
            )
            sparkle.path = sparkleRect.cgPath
            sparkle.fillColor = palette.highlight.withAlphaComponent(0.8).cgColor
            sparkle.frame = petLayer.bounds
            
            // Fade out
            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = 1.0
            fade.toValue = 0.0
            fade.duration = 0.8
            fade.repeatCount = .greatestFiniteMagnitude
            fade.beginTime = CACurrentMediaTime() + CFTimeInterval(i) * 0.2
            sparkle.add(fade, forKey: "walk-sparkle-fade")
            
            petLayer.addSublayer(sparkle)
            accessoryLayers.append(sparkle)
        }
    }
    
    private func applyStateAnimations(for state: PetState) {
        clearStateAnimations()
        
        switch state {
        case .idle:
            addIdleFloat()
            
        case .walking:
            addWalkCycle()
            
        case .running:
            addRunCycle()
            
        case .sleeping:
            addSleepBreathe()
            
        case .eating:
            addEatCycle()
            
        case .playing:
            addPlayBounce()
            
        case .dragging:
            addDragStretch()
            
        case .dropped:
            addDropSquash()
            
        case .dancing, .watching, .sitting:
            // Keep existing blink/accessories; no extra body animation needed
            break
        }
    }
    
    private func clearStateAnimations() {
        let layersToClear: [CALayer] = [petLayer, bodyLayer, mouthLayer] + armLayers + legLayers + accessoryLayers
        layersToClear.forEach { $0.removeAllAnimations() }
        // Reapply blink after clearing animations (but don't remove blink animation itself)
        // The blink will be reapplied in updateShape which is called after this
    }
    
    private func addIdleFloat() {
        let float = CABasicAnimation(keyPath: "transform.translation.y")
        float.byValue = pixelSize * 1.2
        float.duration = 2.2
        float.autoreverses = true
        float.repeatCount = .greatestFiniteMagnitude
        float.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        petLayer.add(float, forKey: "idle-float")
    }
    
    private func addWalkCycle() {
        let bob = CABasicAnimation(keyPath: "transform.translation.y")
        bob.byValue = pixelSize * 0.8
        bob.duration = 0.45
        bob.autoreverses = true
        bob.repeatCount = .greatestFiniteMagnitude
        petLayer.add(bob, forKey: "walk-bob")
        
        let armSwing = CABasicAnimation(keyPath: "transform.rotation.z")
        armSwing.fromValue = -CGFloat.pi / 16
        armSwing.toValue = CGFloat.pi / 16
        armSwing.duration = 0.4
        armSwing.autoreverses = true
        armSwing.repeatCount = .greatestFiniteMagnitude
        armLayers[0].add(armSwing, forKey: "arm-swing-left")
        
        let armSwingRight = armSwing.copy() as! CABasicAnimation
        armSwingRight.timeOffset = armSwing.duration / 2
        armLayers[1].add(armSwingRight, forKey: "arm-swing-right")
        
        let legSwing = CABasicAnimation(keyPath: "transform.rotation.z")
        legSwing.fromValue = CGFloat.pi / 18
        legSwing.toValue = -CGFloat.pi / 18
        legSwing.duration = 0.45
        legSwing.autoreverses = true
        legSwing.repeatCount = .greatestFiniteMagnitude
        legLayers[0].add(legSwing, forKey: "leg-swing-left")
        
        let legSwingRight = legSwing.copy() as! CABasicAnimation
        legSwingRight.timeOffset = legSwing.duration / 2
        legLayers[1].add(legSwingRight, forKey: "leg-swing-right")
    }
    
    private func addRunCycle() {
        let lean = CABasicAnimation(keyPath: "transform.rotation.z")
        lean.fromValue = -CGFloat.pi / 36
        lean.toValue = CGFloat.pi / 36
        lean.duration = 0.28
        lean.autoreverses = true
        lean.repeatCount = .greatestFiniteMagnitude
        petLayer.add(lean, forKey: "run-lean")
        
        let bob = CABasicAnimation(keyPath: "transform.translation.y")
        bob.byValue = pixelSize
        bob.duration = 0.25
        bob.autoreverses = true
        bob.repeatCount = .greatestFiniteMagnitude
        petLayer.add(bob, forKey: "run-bob")
        
        let fastSwing = CABasicAnimation(keyPath: "transform.rotation.z")
        fastSwing.fromValue = -CGFloat.pi / 12
        fastSwing.toValue = CGFloat.pi / 12
        fastSwing.duration = 0.22
        fastSwing.autoreverses = true
        fastSwing.repeatCount = .greatestFiniteMagnitude
        armLayers.forEach { $0.add(fastSwing, forKey: "run-arm") }
        legLayers.forEach { $0.add(fastSwing, forKey: "run-leg") }
    }
    
    private func addSleepBreathe() {
        let breathe = CABasicAnimation(keyPath: "transform.scale.y")
        breathe.fromValue = 0.98
        breathe.toValue = 1.02
        breathe.duration = 2.5
        breathe.autoreverses = true
        breathe.repeatCount = .greatestFiniteMagnitude
        breathe.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        bodyLayer.add(breathe, forKey: "sleep-breathe")
    }
    
    private func addEatCycle() {
        let chomp = CABasicAnimation(keyPath: "transform.scale.x")
        chomp.fromValue = 0.9
        chomp.toValue = 1.1
        chomp.duration = 0.35
        chomp.autoreverses = true
        chomp.repeatCount = .greatestFiniteMagnitude
        mouthLayer.add(chomp, forKey: "eat-chomp")
        
        let cheekPulse = CABasicAnimation(keyPath: "opacity")
        cheekPulse.fromValue = 0.4
        cheekPulse.toValue = 0.9
        cheekPulse.duration = 0.5
        cheekPulse.autoreverses = true
        cheekPulse.repeatCount = .greatestFiniteMagnitude
        cheekLayers.forEach { $0.add(cheekPulse, forKey: "cheek-pulse") }
    }
    
    private func addPlayBounce() {
        let bounce = CABasicAnimation(keyPath: "transform.translation.y")
        bounce.byValue = pixelSize * 1.5
        bounce.duration = 0.5
        bounce.autoreverses = true
        bounce.repeatCount = .greatestFiniteMagnitude
        petLayer.add(bounce, forKey: "play-bounce")
        
        let wiggle = CABasicAnimation(keyPath: "transform.rotation.z")
        wiggle.fromValue = -CGFloat.pi / 40
        wiggle.toValue = CGFloat.pi / 40
        wiggle.duration = 0.35
        wiggle.autoreverses = true
        wiggle.repeatCount = .greatestFiniteMagnitude
        bodyLayer.add(wiggle, forKey: "play-wiggle")
    }
    
    private func addDragStretch() {
        let stretch = CABasicAnimation(keyPath: "transform.scale")
        stretch.fromValue = CATransform3DIdentity
        stretch.toValue = CATransform3DMakeScale(1.08, 0.92, 1.0)
        stretch.duration = 0.25
        stretch.autoreverses = true
        stretch.repeatCount = .greatestFiniteMagnitude
        petLayer.add(stretch, forKey: "drag-stretch")
    }
    
    private func addDropSquash() {
        let squash = CABasicAnimation(keyPath: "transform.scale")
        squash.fromValue = CATransform3DMakeScale(1.1, 0.9, 1.0)
        squash.toValue = CATransform3DIdentity
        squash.duration = 0.28
        squash.autoreverses = true
        squash.repeatCount = 2
        petLayer.add(squash, forKey: "drop-squash")
    }
    
    private func createRoundedBlobPath(rect: CGRect) -> NSBezierPath {
        // unused in pixel mode
        return NSBezierPath(rect: rect)
    }
    
    func getLayer() -> CALayer {
        return petLayer
    }
    
    // Internal for tests
    func interpolateColor(from: NSColor, to: NSColor, factor: Double) -> NSColor {
        let clampedFactor = max(0.0, min(1.0, factor))
        
        guard
            let fromRGB = from.usingColorSpace(.deviceRGB),
            let toRGB = to.usingColorSpace(.deviceRGB)
        else {
            // Fall back to AppKit’s blending if conversion fails
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

    // Internal for tests
    func debugSnapToPixel(_ value: CGFloat) -> CGFloat {
        return snap(value)
    }

    private func pixelRect(center: CGPoint, size: CGSize, corner: CGFloat) -> NSBezierPath {
        let rect = CGRect(
            x: snap(center.x - size.width / 2),
            y: snap(center.y - size.height / 2),
            width: snap(size.width),
            height: snap(size.height)
        )
        return NSBezierPath(roundedRect: rect, xRadius: corner, yRadius: corner)
    }

    private func pixelSmile(rect: CGRect, lift: CGFloat) -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.line(to: CGPoint(x: rect.midX, y: rect.minY + lift))
        path.line(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }

    private func pixelLine(rect: CGRect) -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.line(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }

    private func snap(_ value: CGFloat) -> CGFloat {
        return (value / pixelSize).rounded() * pixelSize
    }

    private func applyBlinkIfNeeded() {
        // Don't blink when sleeping
        guard currentState != .sleeping else {
            // Keep eyes closed when sleeping
            for eye in eyeLayers {
                eye.removeAnimation(forKey: "blink")
                eye.transform = CATransform3DMakeScale(1.0, 0.05, 1.0)
            }
            return
        }
        
        for eye in eyeLayers {
            eye.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            
            // Only add animation if it doesn't exist
            guard eye.animation(forKey: "blink") == nil else { continue }
            
            // Create a more visible and frequent blink animation
            let blink = CAKeyframeAnimation(keyPath: "transform.scale.y")
            
            // More natural blink: quick close, brief hold closed, quick open
            blink.values = [1.0, 0.05, 0.05, 1.0]
            blink.keyTimes = [0.0, 0.3, 0.5, 1.0] // Close quickly, hold briefly, open quickly
            blink.duration = 0.2 // Longer for better visibility
            blink.repeatCount = .greatestFiniteMagnitude
            
            // More frequent blinking: every 2-4 seconds (more natural and visible)
            let delay = CFTimeInterval.random(in: 2.0...4.0)
            blink.beginTime = CACurrentMediaTime() + delay
            
            // Use ease-in-out for more natural motion
            blink.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            eye.add(blink, forKey: "blink")
        }
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

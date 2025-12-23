import Foundation
import Combine

enum Direction: String, Codable {
    case north
    case south
    case east
    case west
    case random
}

enum SleepDepth: String, Codable {
    case light
    case medium
    case deep
}

enum CuriosityTarget: String, Codable {
    case window
    case mouse
    case screenEdge
    case random
}

enum ToyType: String, Codable {
    case ball
    case sparkle
    case bubble
}

enum SocialReaction: String, Codable {
    case friendly
    case shy
    case excited
    case calm
}

enum ActivityType: Equatable {
    case exploring
    case exploringWithDirection(Direction)
    case playing
    case playingWithToy(ToyType)
    case resting
    case napping(SleepDepth)
    case observing
    case curious(CuriosityTarget)
    case wandering
    case social(SocialReaction)
    case startled
    case confused
    case excited
    case bored
}

class ActivityManager {
    private var petEntity: PetEntity
    private var activityTimer: Timer?
    private var lastActivityTime: Date = Date()
    private var currentActivity: ActivityType?
    private let memoryManager = MemoryManager.shared
    private var activityChain: [ActivityType] = []
    private var chainIndex: Int = 0
    
    // Activity parameters
    private var minActivityInterval: TimeInterval = 10.0 // Minimum 10 seconds between activities
    private var maxActivityInterval: TimeInterval = 120.0 // Maximum 2 minutes
    private var activityProbability: Double = 0.6 // 60% chance per check (increased for more autonomy)
    private var activityFrequencyMinutes: Int = 2 // Default from settings
    
    var onActivityTriggered: ((ActivityType) -> Void)?
    
    init(petEntity: PetEntity) {
        self.petEntity = petEntity
        // Get initial frequency from settings
        self.activityFrequencyMinutes = SettingsManager.shared.settings.behavior.activityFrequencyMinutes
        setupActivityTimer()
    }
    
    private func setupActivityTimer() {
        // Check for activities more frequently - adjust frequency based on personality and settings
        let baseInterval: TimeInterval = 15.0 // Check every 15 seconds (much more frequent)
        let frequencyMultiplier = petEntity.personalityEngine.activityFrequencyMultiplier()
        // Settings-based frequency: lower minutes = more frequent checks
        let settingsMultiplier = max(0.3, Double(activityFrequencyMinutes) / 10.0)
        let adjustedInterval = baseInterval * settingsMultiplier / frequencyMultiplier
        
        activityTimer?.invalidate()
        activityTimer = Timer.scheduledTimer(withTimeInterval: adjustedInterval, repeats: true) { [weak self] _ in
            self?.checkForActivity()
        }
    }
    
    func updateActivityFrequency(minutes: Int) {
        activityFrequencyMinutes = minutes
        setupActivityTimer() // Restart timer with new frequency
    }
    
    private func checkForActivity() {
        // Don't interrupt certain states (but allow transitions from them after some time)
        let currentState = petEntity.state
        let timeSinceLastActivity = Date().timeIntervalSince(lastActivityTime)
        
        // Allow transitions from sleeping/dancing/watching if enough time has passed
        if currentState == .sleeping || currentState == .dancing || currentState == .watching {
            // Wait longer before interrupting these states
            guard timeSinceLastActivity >= maxActivityInterval else {
                return
            }
        } else {
            // For other states, check minimum interval
            guard timeSinceLastActivity >= minActivityInterval else {
                return
            }
        }
        
        // Increased probability - pet is more autonomous
        // Adjust probability based on personality energy
        let energyMultiplier = petEntity.personalityEngine.activityFrequencyMultiplier()
        let adjustedProbability = activityProbability * energyMultiplier
        
        if Double.random(in: 0...1) < adjustedProbability {
            triggerRandomActivity()
        }
    }
    
    func triggerRandomActivity() {
        // Check if we're in an activity chain
        if !activityChain.isEmpty && chainIndex < activityChain.count {
            let activity = activityChain[chainIndex]
            chainIndex += 1
            executeActivity(activity)
            return
        }
        
        // Reset chain if completed
        if chainIndex >= activityChain.count {
            activityChain = []
            chainIndex = 0
        }
        
        let activity = selectContextualActivity()
        currentActivity = activity
        
        // Check if this activity should start a chain
        if shouldStartChain(for: activity) {
            activityChain = generateActivityChain(startingWith: activity)
            chainIndex = 1 // Skip first activity as we're about to execute it
        }
        
        executeActivity(activity)
    }
    
    private func executeActivity(_ activity: ActivityType) {
        currentActivity = activity
        
        switch activity {
        case .exploring, .exploringWithDirection:
            petEntity.setState(.walking)
            onActivityTriggered?(activity)
            
        case .playing, .playingWithToy:
            petEntity.setState(.playing)
            petEntity.adjustHappiness(0.1)
            onActivityTriggered?(activity)
            
        case .resting:
            petEntity.setState(.sitting)
            petEntity.adjustHealth(0.05)
            onActivityTriggered?(activity)
            
        case .napping(let depth):
            petEntity.setState(.sleeping)
            let healthBoost = depth == .deep ? 0.08 : (depth == .medium ? 0.05 : 0.03)
            petEntity.adjustHealth(healthBoost)
            onActivityTriggered?(activity)
            
        case .observing:
            petEntity.setState(.idle)
            onActivityTriggered?(activity)
            
        case .curious:
            petEntity.setState(.watching)
            petEntity.adjustHappiness(0.03)
            onActivityTriggered?(activity)
            
        case .wandering:
            petEntity.setState(.walking)
            onActivityTriggered?(activity)
            
        case .social(let reaction):
            switch reaction {
            case .friendly, .excited:
                petEntity.setState(.playing)
                petEntity.adjustHappiness(0.12)
            case .shy:
                petEntity.setState(.sitting)
            case .calm:
                petEntity.setState(.idle)
            }
            onActivityTriggered?(activity)
            
        case .startled:
            petEntity.setState(.idle)
            // Brief pause, then recover
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.petEntity.setState(.idle)
            }
            onActivityTriggered?(activity)
            
        case .confused:
            petEntity.setState(.idle)
            onActivityTriggered?(activity)
            
        case .excited:
            petEntity.setState(.playing)
            petEntity.adjustHappiness(0.15)
            onActivityTriggered?(activity)
            
        case .bored:
            petEntity.setState(.idle)
            // Boredom slightly reduces happiness
            petEntity.adjustHappiness(-0.02)
            onActivityTriggered?(activity)
        }
        
        lastActivityTime = Date()
    }
    
    // MARK: - Activity Chains
    
    private func shouldStartChain(for activity: ActivityType) -> Bool {
        let engine = petEntity.personalityEngine
        
        // High energy pets are more likely to chain activities
        if engine.activityFrequencyMultiplier() > 1.2 {
            return Double.random(in: 0...1) < 0.4
        }
        
        // Curious pets chain exploring activities
        if activity.baseType == .exploring && engine.curiosityProbability() > 0.7 {
            return Double.random(in: 0...1) < 0.5
        }
        
        // Playful pets chain playing activities
        if activity.baseType == .playing && engine.playfulnessProbability() > 0.7 {
            return Double.random(in: 0...1) < 0.4
        }
        
        return false
    }
    
    private func generateActivityChain(startingWith activity: ActivityType) -> [ActivityType] {
        var chain: [ActivityType] = [activity]
        let engine = petEntity.personalityEngine
        let chainLength = Int.random(in: 2...4)
        
        for _ in 1..<chainLength {
            let nextActivity = selectNextChainActivity(current: activity, engine: engine)
            chain.append(nextActivity)
        }
        
        return chain
    }
    
    private func selectNextChainActivity(current: ActivityType, engine: PersonalityEngine) -> ActivityType {
        // Chain activities that make sense together
        let base = current.baseType
        switch base {
        case .exploring:
            // Exploring -> curious -> observing
            if engine.curiosityProbability() > 0.6 {
                return .curious(.random)
            }
            return .observing
            
        case .playing:
            // Playing -> social -> excited
            if engine.socialInteractionProbability() > 0.6 {
                return .social(.friendly)
            }
            if Double.random(in: 0...1) < 0.5 {
                return .excited
            }
            return .playingWithToy(.ball)
            
        case .resting:
            // Resting -> napping -> sleeping (if tired)
            if engine.sleepProbability(timeOfDay: petEntity.age) > 0.6 {
                return .napping(.medium)
            }
            return .resting
            
        case .observing:
            // Observing -> curious -> exploring
            if engine.curiosityProbability() > 0.7 {
                return .curious(.random)
            }
            return .exploringWithDirection(.random)
            
        case .wandering:
            // Wandering -> exploring -> curious
            return .exploringWithDirection(.random)
            
        case .exploringWithDirection, .playingWithToy, .napping, .curious, .social, .startled, .confused, .excited, .bored:
            // These shouldn't happen as baseType, but handle them anyway
            return .observing
        }
    }
    
    private func selectContextualActivity() -> ActivityType {
        let hour = Calendar.current.component(.hour, from: Date())
        let minute = Calendar.current.component(.minute, from: Date())
        let age = petEntity.age
        let health = petEntity.health
        let happiness = petEntity.happiness
        let timeOfDay = age // Use age as proxy for time of day (0.0 = midnight, 1.0 = next midnight)
        let engine = petEntity.personalityEngine
        
        // Calculate preferences for each activity type
        var activityPreferences: [(ActivityType, Double)] = ActivityType.allCases.map { activity in
            let basePreference = engine.preferenceForActivity(activity.baseType)
            return (activity, basePreference)
        }
        
        // Enhance activities based on personality and context
        activityPreferences = enhanceActivitiesWithVariants(preferences: activityPreferences, engine: engine, hour: hour, happiness: happiness, health: health)
        
        // Apply memory-based modifiers
        activityPreferences = applyMemoryModifiers(to: activityPreferences, hour: hour, minute: minute)
        
        // Time-based modifiers (using baseType for variant matching)
        if hour >= 22 || hour < 6 {
            // Night time - increase sleep probability
            activityPreferences = activityPreferences.map { activity, preference in
                if activity.baseType == .resting {
                    return (activity, preference + engine.sleepProbability(timeOfDay: timeOfDay))
                }
                return (activity, preference * 0.5)
            }
        } else if hour >= 6 && hour < 9 {
            // Morning - boost exploring/wandering for curious pets
            activityPreferences = activityPreferences.map { activity, preference in
                if activity.baseType == .exploring || activity.baseType == .wandering {
                    return (activity, preference * (1.0 + engine.curiosityProbability()))
                }
                return (activity, preference)
            }
        } else if hour >= 12 && hour < 14 {
            // Lunch time - prefer resting
            activityPreferences = activityPreferences.map { activity, preference in
                if activity.baseType == .resting {
                    return (activity, preference + 0.3)
                }
                return (activity, preference * 0.7)
            }
        } else if hour >= 18 && hour < 22 {
            // Evening - boost observing/playing for social pets
            activityPreferences = activityPreferences.map { activity, preference in
                if activity.baseType == .observing || activity.baseType == .playing {
                    return (activity, preference * (1.0 + engine.socialInteractionProbability()))
                }
                return (activity, preference)
            }
        }
        
        // Health/happiness modifiers
        if health < 0.5 {
            // Low health - strongly prefer resting
            activityPreferences = activityPreferences.map { activity, preference in
                if activity.baseType == .resting {
                    return (activity, preference + 0.5)
                }
                return (activity, preference * 0.5)
            }
        } else if happiness < 0.5 {
            // Low happiness - prefer playing (boosted by playfulness)
            activityPreferences = activityPreferences.map { activity, preference in
                if activity.baseType == .playing {
                    return (activity, preference + (0.4 * engine.playfulnessProbability()))
                }
                return (activity, preference)
            }
        }
        
        // Age-based modifiers
        if age > 0.7 {
            // Late in day - reduce energy-intensive activities
            activityPreferences = activityPreferences.map { activity, preference in
                if activity.baseType == .exploring || activity.baseType == .wandering {
                    return (activity, preference * (1.0 - engine.activityFrequencyMultiplier() + 0.5))
                }
                return (activity, preference)
            }
        } else if age < 0.3 {
            // Early in day - boost active activities for energetic pets
            activityPreferences = activityPreferences.map { activity, preference in
                if activity.baseType == .exploring || activity.baseType == .wandering {
                    return (activity, preference * (1.0 + engine.activityFrequencyMultiplier() * 0.5))
                }
                return (activity, preference)
            }
        }
        
        // Select based on weighted preferences
        let totalWeight = activityPreferences.reduce(0.0) { $0 + $1.1 }
        guard totalWeight > 0 else {
            return ActivityType.allCases.randomElement() ?? .observing
        }
        
        let random = Double.random(in: 0...totalWeight)
        var cumulative: Double = 0
        
        for (activity, weight) in activityPreferences {
            cumulative += weight
            if random <= cumulative {
                return activity
            }
        }
        
        // Fallback
        return ActivityType.allCases.randomElement() ?? .observing
    }
    
    // MARK: - Memory-Based Decision Making
    
    private func applyMemoryModifiers(to preferences: [(ActivityType, Double)], hour: Int, minute: Int) -> [(ActivityType, Double)] {
        var modified = preferences
        
        // Check for time patterns - if pet remembers doing this activity at this time, boost it
        for (index, (activity, preference)) in modified.enumerated() {
            let activityString = activityToMemoryString(activity)
            if let pattern = memoryManager.findPatternForTime(hour: hour, minute: minute, activity: activityString) {
                // Boost preference based on pattern strength and occurrence count
                let boost = pattern.strength * (1.0 + Double(pattern.occurrenceCount) * 0.1)
                modified[index] = (activity, preference + boost)
            }
        }
        
        // Check activity preferences - boost activities pet enjoys, reduce ones it doesn't
        let activityPrefs = memoryManager.getActivityPreferences()
        for (index, (activity, preference)) in modified.enumerated() {
            let activityString = activityToMemoryString(activity)
            if let activityPref = activityPrefs.first(where: { $0.activityType == activityString }) {
                // Modify preference based on enjoyment (0.0-1.0)
                // Enjoyment > 0.7 = boost, < 0.3 = reduce
                let enjoymentModifier = (activityPref.enjoyment - 0.5) * 2.0 // Scale to -1.0 to 1.0
                let modifier = enjoymentModifier * activityPref.strength * 0.3
                modified[index] = (activity, max(0.0, preference + modifier))
            }
        }
        
        // Check health patterns - if health/happiness is typically low at this hour, prefer resting
        let healthPatterns = memoryManager.getHealthPatterns(for: hour)
        if let pattern = healthPatterns.first {
            if pattern.healthLevel < 0.5 || pattern.happinessLevel < 0.5 {
                // Boost resting preference
                for (index, (activity, preference)) in modified.enumerated() {
                    if activity.baseType == .resting {
                        modified[index] = (activity, preference + pattern.strength * 0.4)
                    }
                }
            }
        }
        
        return modified
    }
    
    private func activityToMemoryString(_ activity: ActivityType) -> String {
        return activity.baseType.rawValue
    }
    
    private func enhanceActivitiesWithVariants(preferences: [(ActivityType, Double)], engine: PersonalityEngine, hour: Int, happiness: Double, health: Double) -> [(ActivityType, Double)] {
        var enhanced: [(ActivityType, Double)] = []
        
        for (activity, preference) in preferences {
            switch activity {
            case .exploring:
                // Replace with directional exploring based on curiosity
                if engine.curiosityProbability() > 0.6 {
                    let direction = Direction.allCases.randomElement() ?? .random
                    enhanced.append((.exploringWithDirection(direction), preference * 1.2))
                } else {
                    enhanced.append((activity, preference))
                }
                
            case .playing:
                // Replace with toy-based playing based on playfulness
                if engine.playfulnessProbability() > 0.7 {
                    let toy = ToyType.allCases.randomElement() ?? .ball
                    enhanced.append((.playingWithToy(toy), preference * 1.15))
                } else {
                    enhanced.append((activity, preference))
                }
                
            case .resting:
                // Replace with napping if sleepiness is high or it's night
                if engine.sleepProbability(timeOfDay: Double(hour) / 24.0) > 0.6 || hour >= 22 || hour < 6 {
                    let depth: SleepDepth = engine.sleepProbability(timeOfDay: Double(hour) / 24.0) > 0.8 ? .deep : .medium
                    enhanced.append((.napping(depth), preference * 1.3))
                } else {
                    enhanced.append((activity, preference))
                }
                
            case .observing:
                // Replace with curious if curiosity is high
                if engine.curiosityProbability() > 0.7 {
                    let target = CuriosityTarget.allCases.randomElement() ?? .random
                    enhanced.append((.curious(target), preference * 1.2))
                } else {
                    enhanced.append((activity, preference))
                }
                
            case .wandering:
                enhanced.append((activity, preference))
                
            case .social:
                // Determine social reaction based on sociability
                let reaction: SocialReaction
                if engine.socialInteractionProbability() > 0.8 {
                    reaction = .excited
                } else if engine.socialInteractionProbability() > 0.6 {
                    reaction = .friendly
                } else if engine.socialInteractionProbability() < 0.3 {
                    reaction = .shy
                } else {
                    reaction = .calm
                }
                enhanced.append((.social(reaction), preference))
                
            default:
                enhanced.append((activity, preference))
            }
        }
        
        // Add emotional states based on context
        if happiness < 0.3 {
            enhanced.append((.bored, 0.3))
        } else if happiness > 0.8 {
            enhanced.append((.excited, 0.4))
        }
        
        if health < 0.3 {
            enhanced.append((.confused, 0.2))
        }
        
        return enhanced
    }
    
    func forceActivity(_ activity: ActivityType) {
        currentActivity = activity
        triggerRandomActivity()
    }
    
    func getCurrentActivity() -> ActivityType? {
        return currentActivity
    }
    
    deinit {
        activityTimer?.invalidate()
    }
}

extension Direction: CaseIterable {
    static var allCases: [Direction] {
        return [.north, .south, .east, .west, .random]
    }
}

extension SleepDepth: CaseIterable {
    static var allCases: [SleepDepth] {
        return [.light, .medium, .deep]
    }
}

extension CuriosityTarget: CaseIterable {
    static var allCases: [CuriosityTarget] {
        return [.window, .mouse, .screenEdge, .random]
    }
}

extension ToyType: CaseIterable {
    static var allCases: [ToyType] {
        return [.ball, .sparkle, .bubble]
    }
}

extension SocialReaction: CaseIterable {
    static var allCases: [SocialReaction] {
        return [.friendly, .shy, .excited, .calm]
    }
}

extension ActivityType: CaseIterable {
    static var allCases: [ActivityType] {
        return [
            .exploring,
            .exploringWithDirection(.random),
            .playing,
            .playingWithToy(.ball),
            .resting,
            .napping(.medium),
            .observing,
            .curious(.random),
            .wandering,
            .social(.friendly),
            .startled,
            .confused,
            .excited,
            .bored
        ]
    }
    
    // Base activity type for memory/pattern matching
    var baseType: ActivityType {
        switch self {
        case .exploring, .exploringWithDirection:
            return .exploring
        case .playing, .playingWithToy:
            return .playing
        case .resting, .napping:
            return .resting
        case .observing, .curious:
            return .observing
        case .wandering:
            return .wandering
        case .social:
            return .playing // Social is a form of playing
        case .startled, .confused, .excited, .bored:
            return .observing // Emotional states are observing
        }
    }
    
    var rawValue: String {
        switch self {
        case .exploring, .exploringWithDirection:
            return "exploring"
        case .playing, .playingWithToy:
            return "playing"
        case .resting, .napping:
            return "resting"
        case .observing, .curious:
            return "observing"
        case .wandering:
            return "wandering"
        case .social:
            return "playing"
        case .startled, .confused, .excited, .bored:
            return "observing"
        }
    }
}

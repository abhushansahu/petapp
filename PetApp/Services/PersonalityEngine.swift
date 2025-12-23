import Foundation

/// Engine that calculates behavior probabilities and influences based on personality traits
class PersonalityEngine {
    private let personality: PetPersonality
    
    init(personality: PetPersonality) {
        self.personality = personality.validated()
    }
    
    // MARK: - Activity Probabilities
    
    /// Calculates the probability of playing vs resting based on playfulness
    func playfulnessProbability() -> Double {
        return personality.playfulness
    }
    
    /// Calculates the probability of exploring vs observing based on curiosity
    func curiosityProbability() -> Double {
        return personality.curiosity
    }
    
    /// Calculates the probability of sleeping based on sleepiness and time of day
    func sleepProbability(timeOfDay: Double) -> Double {
        // Base sleepiness trait
        let baseSleepiness = personality.sleepiness
        
        // Time of day modifier (higher at night, lower during day)
        let timeModifier: Double
        if timeOfDay < 0.25 || timeOfDay > 0.75 {
            // Night time (0-6am or 6pm-midnight)
            timeModifier = 0.3
        } else {
            // Day time
            timeModifier = -0.2
        }
        
        return max(0.0, min(1.0, baseSleepiness + timeModifier))
    }
    
    /// Calculates the probability of social interactions based on sociability
    func socialInteractionProbability() -> Double {
        return personality.sociability
    }
    
    /// Calculates activity frequency multiplier based on energy
    func activityFrequencyMultiplier() -> Double {
        // Energy affects how often activities occur
        // Low energy (0.0) = 0.5x frequency, High energy (1.0) = 1.5x frequency
        return 0.5 + personality.energy
    }
    
    /// Calculates activity intensity multiplier based on energy
    func activityIntensityMultiplier() -> Double {
        // Energy affects how intense activities are
        // Low energy (0.0) = 0.7x intensity, High energy (1.0) = 1.3x intensity
        return 0.7 + (personality.energy * 0.6)
    }
    
    // MARK: - State Transition Influence
    
    /// Determines if a state transition should occur based on personality
    func shouldTransition(from: PetState, to: PetState) -> Bool {
        // High energy pets are more likely to transition
        if personality.energy > 0.7 {
            return true
        }
        
        // Low energy pets resist transitions
        if personality.energy < 0.3 {
            return Double.random(in: 0...1) > 0.3
        }
        
        return true
    }
    
    /// Calculates preference for a given activity type
    func preferenceForActivity(_ activityType: ActivityType) -> Double {
        switch activityType {
        case .playing, .playingWithToy:
            return personality.playfulness
        case .exploring, .exploringWithDirection:
            return personality.curiosity * personality.energy
        case .resting, .napping:
            return personality.sleepiness
        case .observing, .curious:
            return personality.curiosity * (1.0 - personality.energy)
        case .wandering:
            return personality.curiosity * personality.energy * 0.8
        case .social:
            return personality.sociability
        case .startled, .confused, .excited, .bored:
            // These are emotional or transient states; return a neutral or minimal preference
            return 0.2
        }
    }
    
    // MARK: - Interaction Response
    
    /// Calculates response intensity to user interactions based on sociability
    func interactionResponseIntensity() -> Double {
        return personality.sociability
    }
    
    /// Determines if pet should respond positively to interaction
    func shouldRespondPositively() -> Bool {
        return personality.sociability > 0.4
    }
    
    // MARK: - Animation Intensity
    
    /// Calculates animation intensity multiplier based on personality
    func animationIntensityMultiplier() -> Double {
        // More energetic and playful pets have more intense animations
        let energyComponent = personality.energy * 0.6
        let playfulnessComponent = personality.playfulness * 0.4
        return 0.7 + energyComponent + playfulnessComponent
    }
}

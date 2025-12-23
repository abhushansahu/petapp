import Foundation

/// Represents the personality traits of the pet, each ranging from 0.0 to 1.0
struct PetPersonality: Codable, Equatable {
    /// Affects likelihood of playing vs resting (higher = more playful)
    var playfulness: Double
    
    /// Affects exploration and observation behaviors (higher = more curious)
    var curiosity: Double
    
    /// Affects sleep frequency and duration (higher = sleepier)
    var sleepiness: Double
    
    /// Affects interaction responsiveness (higher = more social)
    var sociability: Double
    
    /// Affects activity frequency and intensity (higher = more energetic)
    var energy: Double
    
    /// Default neutral personality (all traits at 0.5)
    static let `default` = PetPersonality(
        playfulness: 0.5,
        curiosity: 0.5,
        sleepiness: 0.5,
        sociability: 0.5,
        energy: 0.5
    )
    
    /// Validates and clamps all traits to valid range [0.0, 1.0]
    func validated() -> PetPersonality {
        var copy = self
        copy.playfulness = clamp(copy.playfulness, min: 0.0, max: 1.0)
        copy.curiosity = clamp(copy.curiosity, min: 0.0, max: 1.0)
        copy.sleepiness = clamp(copy.sleepiness, min: 0.0, max: 1.0)
        copy.sociability = clamp(copy.sociability, min: 0.0, max: 1.0)
        copy.energy = clamp(copy.energy, min: 0.0, max: 1.0)
        return copy
    }
    
    private func clamp(_ value: Double, min: Double, max: Double) -> Double {
        return Swift.max(min, Swift.min(max, value))
    }
}

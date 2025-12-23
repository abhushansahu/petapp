import Foundation

struct PetSettings: Codable, Equatable {
    struct Appearance: Codable, Equatable {
        var petName: String
        var petSize: Double
        var showParticles: Bool
        var effectsIntensity: Double
    }
    
    struct Behavior: Codable, Equatable {
        var activityFrequencyMinutes: Int
        var interactionProximity: Double
    }
    
    struct Reminders: Codable, Equatable {
        var healthRemindersEnabled: Bool
        var customRemindersEnabled: Bool
    }
    
    struct Focus: Codable, Equatable {
        var apps: [String]
    }
    
    struct Personality: Codable, Equatable {
        var playfulness: Double
        var curiosity: Double
        var sleepiness: Double
        var sociability: Double
        var energy: Double
    }
    
    static let currentSchemaVersion = 2
    
    var schemaVersion: Int
    var appearance: Appearance
    var behavior: Behavior
    var reminders: Reminders
    var focus: Focus
    var personality: Personality
    
    /// Bridging accessors so existing call sites remain source-compatible.
    var petName: String {
        get { appearance.petName }
        set { appearance.petName = newValue }
    }
    
    var petSize: Double {
        get { appearance.petSize }
        set { appearance.petSize = newValue }
    }
    
    var showParticles: Bool {
        get { appearance.showParticles }
        set { appearance.showParticles = newValue }
    }
    
    var effectsIntensity: Double {
        get { appearance.effectsIntensity }
        set { appearance.effectsIntensity = newValue }
    }
    
    var activityFrequencyMinutes: Int {
        get { behavior.activityFrequencyMinutes }
        set { behavior.activityFrequencyMinutes = newValue }
    }
    
    var interactionProximity: Double {
        get { behavior.interactionProximity }
        set { behavior.interactionProximity = newValue }
    }
    
    var focusApps: [String] {
        get { focus.apps }
        set { focus.apps = newValue }
    }
    
    static let `default` = PetSettings(
        schemaVersion: currentSchemaVersion,
        appearance: Appearance(
            petName: "Mochi",
            petSize: 96.0,
            showParticles: true,
            effectsIntensity: 0.8
        ),
        behavior: Behavior(
            activityFrequencyMinutes: 2,
            interactionProximity: 120.0
        ),
        reminders: Reminders(
            healthRemindersEnabled: true,
            customRemindersEnabled: true
        ),
        focus: Focus(apps: []),
        personality: Personality(
            playfulness: 0.5,
            curiosity: 0.5,
            sleepiness: 0.5,
            sociability: 0.5,
            energy: 0.5
        )
    )
}

extension PetSettings {
    /// Returns a version of the settings clamped to safe ranges and normalized.
    func validated() -> PetSettings {
        var copy = self
        
        copy.appearance.petName = sanitizedName(copy.appearance.petName)
        copy.appearance.petSize = clamp(copy.appearance.petSize, min: 72, max: 200)
        copy.appearance.effectsIntensity = clamp(copy.appearance.effectsIntensity, min: 0, max: 1)
        
        copy.behavior.activityFrequencyMinutes = Int(clamp(Double(copy.behavior.activityFrequencyMinutes), min: 1, max: 10))
        copy.behavior.interactionProximity = clamp(copy.behavior.interactionProximity, min: 60, max: 260)
        
        copy.focus.apps = normalizedApps(copy.focus.apps)
        
        // Validate personality traits
        copy.personality.playfulness = clamp(copy.personality.playfulness, min: 0.0, max: 1.0)
        copy.personality.curiosity = clamp(copy.personality.curiosity, min: 0.0, max: 1.0)
        copy.personality.sleepiness = clamp(copy.personality.sleepiness, min: 0.0, max: 1.0)
        copy.personality.sociability = clamp(copy.personality.sociability, min: 0.0, max: 1.0)
        copy.personality.energy = clamp(copy.personality.energy, min: 0.0, max: 1.0)
        
        copy.schemaVersion = PetSettings.currentSchemaVersion
        return copy
    }
    
    /// Ensures the instance records the current schema version (no other mutations).
    func withCurrentSchemaVersion() -> PetSettings {
        var copy = self
        copy.schemaVersion = PetSettings.currentSchemaVersion
        return copy
    }
    
    private func clamp(_ value: Double, min: Double, max: Double) -> Double {
        return Swift.max(min, Swift.min(max, value))
    }
    
    private func sanitizedName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? PetSettings.default.appearance.petName : trimmed
    }
    
    private func normalizedApps(_ apps: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        
        for app in apps {
            let trimmed = app.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            if seen.insert(trimmed).inserted {
                result.append(trimmed)
            }
        }
        
        return result
    }
}

extension PetSettings {
    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case appearance
        case behavior
        case reminders
        case focus
        case personality
        
        // Legacy keys (v1) kept for migration
        case petName
        case petSize
        case showParticles
        case effectsIntensity
        case activityFrequencyMinutes
        case interactionProximity
        case focusApps
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedSchemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? PetSettings.currentSchemaVersion
        
        if let appearance = try container.decodeIfPresent(Appearance.self, forKey: .appearance),
           let behavior = try container.decodeIfPresent(Behavior.self, forKey: .behavior),
           let reminders = try container.decodeIfPresent(Reminders.self, forKey: .reminders),
           let focus = try container.decodeIfPresent(Focus.self, forKey: .focus),
           let personality = try container.decodeIfPresent(Personality.self, forKey: .personality) {
            self.schemaVersion = decodedSchemaVersion
            self.appearance = appearance
            self.behavior = behavior
            self.reminders = reminders
            self.focus = focus
            self.personality = personality
            return
        }
        
        // Try v1 with personality fallback
        if let appearance = try container.decodeIfPresent(Appearance.self, forKey: .appearance),
           let behavior = try container.decodeIfPresent(Behavior.self, forKey: .behavior),
           let reminders = try container.decodeIfPresent(Reminders.self, forKey: .reminders),
           let focus = try container.decodeIfPresent(Focus.self, forKey: .focus) {
            self.schemaVersion = decodedSchemaVersion
            self.appearance = appearance
            self.behavior = behavior
            self.reminders = reminders
            self.focus = focus
            self.personality = PetSettings.default.personality
            return
        }
        
        // Legacy flat decoding (v1)
        let petName = try container.decodeIfPresent(String.self, forKey: .petName) ?? PetSettings.default.petName
        let petSize = try container.decodeIfPresent(Double.self, forKey: .petSize) ?? PetSettings.default.petSize
        let showParticles = try container.decodeIfPresent(Bool.self, forKey: .showParticles) ?? PetSettings.default.showParticles
        let effectsIntensity = try container.decodeIfPresent(Double.self, forKey: .effectsIntensity) ?? PetSettings.default.effectsIntensity
        let activityFrequency = try container.decodeIfPresent(Int.self, forKey: .activityFrequencyMinutes) ?? PetSettings.default.activityFrequencyMinutes
        let interactionProximity = try container.decodeIfPresent(Double.self, forKey: .interactionProximity) ?? PetSettings.default.interactionProximity
        let focusApps = try container.decodeIfPresent([String].self, forKey: .focusApps) ?? PetSettings.default.focusApps
        
        self.schemaVersion = decodedSchemaVersion
        self.appearance = Appearance(
            petName: petName,
            petSize: petSize,
            showParticles: showParticles,
            effectsIntensity: effectsIntensity
        )
        self.behavior = Behavior(
            activityFrequencyMinutes: activityFrequency,
            interactionProximity: interactionProximity
        )
        self.reminders = PetSettings.default.reminders
        self.focus = Focus(apps: focusApps)
        self.personality = PetSettings.default.personality
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(appearance, forKey: .appearance)
        try container.encode(behavior, forKey: .behavior)
        try container.encode(reminders, forKey: .reminders)
        try container.encode(focus, forKey: .focus)
        try container.encode(personality, forKey: .personality)
    }
}

import Foundation

/// Manages pet memories with persistence, decay, and pattern recognition
class MemoryManager {
    static let shared = MemoryManager()
    
    private static let storageKey = "pet.memories.v1"
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private var memories: [MemoryContainer] = []
    
    // Memory decay parameters
    private let decayRate: Double = 0.001 // Per day
    private let minStrength: Double = 0.1 // Memories below this are removed
    
    init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults
        loadMemories()
        startDecayTimer()
    }
    
    // MARK: - Memory Storage
    
    /// Record an interaction memory
    func recordInteraction(type: String, location: CGPoint? = nil) {
        let memory = InteractionMemory(interactionType: type, location: location)
        addMemory(memory)
    }
    
    /// Record a location memory
    func recordLocation(screenIndex: Int, position: CGPoint) {
        // Check if we already have a memory for this location
        if let existing = findLocationMemory(screenIndex: screenIndex, position: position) {
            // Update existing memory
            var updated = existing
            updated.visitCount += 1
            updated.strength = min(1.0, updated.strength + 0.1)
            updated.timestamp = Date()
            updateMemory(existing, with: updated)
        } else {
            let memory = LocationMemory(screenIndex: screenIndex, position: position)
            addMemory(memory)
        }
    }
    
    /// Record a time pattern memory
    func recordTimePattern(hour: Int, minute: Int, activity: String) {
        if let existing = findTimePatternMemory(hour: hour, minute: minute, activity: activity) {
            var updated = existing
            updated.occurrenceCount += 1
            updated.strength = min(1.0, updated.strength + 0.05)
            updated.timestamp = Date()
            updateMemory(existing, with: updated)
        } else {
            let memory = TimePatternMemory(hour: hour, minute: minute, activity: activity)
            addMemory(memory)
        }
    }
    
    /// Record an app preference memory
    func recordAppPreference(appName: String, preference: Double) {
        if let existing = findAppPreferenceMemory(appName: appName) {
            var updated = existing
            updated.interactionCount += 1
            // Weighted average of preference
            let totalWeight = Double(existing.interactionCount) + 1.0
            updated.preference = (existing.preference * Double(existing.interactionCount) + preference) / totalWeight
            updated.strength = min(1.0, updated.strength + 0.05)
            updated.timestamp = Date()
            updateMemory(existing, with: updated)
        } else {
            let memory = AppPreferenceMemory(appName: appName, preference: preference)
            addMemory(memory)
        }
    }
    
    /// Record an activity preference memory
    func recordActivityPreference(activityType: String, enjoyment: Double) {
        if let existing = findActivityPreferenceMemory(activityType: activityType) {
            var updated = existing
            updated.occurrenceCount += 1
            // Weighted average of enjoyment
            let totalWeight = Double(existing.occurrenceCount) + 1.0
            updated.enjoyment = (existing.enjoyment * Double(existing.occurrenceCount) + enjoyment) / totalWeight
            updated.strength = min(1.0, updated.strength + 0.05)
            updated.timestamp = Date()
            updateMemory(existing, with: updated)
        } else {
            let memory = ActivityPreferenceMemory(activityType: activityType, enjoyment: enjoyment)
            addMemory(memory)
        }
    }
    
    /// Record a health pattern memory
    func recordHealthPattern(hour: Int, healthLevel: Double, happinessLevel: Double) {
        if let existing = findHealthPatternMemory(hour: hour) {
            var updated = existing
            updated.occurrenceCount += 1
            // Average health/happiness levels
            let totalWeight = Double(existing.occurrenceCount) + 1.0
            updated.healthLevel = (existing.healthLevel * Double(existing.occurrenceCount) + healthLevel) / totalWeight
            updated.happinessLevel = (existing.happinessLevel * Double(existing.occurrenceCount) + happinessLevel) / totalWeight
            updated.strength = min(1.0, updated.strength + 0.05)
            updated.timestamp = Date()
            updateMemory(existing, with: updated)
        } else {
            let memory = HealthPatternMemory(hour: hour, healthLevel: healthLevel, happinessLevel: happinessLevel)
            addMemory(memory)
        }
    }
    
    // MARK: - Memory Retrieval
    
    /// Get all interaction memories
    func getInteractionMemories() -> [InteractionMemory] {
        return memories.compactMap { container in
            guard container.type == .interaction else { return nil }
            return try? container.decode(as: InteractionMemory.self)
        }
    }
    
    /// Get favorite locations
    func getFavoriteLocations(limit: Int = 5) -> [LocationMemory] {
        let locations = memories.compactMap { container -> LocationMemory? in
            guard container.type == .location else { return nil }
            return try? container.decode(as: LocationMemory.self)
        }
        return locations.sorted { $0.strength > $1.strength }.prefix(limit).map { $0 }
    }
    
    /// Get time patterns for a specific activity
    func getTimePatterns(for activity: String) -> [TimePatternMemory] {
        return memories.compactMap { container -> TimePatternMemory? in
            guard container.type == .timePattern else { return nil }
            let memory = try? container.decode(as: TimePatternMemory.self)
            return memory?.activity == activity ? memory : nil
        }
    }
    
    /// Get app preferences
    func getAppPreferences() -> [AppPreferenceMemory] {
        return memories.compactMap { container -> AppPreferenceMemory? in
            guard container.type == .appPreference else { return nil }
            return try? container.decode(as: AppPreferenceMemory.self)
        }
    }
    
    /// Get activity preferences
    func getActivityPreferences() -> [ActivityPreferenceMemory] {
        return memories.compactMap { container -> ActivityPreferenceMemory? in
            guard container.type == .activityPreference else { return nil }
            return try? container.decode(as: ActivityPreferenceMemory.self)
        }
    }
    
    /// Get health patterns for a specific hour
    func getHealthPatterns(for hour: Int) -> [HealthPatternMemory] {
        return memories.compactMap { container -> HealthPatternMemory? in
            guard container.type == .healthPattern else { return nil }
            let memory = try? container.decode(as: HealthPatternMemory.self)
            return memory?.hour == hour ? memory : nil
        }
    }
    
    // MARK: - Pattern Recognition
    
    /// Find if there's a pattern for a specific time and activity
    func findPatternForTime(hour: Int, minute: Int, activity: String) -> TimePatternMemory? {
        return getTimePatterns(for: activity).first { memory in
            memory.hour == hour && abs(memory.minute - minute) < 15
        }
    }
    
    /// Get most enjoyed activity
    func getMostEnjoyedActivity() -> ActivityPreferenceMemory? {
        return getActivityPreferences().max { $0.enjoyment < $1.enjoyment }
    }
    
    /// Get least enjoyed activity
    func getLeastEnjoyedActivity() -> ActivityPreferenceMemory? {
        return getActivityPreferences().min { $0.enjoyment < $1.enjoyment }
    }
    
    // MARK: - Private Helpers
    
    private func addMemory<T: PetMemoryProtocol>(_ memory: T) {
        guard let container = try? MemoryContainer(memory) else { return }
        memories.append(container)
        persistMemories()
    }
    
    private func updateMemory<T: PetMemoryProtocol>(_ old: T, with new: T) {
        guard let index = memories.firstIndex(where: { container in
            guard let decoded = try? container.decode(as: T.self) else { return false }
            return decoded.id == old.id
        }) else { return }
        
        guard let newContainer = try? MemoryContainer(new) else { return }
        memories[index] = newContainer
        persistMemories()
    }
    
    private func findLocationMemory(screenIndex: Int, position: CGPoint) -> LocationMemory? {
        return memories.compactMap { container -> LocationMemory? in
            guard container.type == .location else { return nil }
            return try? container.decode(as: LocationMemory.self)
        }.first { memory in
            memory.screenIndex == screenIndex && 
            abs(memory.position.x - position.x) < 50 && 
            abs(memory.position.y - position.y) < 50
        }
    }
    
    private func findTimePatternMemory(hour: Int, minute: Int, activity: String) -> TimePatternMemory? {
        return getTimePatterns(for: activity).first { memory in
            memory.hour == hour && abs(memory.minute - minute) < 15
        }
    }
    
    private func findAppPreferenceMemory(appName: String) -> AppPreferenceMemory? {
        return getAppPreferences().first { $0.appName == appName }
    }
    
    private func findActivityPreferenceMemory(activityType: String) -> ActivityPreferenceMemory? {
        return getActivityPreferences().first { $0.activityType == activityType }
    }
    
    private func findHealthPatternMemory(hour: Int) -> HealthPatternMemory? {
        return getHealthPatterns(for: hour).first
    }
    
    // MARK: - Persistence
    
    private func loadMemories() {
        guard let data = defaults.data(forKey: Self.storageKey),
              let decoded = try? decoder.decode([MemoryContainer].self, from: data) else {
            memories = []
            return
        }
        memories = decoded
    }
    
    private func persistMemories() {
        guard let data = try? encoder.encode(memories) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }
    
    // MARK: - Memory Decay
    
    private func startDecayTimer() {
        // Apply decay daily
        Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { [weak self] _ in
            self?.applyDecay()
        }
    }
    
    private func applyDecay() {
        var updatedMemories: [MemoryContainer] = []
        
        for container in memories {
            switch container.type {
            case .interaction:
                if var memory = try? container.decode(as: InteractionMemory.self) {
                    memory.strength = max(minStrength, memory.strength - decayRate)
                    if memory.strength > minStrength {
                        if let updated = try? MemoryContainer(memory) {
                            updatedMemories.append(updated)
                        }
                    }
                }
            case .location:
                if var memory = try? container.decode(as: LocationMemory.self) {
                    memory.strength = max(minStrength, memory.strength - decayRate)
                    if memory.strength > minStrength {
                        if let updated = try? MemoryContainer(memory) {
                            updatedMemories.append(updated)
                        }
                    }
                }
            case .timePattern:
                if var memory = try? container.decode(as: TimePatternMemory.self) {
                    memory.strength = max(minStrength, memory.strength - decayRate * 0.5) // Patterns decay slower
                    if memory.strength > minStrength {
                        if let updated = try? MemoryContainer(memory) {
                            updatedMemories.append(updated)
                        }
                    }
                }
            case .appPreference:
                if var memory = try? container.decode(as: AppPreferenceMemory.self) {
                    memory.strength = max(minStrength, memory.strength - decayRate * 0.3) // Preferences decay very slowly
                    if memory.strength > minStrength {
                        if let updated = try? MemoryContainer(memory) {
                            updatedMemories.append(updated)
                        }
                    }
                }
            case .activityPreference:
                if var memory = try? container.decode(as: ActivityPreferenceMemory.self) {
                    memory.strength = max(minStrength, memory.strength - decayRate * 0.3)
                    if memory.strength > minStrength {
                        if let updated = try? MemoryContainer(memory) {
                            updatedMemories.append(updated)
                        }
                    }
                }
            case .healthPattern:
                if var memory = try? container.decode(as: HealthPatternMemory.self) {
                    memory.strength = max(minStrength, memory.strength - decayRate * 0.5)
                    if memory.strength > minStrength {
                        if let updated = try? MemoryContainer(memory) {
                            updatedMemories.append(updated)
                        }
                    }
                }
            }
        }
        
        memories = updatedMemories
        persistMemories()
    }
    
    // MARK: - Memory Management
    
    func clearAllMemories() {
        memories = []
        persistMemories()
    }
    
    func removeMemory(id: UUID) {
        memories.removeAll { container in
            // Try to decode and check ID for each type
            if let memory = try? container.decode(as: InteractionMemory.self), memory.id == id { return true }
            if let memory = try? container.decode(as: LocationMemory.self), memory.id == id { return true }
            if let memory = try? container.decode(as: TimePatternMemory.self), memory.id == id { return true }
            if let memory = try? container.decode(as: AppPreferenceMemory.self), memory.id == id { return true }
            if let memory = try? container.decode(as: ActivityPreferenceMemory.self), memory.id == id { return true }
            if let memory = try? container.decode(as: HealthPatternMemory.self), memory.id == id { return true }
            return false
        }
        persistMemories()
    }
}

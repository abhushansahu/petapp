import Foundation

/// Represents different types of memories the pet can have
enum MemoryType: String, Codable {
    case interaction
    case location
    case timePattern
    case appPreference
    case activityPreference
    case healthPattern
}

/// Base protocol for all memory types
protocol PetMemoryProtocol: Codable {
    var id: UUID { get }
    var type: MemoryType { get }
    var timestamp: Date { get }
    var strength: Double { get set } // 0.0 to 1.0, decays over time
}

/// Memory of a user interaction
struct InteractionMemory: PetMemoryProtocol {
    let id: UUID
    let type: MemoryType
    let timestamp: Date
    var strength: Double
    
    let interactionType: String // "click", "drag", "feed", "play", etc.
    let locationX: Double?
    let locationY: Double?
    
    init(interactionType: String, location: CGPoint? = nil, strength: Double = 1.0) {
        self.id = UUID()
        self.type = .interaction
        self.timestamp = Date()
        self.strength = strength
        self.interactionType = interactionType
        self.locationX = location.map { Double($0.x) }
        self.locationY = location.map { Double($0.y) }
    }
    
    var location: CGPoint? {
        guard let x = locationX, let y = locationY else { return nil }
        return CGPoint(x: x, y: y)
    }
}

/// Memory of a favorite location
struct LocationMemory: PetMemoryProtocol {
    let id: UUID
    let type: MemoryType
    var timestamp: Date
    var strength: Double
    
    let screenIndex: Int
    let positionX: Double
    let positionY: Double
    var visitCount: Int
    
    init(screenIndex: Int, position: CGPoint, visitCount: Int = 1, strength: Double = 1.0) {
        self.id = UUID()
        self.type = .location
        self.timestamp = Date()
        self.strength = strength
        self.screenIndex = screenIndex
        self.positionX = position.x
        self.positionY = position.y
        self.visitCount = visitCount
    }
    
    var position: CGPoint {
        return CGPoint(x: positionX, y: positionY)
    }
}

/// Memory of a time pattern (e.g., "user always feeds at 9am")
struct TimePatternMemory: PetMemoryProtocol {
    let id: UUID
    let type: MemoryType
    var timestamp: Date
    var strength: Double
    
    let hour: Int
    let minute: Int
    let activity: String
    var occurrenceCount: Int
    
    init(hour: Int, minute: Int, activity: String, occurrenceCount: Int = 1, strength: Double = 1.0) {
        self.id = UUID()
        self.type = .timePattern
        self.timestamp = Date()
        self.strength = strength
        self.hour = hour
        self.minute = minute
        self.activity = activity
        self.occurrenceCount = occurrenceCount
    }
}

/// Memory of app preferences (which apps trigger positive/negative reactions)
struct AppPreferenceMemory: PetMemoryProtocol {
    let id: UUID
    let type: MemoryType
    var timestamp: Date
    var strength: Double
    
    let appName: String
    var preference: Double // -1.0 (dislike) to 1.0 (like)
    var interactionCount: Int
    
    init(appName: String, preference: Double, interactionCount: Int = 1, strength: Double = 1.0) {
        self.id = UUID()
        self.type = .appPreference
        self.timestamp = Date()
        self.strength = strength
        self.appName = appName
        self.preference = preference
        self.interactionCount = interactionCount
    }
}

/// Memory of activity preferences (most/least enjoyed activities)
struct ActivityPreferenceMemory: PetMemoryProtocol {
    let id: UUID
    let type: MemoryType
    var timestamp: Date
    var strength: Double
    
    let activityType: String
    var enjoyment: Double // 0.0 (disliked) to 1.0 (loved)
    var occurrenceCount: Int
    
    init(activityType: String, enjoyment: Double, occurrenceCount: Int = 1, strength: Double = 1.0) {
        self.id = UUID()
        self.type = .activityPreference
        self.timestamp = Date()
        self.strength = strength
        self.activityType = activityType
        self.enjoyment = enjoyment
        self.occurrenceCount = occurrenceCount
    }
}

/// Memory of health patterns (times when health/happiness were low/high)
struct HealthPatternMemory: PetMemoryProtocol {
    let id: UUID
    let type: MemoryType
    var timestamp: Date
    var strength: Double
    
    let hour: Int
    var healthLevel: Double
    var happinessLevel: Double
    var occurrenceCount: Int
    
    init(hour: Int, healthLevel: Double, happinessLevel: Double, occurrenceCount: Int = 1, strength: Double = 1.0) {
        self.id = UUID()
        self.type = .healthPattern
        self.timestamp = Date()
        self.strength = strength
        self.hour = hour
        self.healthLevel = healthLevel
        self.happinessLevel = happinessLevel
        self.occurrenceCount = occurrenceCount
    }
}

/// Wrapper to store any type of memory with type erasure for persistence
struct MemoryContainer: Codable {
    let type: MemoryType
    let data: Data
    
    init<T: PetMemoryProtocol>(_ memory: T) throws {
        self.type = memory.type
        self.data = try JSONEncoder().encode(memory)
    }
    
    func decode<T: PetMemoryProtocol>(as type: T.Type) throws -> T {
        return try JSONDecoder().decode(type, from: data)
    }
}


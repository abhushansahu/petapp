import Foundation

enum ReminderType {
    case timeBased(interval: TimeInterval)
    case custom(date: Date, title: String, message: String)
    case health(type: HealthReminderType)
}

enum HealthReminderType {
    case drinkWater
    case stretch
    case posture
    case takeBreak
    
    var title: String {
        switch self {
        case .drinkWater: return "Stay Hydrated"
        case .stretch: return "Time to Stretch"
        case .posture: return "Check Your Posture"
        case .takeBreak: return "Take a Break"
        }
    }
    
    var message: String {
        switch self {
        case .drinkWater: return "Your pet reminds you to drink some water! 💧"
        case .stretch: return "Your pet wants you to stretch a bit! 🧘"
        case .posture: return "Your pet noticed you might need to adjust your posture! 🪑"
        case .takeBreak: return "Your pet thinks you should take a short break! ☕"
        }
    }
    
    var defaultInterval: TimeInterval {
        switch self {
        case .drinkWater: return 60 * 60 // 1 hour
        case .stretch: return 90 * 60 // 1.5 hours
        case .posture: return 45 * 60 // 45 minutes
        case .takeBreak: return 120 * 60 // 2 hours
        }
    }
}

struct Reminder: Identifiable {
    let id: UUID
    let type: ReminderType
    var isActive: Bool
    var lastTriggered: Date?
    
    init(type: ReminderType, isActive: Bool = true) {
        self.id = UUID()
        self.type = type
        self.isActive = isActive
        self.lastTriggered = nil
    }
}

import Foundation
import Combine

class PetEntity: ObservableObject {
    // MARK: - Published Properties
    @Published var state: PetState = .idle
    @Published var age: Double = 0.0 // 0.0 to 1.0, representing progress through the day
    @Published var health: Double = 1.0 // 0.0 to 1.0
    @Published var happiness: Double = 1.0 // 0.0 to 1.0
    
    // MARK: - Personality
    var personality: PetPersonality {
        didSet {
            personalityEngine = PersonalityEngine(personality: personality)
        }
    }
    private(set) var personalityEngine: PersonalityEngine
    
    // MARK: - Private Properties
    private var dayStartTime: Date
    private var lastUpdateTime: Date
    private var dailyResetTimer: Timer?
    private var ageUpdateTimer: Timer?
    
    // MARK: - Initialization
    init(personality: PetPersonality = .default) {
        self.personality = personality
        self.personalityEngine = PersonalityEngine(personality: personality)
        let now = Date()
        dayStartTime = Calendar.current.startOfDay(for: now)
        lastUpdateTime = now
        
        // Calculate initial age
        updateAge()
        
        // Set up daily reset timer
        setupDailyReset()
        
        // Set up age update timer (update every minute)
        setupAgeUpdateTimer()
    }
    
    deinit {
        dailyResetTimer?.invalidate()
        ageUpdateTimer?.invalidate()
    }
    
    // MARK: - Age Management
    private func updateAge() {
        let now = Date()
        let dayStart = Calendar.current.startOfDay(for: now)
        
        // If it's a new day, reset
        if dayStart != dayStartTime {
            resetForNewDay()
            dayStartTime = dayStart
            return
        }
        
        // Calculate age as fraction of day elapsed
        let secondsSinceDayStart = now.timeIntervalSince(dayStart)
        let secondsInDay: TimeInterval = 24 * 60 * 60
        age = min(1.0, max(0.0, secondsSinceDayStart / secondsInDay))
        
        lastUpdateTime = now
    }
    
    private func setupAgeUpdateTimer() {
        ageUpdateTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.updateAge()
        }
    }
    
    // MARK: - Daily Reset
    private func setupDailyReset() {
        // Calculate time until next midnight
        let calendar = Calendar.current
        let now = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let midnight = calendar.startOfDay(for: tomorrow)
        let timeUntilMidnight = midnight.timeIntervalSince(now)
        
        // Schedule reset at midnight
        dailyResetTimer = Timer.scheduledTimer(withTimeInterval: timeUntilMidnight, repeats: false) { [weak self] _ in
            self?.resetForNewDay()
            // Schedule next reset
            self?.setupDailyReset()
        }
    }
    
    private func resetForNewDay() {
        age = 0.0
        dayStartTime = Calendar.current.startOfDay(for: Date())
        
        // Record health pattern before decay
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        MemoryManager.shared.recordHealthPattern(hour: hour, healthLevel: health, happinessLevel: happiness)
        
        // Slight health/happiness decay, but not too much
        health = max(0.5, health * 0.95)
        happiness = max(0.5, happiness * 0.95)
        
        // Return to idle state
        if state != .sleeping {
            state = .idle
        }
    }
    
    // MARK: - State Management
    func setState(_ newState: PetState) {
        guard state != newState else { return }
        
        // Check if personality allows this transition
        guard personalityEngine.shouldTransition(from: state, to: newState) else {
            return
        }
        
        // Record time pattern memory for state changes
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        MemoryManager.shared.recordTimePattern(hour: hour, minute: minute, activity: newState.rawValue)
        
        // Record activity preference based on state change
        let enjoyment: Double
        switch newState {
        case .playing, .dancing:
            enjoyment = 0.9
        case .eating:
            enjoyment = 0.8
        case .sleeping:
            enjoyment = 0.7
        case .watching:
            enjoyment = 0.6
        default:
            enjoyment = 0.5
        }
        MemoryManager.shared.recordActivityPreference(activityType: newState.rawValue, enjoyment: enjoyment)
        
        state = newState
        
        // State-specific effects on health/happiness
        switch newState {
        case .running:
            happiness = min(1.0, happiness + 0.04)
        case .eating:
            happiness = min(1.0, happiness + 0.06)
            health = min(1.0, health + 0.04)
        case .playing:
            happiness = min(1.0, happiness + 0.08)
        case .dragging, .dropped:
            // Neutral effects
            break
        case .dancing:
            happiness = min(1.0, happiness + 0.1)
        case .watching:
            happiness = min(1.0, happiness + 0.05)
        case .sitting:
            health = min(1.0, health + 0.02)
        case .sleeping:
            health = min(1.0, health + 0.05)
        default:
            break
        }
    }
    
    // MARK: - Health & Happiness
    func adjustHealth(_ delta: Double) {
        health = max(0.0, min(1.0, health + delta))
    }
    
    func adjustHappiness(_ delta: Double) {
        happiness = max(0.0, min(1.0, happiness + delta))
    }
    
    // MARK: - Random Activity Triggers
    func triggerRandomActivity() {
        // Don't interrupt certain states
        guard state != .sleeping && state != .dancing && state != .watching else {
            return
        }
        
        // Use personality to influence activity selection
        let activities: [PetState] = [.idle, .walking, .sitting, .playing]
        
        // Weight activities based on personality
        let weightedActivities: [(PetState, Double)] = activities.map { activity in
            let weight: Double
            switch activity {
            case .playing:
                weight = personalityEngine.playfulnessProbability()
            case .walking:
                weight = personalityEngine.curiosityProbability() * personalityEngine.activityFrequencyMultiplier()
            case .sitting:
                weight = 1.0 - personalityEngine.activityFrequencyMultiplier()
            default:
                weight = 0.5
            }
            return (activity, weight)
        }
        
        // Select based on weighted probabilities
        let totalWeight = weightedActivities.reduce(0.0) { $0 + $1.1 }
        let random = Double.random(in: 0...totalWeight)
        var cumulative: Double = 0
        
        for (activity, weight) in weightedActivities {
            cumulative += weight
            if random <= cumulative {
                setState(activity)
                return
            }
        }
        
        // Fallback
        if let randomActivity = activities.randomElement() {
            setState(randomActivity)
        }
    }
    
    // MARK: - Personality Updates
    func updatePersonality(_ newPersonality: PetPersonality) {
        personality = newPersonality.validated()
    }
}

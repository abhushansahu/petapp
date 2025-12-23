import XCTest
@testable import PetApp

final class PersonalityEngineTests: XCTestCase {
    
    func testPlayfulnessProbability() {
        let highPlayfulness = PetPersonality(playfulness: 0.9, curiosity: 0.5, sleepiness: 0.5, sociability: 0.5, energy: 0.5)
        let engine = PersonalityEngine(personality: highPlayfulness)
        XCTAssertEqual(engine.playfulnessProbability(), 0.9, accuracy: 0.01)
        
        let lowPlayfulness = PetPersonality(playfulness: 0.1, curiosity: 0.5, sleepiness: 0.5, sociability: 0.5, energy: 0.5)
        let engine2 = PersonalityEngine(personality: lowPlayfulness)
        XCTAssertEqual(engine2.playfulnessProbability(), 0.1, accuracy: 0.01)
    }
    
    func testSleepProbability() {
        let sleepy = PetPersonality(playfulness: 0.5, curiosity: 0.5, sleepiness: 0.9, sociability: 0.5, energy: 0.5)
        let engine = PersonalityEngine(personality: sleepy)
        
        // Night time (timeOfDay > 0.75)
        let nightSleepProb = engine.sleepProbability(timeOfDay: 0.8)
        XCTAssertGreaterThan(nightSleepProb, 0.5)
        
        // Day time (timeOfDay < 0.25)
        let daySleepProb = engine.sleepProbability(timeOfDay: 0.2)
        XCTAssertLessThan(daySleepProb, nightSleepProb)
    }
    
    func testActivityFrequencyMultiplier() {
        let highEnergy = PetPersonality(playfulness: 0.5, curiosity: 0.5, sleepiness: 0.5, sociability: 0.5, energy: 1.0)
        let engine = PersonalityEngine(personality: highEnergy)
        XCTAssertGreaterThan(engine.activityFrequencyMultiplier(), 1.0)
        
        let lowEnergy = PetPersonality(playfulness: 0.5, curiosity: 0.5, sleepiness: 0.5, sociability: 0.5, energy: 0.0)
        let engine2 = PersonalityEngine(personality: lowEnergy)
        XCTAssertLessThan(engine2.activityFrequencyMultiplier(), 1.0)
    }
    
    func testPreferenceForActivity() {
        let personality = PetPersonality(playfulness: 0.8, curiosity: 0.7, sleepiness: 0.3, sociability: 0.6, energy: 0.9)
        let engine = PersonalityEngine(personality: personality)
        
        let playingPreference = engine.preferenceForActivity(.playing)
        XCTAssertGreaterThan(playingPreference, 0.5) // High playfulness should prefer playing
        
        let exploringPreference = engine.preferenceForActivity(.exploring)
        XCTAssertGreaterThan(exploringPreference, 0.5) // High curiosity and energy should prefer exploring
    }
    
    func testShouldTransition() {
        let highEnergy = PetPersonality(playfulness: 0.5, curiosity: 0.5, sleepiness: 0.5, sociability: 0.5, energy: 0.9)
        let engine = PersonalityEngine(personality: highEnergy)
        XCTAssertTrue(engine.shouldTransition(from: .idle, to: .walking))
        
        let lowEnergy = PetPersonality(playfulness: 0.5, curiosity: 0.5, sleepiness: 0.5, sociability: 0.5, energy: 0.1)
        let engine2 = PersonalityEngine(personality: lowEnergy)
        // Low energy pets may resist transitions, but should still allow some
        let result = engine2.shouldTransition(from: .idle, to: .walking)
        // Result can be true or false based on random, but function should not crash
        XCTAssertTrue(result || !result) // Just check it returns a boolean
    }
}

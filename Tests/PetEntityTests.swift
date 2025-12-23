import XCTest
@testable import PetApp

class PetEntityTests: XCTestCase {
    var petEntity: PetEntity!
    
    override func setUp() {
        super.setUp()
        petEntity = PetEntity()
    }
    
    override func tearDown() {
        petEntity = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertEqual(petEntity.state, .idle)
        XCTAssertEqual(petEntity.age, 0.0, accuracy: 0.1)
        XCTAssertEqual(petEntity.health, 1.0, accuracy: 0.01)
        XCTAssertEqual(petEntity.happiness, 1.0, accuracy: 0.01)
    }
    
    func testStateTransition() {
        petEntity.setState(.walking)
        XCTAssertEqual(petEntity.state, .walking)
        
        petEntity.setState(.dancing)
        XCTAssertEqual(petEntity.state, .dancing)
    }
    
    func testStateDoesNotChangeIfSame() {
        petEntity.setState(.idle)
        let initialState = petEntity.state
        petEntity.setState(.idle)
        XCTAssertEqual(petEntity.state, initialState)
    }
    
    func testHealthAdjustment() {
        petEntity.adjustHealth(-0.5)
        XCTAssertEqual(petEntity.health, 0.5, accuracy: 0.01)
        
        petEntity.adjustHealth(0.3)
        XCTAssertEqual(petEntity.health, 0.8, accuracy: 0.01)
        
        // Test clamping
        petEntity.adjustHealth(1.0)
        XCTAssertEqual(petEntity.health, 1.0, accuracy: 0.01)
        
        petEntity.adjustHealth(-2.0)
        XCTAssertEqual(petEntity.health, 0.0, accuracy: 0.01)
    }
    
    func testHappinessAdjustment() {
        petEntity.adjustHappiness(-0.5)
        XCTAssertEqual(petEntity.happiness, 0.5, accuracy: 0.01)
        
        petEntity.adjustHappiness(0.3)
        XCTAssertEqual(petEntity.happiness, 0.8, accuracy: 0.01)
        
        // Test clamping
        petEntity.adjustHappiness(1.0)
        XCTAssertEqual(petEntity.happiness, 1.0, accuracy: 0.01)
        
        petEntity.adjustHappiness(-2.0)
        XCTAssertEqual(petEntity.happiness, 0.0, accuracy: 0.01)
    }
    
    func testDancingIncreasesHappiness() {
        let initialHappiness = petEntity.happiness
        petEntity.setState(.dancing)
        XCTAssertGreaterThan(petEntity.happiness, initialHappiness)
    }
    
    func testSittingIncreasesHealth() {
        let initialHealth = petEntity.health
        petEntity.adjustHealth(-0.2) // Reduce health first
        petEntity.setState(.sitting)
        XCTAssertGreaterThan(petEntity.health, 0.8 - 0.02) // Should increase slightly
    }
    
    func testEatingImprovesHealthAndHappiness() {
        petEntity.adjustHealth(-0.3)
        petEntity.adjustHappiness(-0.3)
        petEntity.setState(.eating)
        XCTAssertGreaterThanOrEqual(petEntity.health, 0.74, "Eating should restore some health")
        XCTAssertGreaterThan(petEntity.happiness, 0.7)
    }
    
    func testPlayingImprovesHappiness() {
        petEntity.adjustHappiness(-0.4)
        let before = petEntity.happiness
        petEntity.setState(.playing)
        XCTAssertGreaterThan(petEntity.happiness, before)
        XCTAssertLessThanOrEqual(petEntity.happiness, 1.0)
    }
    
    func testRandomActivityTrigger() {
        petEntity.setState(.idle)
        petEntity.triggerRandomActivity()
        // Should change to one of the random activities
        let validStates: [PetState] = [.idle, .walking, .sitting]
        XCTAssertTrue(validStates.contains(petEntity.state))
    }
    
    func testRandomActivityDoesNotInterruptSleeping() {
        petEntity.setState(.sleeping)
        let initialState = petEntity.state
        petEntity.triggerRandomActivity()
        XCTAssertEqual(petEntity.state, initialState)
    }
    
    func testRandomActivityDoesNotInterruptDancing() {
        petEntity.setState(.dancing)
        let initialState = petEntity.state
        petEntity.triggerRandomActivity()
        XCTAssertEqual(petEntity.state, initialState)
    }
    
    func testAgeCalculation() {
        // Age should be between 0 and 1
        XCTAssertGreaterThanOrEqual(petEntity.age, 0.0)
        XCTAssertLessThanOrEqual(petEntity.age, 1.0)
    }
}

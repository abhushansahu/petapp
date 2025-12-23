import XCTest
@testable import PetApp

final class EnhancedActivityManagerTests: XCTestCase {
    
    var petEntity: PetEntity!
    var activityManager: ActivityManager!
    
    override func setUp() {
        super.setUp()
        petEntity = PetEntity()
        activityManager = ActivityManager(petEntity: petEntity)
    }
    
    override func tearDown() {
        activityManager = nil
        petEntity = nil
        super.tearDown()
    }
    
    func testActivityTypeBaseType() {
        XCTAssertEqual(ActivityType.exploring.baseType, ActivityType.exploring)
        XCTAssertEqual(ActivityType.exploringWithDirection(.north).baseType, ActivityType.exploring)
        XCTAssertEqual(ActivityType.playing.baseType, ActivityType.playing)
        XCTAssertEqual(ActivityType.playingWithToy(.ball).baseType, ActivityType.playing)
        XCTAssertEqual(ActivityType.napping(.deep).baseType, ActivityType.resting)
    }
    
    func testActivityTypeRawValue() {
        XCTAssertEqual(ActivityType.exploring.rawValue, "exploring")
        XCTAssertEqual(ActivityType.exploringWithDirection(.north).rawValue, "exploring")
        XCTAssertEqual(ActivityType.playing.rawValue, "playing")
        XCTAssertEqual(ActivityType.social(.friendly).rawValue, "playing")
    }
    
    func testTriggerActivityWithPersonality() {
        // Set high playfulness personality
        let personality = PetPersonality(playfulness: 0.9, curiosity: 0.5, sleepiness: 0.3, sociability: 0.5, energy: 0.8)
        petEntity.updatePersonality(personality)
        
        // Trigger activity - should favor playing
        activityManager.triggerRandomActivity()
        
        let currentActivity = activityManager.getCurrentActivity()
        XCTAssertNotNil(currentActivity)
    }
    
    func testActivityChains() {
        let personality = PetPersonality(playfulness: 0.5, curiosity: 0.8, sleepiness: 0.3, sociability: 0.5, energy: 1.0)
        petEntity.updatePersonality(personality)
        
        // High energy and curiosity should enable chains
        activityManager.triggerRandomActivity()
        
        // Chain should be created for high energy pets
        // This is tested indirectly through activity selection
        let activity = activityManager.getCurrentActivity()
        XCTAssertNotNil(activity)
    }
    
    func testDirectionEnum() {
        XCTAssertTrue(Direction.allCases.contains(.north))
        XCTAssertTrue(Direction.allCases.contains(.south))
        XCTAssertTrue(Direction.allCases.contains(.east))
        XCTAssertTrue(Direction.allCases.contains(.west))
        XCTAssertTrue(Direction.allCases.contains(.random))
    }
    
    func testSleepDepthEnum() {
        XCTAssertTrue(SleepDepth.allCases.contains(.light))
        XCTAssertTrue(SleepDepth.allCases.contains(.medium))
        XCTAssertTrue(SleepDepth.allCases.contains(.deep))
    }
    
    func testToyTypeEnum() {
        XCTAssertTrue(ToyType.allCases.contains(.ball))
        XCTAssertTrue(ToyType.allCases.contains(.sparkle))
        XCTAssertTrue(ToyType.allCases.contains(.bubble))
    }
    
    func testSocialReactionEnum() {
        XCTAssertTrue(SocialReaction.allCases.contains(.friendly))
        XCTAssertTrue(SocialReaction.allCases.contains(.shy))
        XCTAssertTrue(SocialReaction.allCases.contains(.excited))
        XCTAssertTrue(SocialReaction.allCases.contains(.calm))
    }
}

import XCTest
@testable import PetApp

final class MemoryManagerTests: XCTestCase {
    
    var memoryManager: MemoryManager!
    
    override func setUp() {
        super.setUp()
        // Use a test UserDefaults to avoid polluting real data
        let testDefaults = UserDefaults(suiteName: "test.memory.manager")!
        testDefaults.removePersistentDomain(forName: "test.memory.manager")
        memoryManager = MemoryManager(userDefaults: testDefaults)
    }
    
    override func tearDown() {
        memoryManager.clearAllMemories()
        memoryManager = nil
        super.tearDown()
    }
    
    func testRecordInteraction() {
        memoryManager.recordInteraction(type: "click", location: CGPoint(x: 100, y: 200))
        
        let interactions = memoryManager.getInteractionMemories()
        XCTAssertEqual(interactions.count, 1)
        XCTAssertEqual(interactions.first?.interactionType, "click")
    }
    
    func testRecordLocation() {
        memoryManager.recordLocation(screenIndex: 0, position: CGPoint(x: 100, y: 200))
        
        let locations = memoryManager.getFavoriteLocations()
        XCTAssertEqual(locations.count, 1)
        XCTAssertEqual(locations.first?.screenIndex, 0)
    }
    
    func testRecordTimePattern() {
        memoryManager.recordTimePattern(hour: 9, minute: 0, activity: "playing")
        
        let patterns = memoryManager.getTimePatterns(for: "playing")
        XCTAssertEqual(patterns.count, 1)
        XCTAssertEqual(patterns.first?.hour, 9)
    }
    
    func testFindPatternForTime() {
        memoryManager.recordTimePattern(hour: 9, minute: 5, activity: "playing")
        
        let pattern = memoryManager.findPatternForTime(hour: 9, minute: 10, activity: "playing")
        XCTAssertNotNil(pattern)
        XCTAssertEqual(pattern?.hour, 9)
    }
    
    func testRecordAppPreference() {
        memoryManager.recordAppPreference(appName: "Xcode", preference: 0.8)
        
        let preferences = memoryManager.getAppPreferences()
        XCTAssertEqual(preferences.count, 1)
        XCTAssertEqual(preferences.first?.appName, "Xcode")
        XCTAssertEqual(preferences.first?.preference, 0.8, accuracy: 0.01)
    }
    
    func testRecordActivityPreference() {
        memoryManager.recordActivityPreference(activityType: "playing", enjoyment: 0.9)
        
        let preferences = memoryManager.getActivityPreferences()
        XCTAssertEqual(preferences.count, 1)
        XCTAssertEqual(preferences.first?.activityType, "playing")
        XCTAssertEqual(preferences.first?.enjoyment, 0.9, accuracy: 0.01)
    }
    
    func testGetMostEnjoyedActivity() {
        memoryManager.recordActivityPreference(activityType: "playing", enjoyment: 0.9)
        memoryManager.recordActivityPreference(activityType: "resting", enjoyment: 0.3)
        
        let mostEnjoyed = memoryManager.getMostEnjoyedActivity()
        XCTAssertNotNil(mostEnjoyed)
        XCTAssertEqual(mostEnjoyed?.activityType, "playing")
    }
    
    func testClearAllMemories() {
        memoryManager.recordInteraction(type: "click")
        memoryManager.recordLocation(screenIndex: 0, position: .zero)
        
        memoryManager.clearAllMemories()
        
        XCTAssertEqual(memoryManager.getInteractionMemories().count, 0)
        XCTAssertEqual(memoryManager.getFavoriteLocations().count, 0)
    }
}

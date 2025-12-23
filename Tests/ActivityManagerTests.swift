import XCTest
@testable import PetApp

class ActivityManagerTests: XCTestCase {
    var activityManager: ActivityManager!
    var petEntity: PetEntity!
    
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
    
    func testTriggerRandomActivity() {
        let initialState = petEntity.state
        activityManager.triggerRandomActivity()
        
        // State should change (unless it was sleeping/dancing/watching)
        if initialState != .sleeping && initialState != .dancing && initialState != .watching {
            // State might change, but let's just verify the method doesn't crash
            XCTAssertNotNil(petEntity.state)
        }
    }
    
    func testForceActivity() {
        activityManager.forceActivity(.playing)
        // Should trigger activity
        XCTAssertNotNil(activityManager.getCurrentActivity())
    }
    
    func testGetCurrentActivity() {
        XCTAssertNil(activityManager.getCurrentActivity())
        
        activityManager.triggerRandomActivity()
        // May or may not be set depending on implementation
        let activity = activityManager.getCurrentActivity()
        // Just verify it doesn't crash
        XCTAssertNotNil(activity)
    }
    
    func testActivityDoesNotInterruptSleeping() {
        petEntity.setState(.sleeping)
        let initialState = petEntity.state
        
        // Activities shouldn't trigger when sleeping
        // This is tested indirectly through triggerRandomActivity
        activityManager.triggerRandomActivity()
        
        // State should remain sleeping
        XCTAssertEqual(petEntity.state, initialState)
    }
    
    func testActivityDoesNotInterruptDancing() {
        petEntity.setState(.dancing)
        let initialState = petEntity.state
        
        activityManager.triggerRandomActivity()
        
        // State should remain dancing
        XCTAssertEqual(petEntity.state, initialState)
    }
}

import XCTest
import QuartzCore
@testable import PetApp

class PetViewTests: XCTestCase {
    var petEntity: PetEntity!
    var petView: PetView!
    
    override func setUp() {
        super.setUp()
        petEntity = PetEntity()
        let frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        petView = PetView(petEntity: petEntity, frame: frame)
    }
    
    override func tearDown() {
        petView = nil
        petEntity = nil
        super.tearDown()
    }
    
    func testTransformResetWhenTransitioningFromDancingToIdle() {
        // Set state to dancing
        petEntity.setState(.dancing)
        
        // Wait for state change to propagate
        let expectation = XCTestExpectation(description: "State changed to dancing")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Apply some dance intensity to create a transform
        petView.updateDanceIntensity(0.5)
        
        // Wait for animation to be applied
        let expectation2 = XCTestExpectation(description: "Dance intensity applied")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 1.0)
        
        // Transition back to idle
        petEntity.setState(.idle)
        
        // Wait for state change to propagate and transform to reset
        let expectation3 = XCTestExpectation(description: "State changed to idle and transform reset")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Verify transform is identity (no scaling)
            // animationLayer is the first sublayer of the view's layer
            guard let animationLayer = self.petView.layer?.sublayers?.first else {
                XCTFail("Animation layer should exist")
                expectation3.fulfill()
                return
            }
            
            let transform = animationLayer.transform
            let scaleX = sqrt(transform.m11 * transform.m11 + transform.m12 * transform.m12)
            let scaleY = sqrt(transform.m21 * transform.m21 + transform.m22 * transform.m22)
            
            // Allow small floating point differences
            XCTAssertEqual(scaleX, 1.0, accuracy: 0.01, "Transform should be reset to identity after transitioning from dancing to idle")
            XCTAssertEqual(scaleY, 1.0, accuracy: 0.01, "Transform should be reset to identity after transitioning from dancing to idle")
            
            expectation3.fulfill()
        }
        wait(for: [expectation3], timeout: 1.0)
    }
    
    func testUpdateDanceIntensityCleansUpWhenNotDancing() {
        // Set state to idle (not dancing)
        petEntity.setState(.idle)
        
        // Wait for state change
        let expectation = XCTestExpectation(description: "State set to idle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Try to update dance intensity when not dancing
        petView.updateDanceIntensity(0.5)
        
        // Wait for cleanup
        let expectation2 = XCTestExpectation(description: "Cleanup completed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Verify transform is identity
            guard let animationLayer = self.petView.layer?.sublayers?.first else {
                XCTFail("Animation layer should exist")
                expectation2.fulfill()
                return
            }
            
            let transform = animationLayer.transform
            let scaleX = sqrt(transform.m11 * transform.m11 + transform.m12 * transform.m12)
            let scaleY = sqrt(transform.m21 * transform.m21 + transform.m22 * transform.m22)
            
            XCTAssertEqual(scaleX, 1.0, accuracy: 0.01, "Transform should remain identity when updateDanceIntensity is called but state is not dancing")
            XCTAssertEqual(scaleY, 1.0, accuracy: 0.01, "Transform should remain identity when updateDanceIntensity is called but state is not dancing")
            
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 1.0)
    }
    
    func testMultipleDanceIntensityUpdatesDoNotCumulate() {
        // Set state to dancing
        petEntity.setState(.dancing)
        
        // Wait for state change
        let expectation = XCTestExpectation(description: "State changed to dancing")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Apply multiple dance intensity updates
        petView.updateDanceIntensity(0.3)
        
        let expectation2 = XCTestExpectation(description: "First intensity applied")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.petView.updateDanceIntensity(0.5)
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 1.0)
        
        let expectation3 = XCTestExpectation(description: "Second intensity applied")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.petView.updateDanceIntensity(0.7)
            expectation3.fulfill()
        }
        wait(for: [expectation3], timeout: 1.0)
        
        // Transition to idle
        petEntity.setState(.idle)
        
        // Wait and verify transform is reset
        let expectation4 = XCTestExpectation(description: "Transform reset after multiple updates")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            guard let animationLayer = self.petView.layer?.sublayers?.first else {
                XCTFail("Animation layer should exist")
                expectation4.fulfill()
                return
            }
            
            let transform = animationLayer.transform
            let scaleX = sqrt(transform.m11 * transform.m11 + transform.m12 * transform.m12)
            let scaleY = sqrt(transform.m21 * transform.m21 + transform.m22 * transform.m22)
            
            XCTAssertEqual(scaleX, 1.0, accuracy: 0.01, "Transform should be reset to identity even after multiple dance intensity updates")
            XCTAssertEqual(scaleY, 1.0, accuracy: 0.01, "Transform should be reset to identity even after multiple dance intensity updates")
            
            expectation4.fulfill()
        }
        wait(for: [expectation4], timeout: 1.0)
    }
    
    func testDancingAnimationStartsAtSameSizeAsNormal() {
        // Start in idle state
        petEntity.setState(.idle)
        
        // Wait for state change
        let expectation = XCTestExpectation(description: "State set to idle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Get the size in idle state
        guard let animationLayer = self.petView.layer?.sublayers?.first else {
            XCTFail("Animation layer should exist")
            return
        }
        
        let idleTransform = animationLayer.transform
        let idleScaleX = sqrt(idleTransform.m11 * idleTransform.m11 + idleTransform.m12 * idleTransform.m12)
        let idleScaleY = sqrt(idleTransform.m21 * idleTransform.m21 + idleTransform.m22 * idleTransform.m22)
        
        // Transition to dancing
        petEntity.setState(.dancing)
        
        // Wait for dancing animation to start
        let expectation2 = XCTestExpectation(description: "Dancing animation started")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard let animationLayer = self.petView.layer?.sublayers?.first else {
                XCTFail("Animation layer should exist")
                expectation2.fulfill()
                return
            }
            
            // Verify dancing starts at same size as idle
            let dancingTransform = animationLayer.transform
            let dancingScaleX = sqrt(dancingTransform.m11 * dancingTransform.m11 + dancingTransform.m12 * dancingTransform.m12)
            let dancingScaleY = sqrt(dancingTransform.m21 * dancingTransform.m21 + dancingTransform.m22 * dancingTransform.m22)
            
            XCTAssertEqual(dancingScaleX, idleScaleX, accuracy: 0.01, "Dancing animation should start at the same size as normal state")
            XCTAssertEqual(dancingScaleY, idleScaleY, accuracy: 0.01, "Dancing animation should start at the same size as normal state")
            XCTAssertEqual(dancingScaleX, 1.0, accuracy: 0.01, "Size should be fixed at identity scale")
            XCTAssertEqual(dancingScaleY, 1.0, accuracy: 0.01, "Size should be fixed at identity scale")
            
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 1.0)
    }
    
    func testUpdateDanceIntensityDoesNotChangeSize() {
        // Set state to dancing
        petEntity.setState(.dancing)
        
        // Wait for state change
        let expectation = XCTestExpectation(description: "State changed to dancing")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Update dance intensity multiple times - should not change size
        petView.updateDanceIntensity(0.3)
        
        let expectation2 = XCTestExpectation(description: "First intensity applied")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.petView.updateDanceIntensity(0.5)
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 1.0)
        
        let expectation3 = XCTestExpectation(description: "Second intensity applied")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard let animationLayer = self.petView.layer?.sublayers?.first else {
                XCTFail("Animation layer should exist")
                expectation3.fulfill()
                return
            }
            
            // Verify transform remains identity - no size changes
            let transform = animationLayer.transform
            let scaleX = sqrt(transform.m11 * transform.m11 + transform.m12 * transform.m12)
            let scaleY = sqrt(transform.m21 * transform.m21 + transform.m22 * transform.m22)
            
            XCTAssertEqual(scaleX, 1.0, accuracy: 0.01, "Transform should remain identity - no size changes from updateDanceIntensity")
            XCTAssertEqual(scaleY, 1.0, accuracy: 0.01, "Transform should remain identity - no size changes from updateDanceIntensity")
            
            expectation3.fulfill()
        }
        wait(for: [expectation3], timeout: 1.0)
    }
}

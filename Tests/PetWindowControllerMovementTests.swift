import XCTest
@testable import PetApp

final class PetWindowControllerMovementTests: XCTestCase {
    func testLimitedVelocityClampsMagnitude() {
        let controller = PetWindowController()
        let limited = controller.limitedVelocity(CGVector(dx: 5, dy: 4), maxSpeed: 3)
        let magnitude = sqrt(limited.dx * limited.dx + limited.dy * limited.dy)
        XCTAssertLessThanOrEqual(magnitude, 3.0001)
    }
    
    func testClampedOriginInvertsVelocityOnHit() {
        let controller = PetWindowController()
        let frame = NSRect(x: 0, y: 0, width: 200, height: 200)
        let size = CGSize(width: 80, height: 80)
        
        let result = controller.clampedOrigin(
            for: NSPoint(x: -10, y: -5),
            size: size,
            within: frame,
            velocity: CGVector(dx: -2, dy: -3),
            invertingVelocityOnHit: true
        )
        
        XCTAssertEqual(result.origin.x, frame.minX)
        XCTAssertEqual(result.origin.y, frame.minY)
        XCTAssertGreaterThanOrEqual(result.velocity.dx, 0)
        XCTAssertGreaterThanOrEqual(result.velocity.dy, 0)
    }
}

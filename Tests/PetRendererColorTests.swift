import XCTest
@testable import PetApp

final class PetRendererColorTests: XCTestCase {
    func testInterpolateColorHandlesSystemColors() {
        let renderer = PetRenderer(size: CGSize(width: 100, height: 100))
        let blended = renderer.interpolateColor(from: .systemBlue, to: .systemGreen, factor: 0.5)
        XCTAssertNotNil(blended.usingColorSpace(.deviceRGB))
    }
    
    func testInterpolateColorClampsFactor() {
        let renderer = PetRenderer(size: CGSize(width: 100, height: 100))
        let color = renderer.interpolateColor(from: NSColor(red: 0, green: 0, blue: 0, alpha: 1),
                                              to: NSColor(red: 1, green: 1, blue: 1, alpha: 1),
                                              factor: 2.0) // intentionally > 1
        // Should clamp to white instead of overshooting
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        XCTAssertTrue(color.usingColorSpace(.deviceRGB)?.getRed(&red, green: &green, blue: &blue, alpha: &alpha) ?? false)
        XCTAssertEqual(red, 1.0, accuracy: 0.001)
        XCTAssertEqual(green, 1.0, accuracy: 0.001)
        XCTAssertEqual(blue, 1.0, accuracy: 0.001)
    }
    
    func testSnapToPixelRoundsToNearestPixelSize() {
        let renderer = PetRenderer(size: CGSize(width: 100, height: 100))
        // pixel size will be floor(100/40) = 2
        let snapped = renderer.debugSnapToPixel(3.4)
        XCTAssertEqual(snapped, 4.0, accuracy: 0.0001)
    }
}

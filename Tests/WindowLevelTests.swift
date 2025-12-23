import XCTest
import AppKit
import CoreGraphics
@testable import PetApp

final class WindowLevelTests: XCTestCase {
    func testDesktopIconLevelMatchesCGLevel() {
        let expected = Int(kCGDesktopWindowLevel) + 1
        XCTAssertEqual(NSWindow.Level.desktopIcon.rawValue, expected)
    }
}

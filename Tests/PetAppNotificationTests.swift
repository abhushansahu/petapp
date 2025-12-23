import XCTest
@testable import PetApp

final class PetAppNotificationTests: XCTestCase {
    struct StubBundle: BundleInfoProviding {
        var bundleIdentifier: String?
        var bundleURL: URL
    }
    
    func testIsRunningFromAppBundleReturnsFalseForNonAppPath() {
        let stub = StubBundle(bundleIdentifier: "com.test.app", bundleURL: URL(fileURLWithPath: "/tmp/Debug"))
        XCTAssertFalse(PetApp.isRunningFromAppBundle(bundle: stub))
    }
    
    func testIsRunningFromAppBundleReturnsFalseWhenIdentifierMissing() {
        let stub = StubBundle(bundleIdentifier: nil, bundleURL: URL(fileURLWithPath: "/tmp/MyApp.app"))
        XCTAssertFalse(PetApp.isRunningFromAppBundle(bundle: stub))
    }
    
    func testIsRunningFromAppBundleReturnsTrueForValidBundle() {
        let stub = StubBundle(bundleIdentifier: "com.test.app", bundleURL: URL(fileURLWithPath: "/tmp/MyApp.app"))
        XCTAssertTrue(PetApp.isRunningFromAppBundle(bundle: stub))
    }
}

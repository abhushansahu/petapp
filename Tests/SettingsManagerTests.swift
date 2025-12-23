import XCTest
@testable import PetApp

final class SettingsManagerTests: XCTestCase {
    override func tearDown() async throws {
        // Clean up all custom suites to avoid cross-test pollution
        UserDefaults.standard.removePersistentDomain(forName: "SettingsManagerTests-defaults")
        UserDefaults.standard.removePersistentDomain(forName: "SettingsManagerTests-persist")
        UserDefaults.standard.removePersistentDomain(forName: "SettingsManagerTests-migration")
        UserDefaults.standard.removePersistentDomain(forName: "SettingsManagerTests-notifications")
    }
    
    func testDefaultsLoadWhenNoSavedData() {
        let suiteName = "SettingsManagerTests-defaults"
        let suite = UserDefaults(suiteName: suiteName)!
        suite.removePersistentDomain(forName: suiteName)
        
        let manager = SettingsManager(userDefaults: suite)
        XCTAssertEqual(manager.settings, .default)
        XCTAssertEqual(manager.settings.schemaVersion, PetSettings.currentSchemaVersion)
    }
    
    func testSettingsPersistAndReload() {
        let suiteName = "SettingsManagerTests-persist"
        let suite = UserDefaults(suiteName: suiteName)!
        suite.removePersistentDomain(forName: suiteName)
        
        let manager = SettingsManager(userDefaults: suite)
        var custom = PetSettings.default
        custom.petName = "Luna"
        custom.petSize = 120
        custom.showParticles = false
        custom.effectsIntensity = 0.4
        custom.activityFrequencyMinutes = 3
        custom.interactionProximity = 150
        custom.focusApps = ["Xcode", "Safari"]
        custom.reminders.healthRemindersEnabled = false
        custom.reminders.customRemindersEnabled = false
        
        manager.set(custom)
        
        // Recreate manager with same suite to verify persistence and validation stability
        let reloaded = SettingsManager(userDefaults: suite)
        XCTAssertEqual(reloaded.settings, custom)
    }
    
    func testLegacySettingsAreMigratedAndSavedToNewKey() throws {
        struct LegacySettings: Codable, Equatable {
            var petName: String
            var petSize: Double
            var showParticles: Bool
            var effectsIntensity: Double
            var activityFrequencyMinutes: Int
            var interactionProximity: Double
            var focusApps: [String]
        }
        
        let suiteName = "SettingsManagerTests-migration"
        let suite = UserDefaults(suiteName: suiteName)!
        suite.removePersistentDomain(forName: suiteName)
        
        // Seed legacy data under old key
        let legacy = LegacySettings(
            petName: "Legacy",
            petSize: 180,
            showParticles: true,
            effectsIntensity: 0.6,
            activityFrequencyMinutes: 5,
            interactionProximity: 200,
            focusApps: ["Notes"]
        )
        let legacyData = try JSONEncoder().encode(legacy)
        suite.set(legacyData, forKey: "pet.settings.v1")
        
        let manager = SettingsManager(userDefaults: suite)
        let settings = manager.settings
        
        XCTAssertEqual(settings.petName, "Legacy")
        XCTAssertEqual(settings.petSize, 180)
        XCTAssertEqual(settings.activityFrequencyMinutes, 5)
        XCTAssertEqual(settings.focusApps, ["Notes"])
        XCTAssertEqual(settings.schemaVersion, PetSettings.currentSchemaVersion)
        
        // New key should be populated after migration
        XCTAssertNotNil(suite.data(forKey: "pet.settings.v2"))
    }
    
    func testChangeNotificationEmittedOnUpdate() {
        let suiteName = "SettingsManagerTests-notifications"
        let suite = UserDefaults(suiteName: suiteName)!
        suite.removePersistentDomain(forName: suiteName)
        
        let manager = SettingsManager(userDefaults: suite)
        let expectation = expectation(description: "SettingsManager change notification")
        let token = NotificationCenter.default.addObserver(forName: SettingsManager.didChangeNotification, object: manager, queue: .main) { _ in
            expectation.fulfill()
        }
        
        manager.update { $0.petName = "Ping" }
        
        waitForExpectations(timeout: 1.0)
        NotificationCenter.default.removeObserver(token)
    }
    
    func testValidationClampsValues() {
        let suiteName = "SettingsManagerTests-validation"
        let suite = UserDefaults(suiteName: suiteName)!
        suite.removePersistentDomain(forName: suiteName)
        
        let manager = SettingsManager(userDefaults: suite)
        manager.update {
            $0.petSize = 20       // too small
            $0.effectsIntensity = 2.0
            $0.activityFrequencyMinutes = -5
            $0.interactionProximity = 1000
            $0.focusApps = ["", "Safari", "Safari", "Xcode  "]
            $0.petName = "   "    // invalid name, should fall back to default
        }
        
        XCTAssertEqual(manager.settings.petSize, 72)
        XCTAssertEqual(manager.settings.effectsIntensity, 1.0)
        XCTAssertEqual(manager.settings.activityFrequencyMinutes, 1)
        XCTAssertEqual(manager.settings.interactionProximity, 260)
        XCTAssertEqual(manager.settings.focusApps, ["Safari", "Xcode"])
        XCTAssertEqual(manager.settings.petName, PetSettings.default.petName)
    }
}

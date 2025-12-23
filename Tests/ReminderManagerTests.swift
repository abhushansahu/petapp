import XCTest
@testable import PetApp

class ReminderManagerTests: XCTestCase {
    struct StubBundle: BundleInfoProviding {
        var bundleIdentifier: String?
        var bundleURL: URL
    }
    
    var reminderManager: ReminderManager!
    var petEntity: PetEntity!
    
    override func setUp() {
        super.setUp()
        reminderManager = ReminderManager()
        petEntity = PetEntity()
        reminderManager.setPetEntity(petEntity)
    }
    
    override func tearDown() {
        reminderManager = nil
        petEntity = nil
        super.tearDown()
    }
    
    func testAddReminder() {
        let reminder = Reminder(type: .health(type: .drinkWater))
        reminderManager.addReminder(reminder)
        
        let reminders = reminderManager.getAllReminders()
        XCTAssertTrue(reminders.contains { $0.id == reminder.id })
    }
    
    func testRemoveReminder() {
        let reminder = Reminder(type: .health(type: .drinkWater))
        reminderManager.addReminder(reminder)
        
        reminderManager.removeReminder(reminder.id)
        
        let reminders = reminderManager.getAllReminders()
        XCTAssertFalse(reminders.contains { $0.id == reminder.id })
    }
    
    func testDefaultReminders() {
        let reminders = reminderManager.getAllReminders()
        XCTAssertGreaterThan(reminders.count, 0, "Should have default reminders")
    }
    
    func testCustomReminder() {
        let futureDate = Date().addingTimeInterval(3600) // 1 hour from now
        let reminder = Reminder(type: .custom(date: futureDate, title: "Test", message: "Test message"))
        reminderManager.addReminder(reminder)
        
        let reminders = reminderManager.getAllReminders()
        XCTAssertTrue(reminders.contains { $0.id == reminder.id })
    }
    
    func testTimeBasedReminder() {
        let reminder = Reminder(type: .timeBased(interval: 60.0))
        reminderManager.addReminder(reminder)
        
        let reminders = reminderManager.getAllReminders()
        XCTAssertTrue(reminders.contains { $0.id == reminder.id })
    }
    
    func testUpdateReminder() {
        let reminder = Reminder(type: .health(type: .drinkWater))
        reminderManager.addReminder(reminder)
        
        var updatedReminder = reminder
        updatedReminder.isActive = false
        reminderManager.updateReminder(updatedReminder)
        
        let reminders = reminderManager.getAllReminders()
        if let found = reminders.first(where: { $0.id == reminder.id }) {
            XCTAssertFalse(found.isActive)
        } else {
            XCTFail("Reminder not found")
        }
    }
    
    func testNotificationsDisabledWhenNotAppBundle() {
        let stub = StubBundle(bundleIdentifier: "com.test.pet", bundleURL: URL(fileURLWithPath: "/tmp/Debug"))
        let manager = ReminderManager(bundleProvider: stub)
        XCTAssertFalse(manager.notificationsEnabled)
    }
}

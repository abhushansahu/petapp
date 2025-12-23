import Foundation
import UserNotifications
import Combine

class ReminderManager: NSObject, UNUserNotificationCenterDelegate {
    private var reminders: [Reminder] = []
    private var timers: [UUID: Timer] = [:]
    private var petEntity: PetEntity?
    private let bundleProvider: BundleInfoProviding
    private let notificationCenter: UNUserNotificationCenter?
    internal let notificationsEnabled: Bool
    
    var onReminderTriggered: ((Reminder) -> Void)?
    
    convenience override init() {
        self.init(bundleProvider: Bundle.main)
    }
    
    init(bundleProvider: BundleInfoProviding) {
        self.bundleProvider = bundleProvider
        self.notificationsEnabled = PetApp.isRunningFromAppBundle(bundle: bundleProvider)
        self.notificationCenter = notificationsEnabled ? UNUserNotificationCenter.current() : nil
        super.init()
        
        if notificationsEnabled {
            notificationCenter?.delegate = self
            requestPermissions()
        } else {
            NSLog("ReminderManager: notifications disabled because app is not running from a bundled .app (bundleURL: \(bundleProvider.bundleURL))")
        }
        
        // Setup default reminders
        setupDefaultReminders()
    }
    
    func setPetEntity(_ entity: PetEntity) {
        self.petEntity = entity
    }
    
    // MARK: - Permissions
    private func requestPermissions() {
        notificationCenter?.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    // MARK: - Default Reminders
    private func setupDefaultReminders() {
        // Hourly break reminder
        let hourlyBreak = Reminder(type: .health(type: .takeBreak))
        addReminder(hourlyBreak)
        
        // Water reminder (every hour)
        let waterReminder = Reminder(type: .health(type: .drinkWater))
        addReminder(waterReminder)
        
        // Stretch reminder (every 1.5 hours)
        let stretchReminder = Reminder(type: .health(type: .stretch))
        addReminder(stretchReminder)
        
        // Posture reminder (every 45 minutes)
        let postureReminder = Reminder(type: .health(type: .posture))
        addReminder(postureReminder)
    }
    
    // MARK: - Reminder Management
    func addReminder(_ reminder: Reminder) {
        reminders.append(reminder)
        scheduleReminder(reminder)
    }
    
    func removeReminder(_ id: UUID) {
        reminders.removeAll { $0.id == id }
        timers[id]?.invalidate()
        timers.removeValue(forKey: id)
        
        // Cancel notification
        notificationCenter?.removePendingNotificationRequests(withIdentifiers: [id.uuidString])
    }
    
    func updateReminder(_ reminder: Reminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index] = reminder
            
            // Reschedule
            timers[reminder.id]?.invalidate()
            scheduleReminder(reminder)
        }
    }
    
    func getAllReminders() -> [Reminder] {
        return reminders
    }
    
    // MARK: - Scheduling
    private func scheduleReminder(_ reminder: Reminder) {
        guard reminder.isActive else { return }
        
        switch reminder.type {
        case .timeBased(let interval):
            scheduleTimeBasedReminder(reminder, interval: interval)
            
        case .custom(let date, let title, let message):
            scheduleCustomReminder(reminder, date: date, title: title, message: message)
            
        case .health(let type):
            scheduleHealthReminder(reminder, type: type)
        }
    }
    
    private func scheduleTimeBasedReminder(_ reminder: Reminder, interval: TimeInterval) {
        // Check if enough time has passed since last trigger
        if let lastTriggered = reminder.lastTriggered {
            let timeSinceLastTrigger = Date().timeIntervalSince(lastTriggered)
            if timeSinceLastTrigger < interval {
                // Schedule for remaining time
                let remainingTime = interval - timeSinceLastTrigger
                scheduleTimer(reminder, interval: remainingTime)
                return
            }
        }
        
        scheduleTimer(reminder, interval: interval)
    }
    
    private func scheduleHealthReminder(_ reminder: Reminder, type: HealthReminderType) {
        let interval = type.defaultInterval
        
        // Check if enough time has passed since last trigger
        if let lastTriggered = reminder.lastTriggered {
            let timeSinceLastTrigger = Date().timeIntervalSince(lastTriggered)
            if timeSinceLastTrigger < interval {
                let remainingTime = interval - timeSinceLastTrigger
                scheduleTimer(reminder, interval: remainingTime, title: type.title, message: type.message)
                return
            }
        }
        
        scheduleTimer(reminder, interval: interval, title: type.title, message: type.message)
    }
    
    private func scheduleCustomReminder(_ reminder: Reminder, date: Date, title: String, message: String) {
        let timeUntilDate = date.timeIntervalSinceNow
        
        guard timeUntilDate > 0 else {
            // Date has passed, trigger immediately
            triggerReminder(reminder, title: title, message: message)
            return
        }
        
        scheduleTimer(reminder, interval: timeUntilDate, title: title, message: message)
        
        // Also schedule notification
        scheduleNotification(reminder, date: date, title: title, message: message)
    }
    
    private func scheduleTimer(_ reminder: Reminder, interval: TimeInterval, title: String? = nil, message: String? = nil) {
        timers[reminder.id]?.invalidate()
        
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.triggerReminder(reminder, title: title, message: message)
        }
        
        timers[reminder.id] = timer
    }
    
    private func triggerReminder(_ reminder: Reminder, title: String?, message: String?) {
        // Update last triggered time
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index].lastTriggered = Date()
        }
        
        // Determine title and message
        let finalTitle: String
        let finalMessage: String
        
        if let title = title, let message = message {
            finalTitle = title
            finalMessage = message
        } else {
            switch reminder.type {
            case .health(let type):
                finalTitle = type.title
                finalMessage = type.message
            case .custom(_, let customTitle, let customMessage):
                finalTitle = customTitle
                finalMessage = customMessage
            case .timeBased:
                finalTitle = "Reminder"
                finalMessage = "Your pet has a reminder for you!"
            }
        }
        
        // Send notification
        sendNotification(title: finalTitle, message: finalMessage, reminderId: reminder.id)
        
        // Trigger callback
        onReminderTriggered?(reminder)
        
        // Trigger pet animation
        petEntity?.triggerRandomActivity()
        
        // Reschedule if it's a repeating reminder
        if reminder.isActive {
            switch reminder.type {
            case .timeBased(let interval):
                scheduleTimeBasedReminder(reminder, interval: interval)
            case .health(let type):
                scheduleHealthReminder(reminder, type: type)
            case .custom:
                // Custom reminders don't repeat automatically
                break
            }
        }
    }
    
    // MARK: - Notifications
    private func scheduleNotification(_ reminder: Reminder, date: Date, title: String, message: String) {
        guard notificationsEnabled, let notificationCenter else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: reminder.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    private func sendNotification(title: String, message: String, reminderId: UUID) {
        guard notificationsEnabled, let notificationCenter else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: reminderId.uuidString,
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is active
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap
        if let reminderId = UUID(uuidString: response.notification.request.identifier),
           let reminder = reminders.first(where: { $0.id == reminderId }) {
            onReminderTriggered?(reminder)
        }
        completionHandler()
    }
    
    deinit {
        timers.values.forEach { $0.invalidate() }
    }
}

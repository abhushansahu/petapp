import Foundation

final class SettingsManager {
    static let shared = SettingsManager()
    
    static let didChangeNotification = Notification.Name("SettingsManager.didChange")
    
    private static let storageKey = "pet.settings.v2"
    private static let legacyKeys = ["pet.settings.v1"]
    
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private(set) var settings: PetSettings {
        didSet {
            guard oldValue != settings else { return }
            persist()
            notifyChange()
        }
    }
    
    // MARK: - Init
    init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults
        
        let loaded = SettingsManager.load(from: userDefaults, decoder: decoder) ?? .default
        let validated = loaded.validated()
        self.settings = validated
        
        let migratedFromLegacy = SettingsManager.hasLegacyData(in: userDefaults)
        if migratedFromLegacy || loaded != validated || !SettingsManager.hasData(for: SettingsManager.storageKey, in: userDefaults) {
            persist()
        }
    }
    
    // MARK: - Public API
    func update(_ transform: (inout PetSettings) -> Void) {
        var copy = settings
        transform(&copy)
        set(copy)
    }
    
    func set(_ settings: PetSettings) {
        let validated = settings.validated()
        guard validated != self.settings else { return }
        self.settings = validated
    }
    
    // MARK: - Persistence
    private func persist() {
        let normalized = settings.withCurrentSchemaVersion()
        guard let data = try? encoder.encode(normalized) else { return }
        defaults.set(data, forKey: SettingsManager.storageKey)
    }
    
    private func notifyChange() {
        NotificationCenter.default.post(name: SettingsManager.didChangeNotification, object: self)
    }
    
    private static func load(from defaults: UserDefaults, decoder: JSONDecoder) -> PetSettings? {
        // Prefer new key first
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? decoder.decode(PetSettings.self, from: data) {
            return decoded
        }
        
        // Fallback to legacy keys
        for key in legacyKeys {
            if let data = defaults.data(forKey: key),
               let decoded = try? decoder.decode(PetSettings.self, from: data) {
                return decoded
            }
        }
        
        return nil
    }
    
    private static func hasData(for key: String, in defaults: UserDefaults) -> Bool {
        return defaults.object(forKey: key) != nil
    }
    
    private static func hasLegacyData(in defaults: UserDefaults) -> Bool {
        return legacyKeys.contains { defaults.object(forKey: $0) != nil }
    }
}

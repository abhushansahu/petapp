import SwiftUI

final class SettingsViewModel: ObservableObject {
    @Published var settings: PetSettings {
        didSet { settingsManager.set(settings) }
    }
    
    private let settingsManager: SettingsManager
    
    init(settingsManager: SettingsManager = .shared) {
        self.settingsManager = settingsManager
        self.settings = settingsManager.settings
    }
}

struct PreferencesView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var focusAppsText: String
    @State private var selectedTab: Int = 0
    
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        _focusAppsText = State(initialValue: viewModel.settings.focusApps.joined(separator: ", "))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Tamagotchi Settings")
                .font(.title2)
                .bold()
                .padding(.bottom, 8)
            
            Picker("", selection: $selectedTab) {
                Text("Appearance").tag(0)
                Text("Personality").tag(1)
                Text("Behavior").tag(2)
                Text("Memory").tag(3)
                Text("Focus Apps").tag(4)
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 16)
            
            TabView(selection: $selectedTab) {
                appearanceTab
                    .tag(0)
                personalityTab
                    .tag(1)
                behaviorTab
                    .tag(2)
                memoryTab
                    .tag(3)
                focusAppsTab
                    .tag(4)
            }
            .frame(height: 350)
        }
        .padding(20)
        .frame(width: 500, height: 480)
    }
    
    private var appearanceTab: some View {
        Form {
            Section(header: Text("Appearance")) {
                TextField("Pet Name", text: binding(\.petName))
                HStack {
                    Text("Size")
                    Slider(value: binding(\.petSize), in: 64...160, step: 2)
                    Text("\(Int(viewModel.settings.petSize)) pt")
                        .font(.system(.body, design: .monospaced))
                }
                Toggle("Enable Particles", isOn: binding(\.showParticles))
                HStack {
                    Text("Effects Intensity")
                    Slider(value: binding(\.effectsIntensity), in: 0...1, step: 0.05)
                    Text(String(format: "%.2f", viewModel.settings.effectsIntensity))
                        .font(.system(.body, design: .monospaced))
                }
            }
        }
    }
    
    private var personalityTab: some View {
        Form {
            Section(header: Text("Personality Traits")) {
                HStack {
                    Text("Playfulness")
                    Spacer()
                    Slider(value: Binding(
                        get: { viewModel.settings.personality.playfulness },
                        set: { viewModel.settings.personality.playfulness = $0 }
                    ), in: 0...1, step: 0.05)
                    Text(String(format: "%.0f%%", viewModel.settings.personality.playfulness * 100))
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 50)
                }
                HStack {
                    Text("Curiosity")
                    Spacer()
                    Slider(value: Binding(
                        get: { viewModel.settings.personality.curiosity },
                        set: { viewModel.settings.personality.curiosity = $0 }
                    ), in: 0...1, step: 0.05)
                    Text(String(format: "%.0f%%", viewModel.settings.personality.curiosity * 100))
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 50)
                }
                HStack {
                    Text("Sleepiness")
                    Spacer()
                    Slider(value: Binding(
                        get: { viewModel.settings.personality.sleepiness },
                        set: { viewModel.settings.personality.sleepiness = $0 }
                    ), in: 0...1, step: 0.05)
                    Text(String(format: "%.0f%%", viewModel.settings.personality.sleepiness * 100))
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 50)
                }
                HStack {
                    Text("Sociability")
                    Spacer()
                    Slider(value: Binding(
                        get: { viewModel.settings.personality.sociability },
                        set: { viewModel.settings.personality.sociability = $0 }
                    ), in: 0...1, step: 0.05)
                    Text(String(format: "%.0f%%", viewModel.settings.personality.sociability * 100))
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 50)
                }
                HStack {
                    Text("Energy")
                    Spacer()
                    Slider(value: Binding(
                        get: { viewModel.settings.personality.energy },
                        set: { viewModel.settings.personality.energy = $0 }
                    ), in: 0...1, step: 0.05)
                    Text(String(format: "%.0f%%", viewModel.settings.personality.energy * 100))
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 50)
                }
            }
        }
    }
    
    private var behaviorTab: some View {
        Form {
            Section(header: Text("Behavior")) {
                Stepper(
                    value: binding(\.activityFrequencyMinutes),
                    in: 1...10,
                    step: 1
                ) {
                    Text("Activity Frequency: every \(viewModel.settings.activityFrequencyMinutes) min")
                }
                HStack {
                    Text("Interaction Radius")
                    Slider(value: binding(\.interactionProximity), in: 60...240, step: 5)
                    Text("\(Int(viewModel.settings.interactionProximity)) px")
                        .font(.system(.body, design: .monospaced))
                }
            }
        }
    }
    
    private var memoryTab: some View {
        let memoryManager = MemoryManager.shared
        let interactions = memoryManager.getInteractionMemories().count
        let locations = memoryManager.getFavoriteLocations().count
        let activityPrefs = memoryManager.getActivityPreferences().count
        
        return Form {
            Section(header: Text("Memory Statistics")) {
                Text("Interactions: \(interactions)")
                Text("Favorite Locations: \(locations)")
                Text("Activity Preferences: \(activityPrefs)")
            }
            
            Section(header: Text("Memory Management")) {
                Button("Clear All Memories") {
                    memoryManager.clearAllMemories()
                }
            }
        }
    }
    
    private var focusAppsTab: some View {
        Form {
            Section(header: Text("Focus Apps")) {
                TextEditor(text: $focusAppsText)
                    .frame(height: 80)
                    .font(.system(.body, design: .monospaced))
                    .onChange(of: focusAppsText) { newValue in
                        let apps = newValue
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                        viewModel.settings.focusApps = apps
                    }
                Text("Comma-separated list used to trigger focus mode.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Helpers
    private func binding<Value>(_ keyPath: WritableKeyPath<PetSettings, Value>) -> Binding<Value> {
        Binding(
            get: { viewModel.settings[keyPath: keyPath] },
            set: { viewModel.settings[keyPath: keyPath] = $0 }
        )
    }
}

#if DEBUG
struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView(viewModel: SettingsViewModel())
            .frame(width: 420, height: 420)
    }
}
#endif

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppSettingsKey.recommendation) private var recommendation = true
    @AppStorage(AppSettingsKey.shortVideoSeconds) private var shortVideoSeconds = 2
    @AppStorage(AppSettingsKey.appearance) private var appearance = AppearanceMode.system.rawValue
    @AppStorage(AppLanguage.storageKey) private var language = AppLanguage.system.rawValue

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Suggest the best shot", isOn: $recommendation)
                } footer: {
                    Text("In each group, the sharpest and best-looking photo starts out selected.")
                }
                Section {
                    Stepper(value: $shortVideoSeconds, in: 1...10) {
                        LabeledContent("Short videos", value: L10n.string("\(shortVideoSeconds) sec or less"))
                    }
                } footer: {
                    Text("Videos this short are often taken by accident. Longer videos aren't shown.")
                }
                Section {
                    Picker("Language", selection: $language) {
                        ForEach(AppLanguage.allCases) { lang in
                            if let name = lang.nativeName { Text(verbatim: name).tag(lang.rawValue) }
                            else { Text("System").tag(lang.rawValue) }
                        }
                    }
                } footer: {
                    Text("Album names follow this language too.")
                }
                Section("Appearance") {
                    Picker("Appearance", selection: $appearance) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.label).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                Section {
                    LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")
                } footer: {
                    Text("Your photos are analyzed on this iPhone and never leave it.")
                }
            }
            .onChange(of: language) { _, new in (AppLanguage(rawValue: new) ?? .system).applyToSystem() }
            .navigationTitle(Text("Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark") { dismiss() }
                }
            }
        }
    }
}

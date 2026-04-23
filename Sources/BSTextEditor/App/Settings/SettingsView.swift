import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settingsStore: SettingsStore

    var body: some View {
        TabView {
            Form {
                TextField("Font", text: binding(\.editorFontName))
                Stepper(
                    "Font Size: \(Int(settingsStore.settings.editorFontSize))",
                    value: binding(\.editorFontSize),
                    in: 9...32,
                    step: 1
                )
                Stepper(
                    "Tab Width: \(settingsStore.settings.tabWidth)",
                    value: binding(\.tabWidth),
                    in: 2...8,
                    step: 1
                )
                Toggle("Show Hidden Files", isOn: binding(\.showHiddenFiles))
            }
            .formStyle(.grouped)
            .scenePadding()
            .tabItem {
                Label("Editor", systemImage: "text.cursor")
            }

            Form {
                TextField("Shell", text: binding(\.terminalShell))
                TextField("Theme", text: binding(\.themeName))
                LSPSettingsList()
            }
            .formStyle(.grouped)
            .scenePadding()
            .tabItem {
                Label("Tools", systemImage: "terminal")
            }
        }
        .frame(width: 520, height: 360)
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<AppSettings, Value>) -> Binding<Value> {
        Binding(
            get: { settingsStore.settings[keyPath: keyPath] },
            set: { newValue in
                settingsStore.update { $0[keyPath: keyPath] = newValue }
            }
        )
    }
}

private struct LSPSettingsList: View {
    @EnvironmentObject private var settingsStore: SettingsStore

    var body: some View {
        Section("Language Servers") {
            ForEach(settingsStore.settings.languageServers.keys.sorted(), id: \.self) { language in
                TextField(language, text: serverBinding(for: language))
            }
        }
    }

    private func serverBinding(for language: String) -> Binding<String> {
        Binding(
            get: { settingsStore.settings.languageServers[language, default: ""] },
            set: { newValue in
                settingsStore.update { $0.languageServers[language] = newValue }
            }
        )
    }
}

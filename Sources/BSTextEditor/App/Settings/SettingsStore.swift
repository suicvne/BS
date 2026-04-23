import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    @Published var settings: AppSettings {
        didSet {
            guard settings != oldValue else { return }
            save()
        }
    }

    let settingsURL: URL

    init(fileManager: FileManager = .default) {
        let supportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("BSTextEditor", isDirectory: true)
            ?? fileManager.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Application Support/BSTextEditor", isDirectory: true)

        settingsURL = supportURL.appendingPathComponent("settings.json", isDirectory: false)

        if let data = try? Data(contentsOf: settingsURL),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = decoded
        } else {
            settings = .defaults
            saveInitialSettings(to: settingsURL, settings: .defaults, fileManager: fileManager)
        }
    }

    func update(_ changes: (inout AppSettings) -> Void) {
        var copy = settings
        changes(&copy)
        settings = copy
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(
                at: settingsURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(settings)
            try data.write(to: settingsURL, options: .atomic)
        } catch {
            NSLog("Failed to save settings: \(error.localizedDescription)")
        }
    }

    private func saveInitialSettings(to url: URL, settings: AppSettings, fileManager: FileManager) {
        do {
            try fileManager.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(settings)
            try data.write(to: url, options: .atomic)
        } catch {
            NSLog("Failed to write initial settings: \(error.localizedDescription)")
        }
    }
}

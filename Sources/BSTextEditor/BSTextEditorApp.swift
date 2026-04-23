import SwiftUI

@main
struct BSTextEditorApp: App {
    @StateObject private var applicationModel = ApplicationModel()
    @StateObject private var settingsStore = SettingsStore()

    var body: some Scene {
        WindowGroup("Workspace", id: "workspace", for: WorkspaceID.self) { workspaceID in
            if let descriptor = applicationModel.workspace(for: workspaceID.wrappedValue) {
                WorkspaceWindow(descriptor: descriptor)
                    .environmentObject(applicationModel)
                    .environmentObject(settingsStore)
            } else {
                EmptyWorkspaceView()
                    .environmentObject(applicationModel)
                    .environmentObject(settingsStore)
            }
        } defaultValue: {
            applicationModel.defaultWorkspaceID()
        }
        .defaultSize(width: 1180, height: 760)
        .commands {
            AppCommands(applicationModel: applicationModel)
        }

        Settings {
            SettingsView()
                .environmentObject(settingsStore)
        }
    }
}

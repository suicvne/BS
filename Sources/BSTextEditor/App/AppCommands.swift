import AppKit
import SwiftUI

struct AppCommands: Commands {
    @ObservedObject var applicationModel: ApplicationModel
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Open Folder...") {
                openFolder()
            }
            .keyboardShortcut("O", modifiers: [.command, .shift])
        }

        CommandMenu("Workspace") {
            Button("Reload File Tree") {
                NotificationCenter.default.post(name: .reloadCurrentWorkspace, object: nil)
            }
            .keyboardShortcut("R", modifiers: [.command, .shift])
        }

        CommandGroup(after: .saveItem) {
            Button("Save") {
                NotificationCenter.default.post(name: .saveCurrentEditor, object: nil)
            }
            .keyboardShortcut("s", modifiers: [.command])
        }
    }

    private func openFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Open"
        panel.message = "Choose a project folder to open in a workspace window."

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        let id = applicationModel.registerWorkspace(at: url)
        openWindow(id: "workspace", value: id)
    }
}

extension Notification.Name {
    static let reloadCurrentWorkspace = Notification.Name("BSTextEditor.reloadCurrentWorkspace")
    static let saveCurrentEditor = Notification.Name("BSTextEditor.saveCurrentEditor")
}

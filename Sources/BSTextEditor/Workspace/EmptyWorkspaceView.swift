import SwiftUI

struct EmptyWorkspaceView: View {
    @EnvironmentObject private var applicationModel: ApplicationModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)

            Button {
                openFolder()
            } label: {
                Label("Open Folder", systemImage: "folder.badge.plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(minWidth: 720, maxWidth: .infinity, minHeight: 460, maxHeight: .infinity)
    }

    private func openFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        let id = applicationModel.registerWorkspace(at: url)
        openWindow(id: "workspace", value: id)
    }
}

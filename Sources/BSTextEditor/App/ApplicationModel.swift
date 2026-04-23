import Foundation

struct WorkspaceID: RawRepresentable, Hashable, Codable {
    var rawValue: String
}

struct WorkspaceDescriptor: Identifiable, Hashable, Codable {
    var id: WorkspaceID
    var rootURL: URL

    var displayName: String {
        rootURL.lastPathComponent.isEmpty ? rootURL.path : rootURL.lastPathComponent
    }
}

@MainActor
final class ApplicationModel: ObservableObject {
    static let emptyWorkspaceID = WorkspaceID(rawValue: "BSTextEditor.emptyWorkspace")

    @Published private var workspaces: [WorkspaceID: WorkspaceDescriptor] = [:]
    private var rememberedWorkspaceIDs: [WorkspaceID] = []
    private var didRestoreAdditionalWindows = false
    private var isTerminating = false
    private let windowStateURL: URL

    init(fileManager: FileManager = .default) {
        let supportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("BSTextEditor", isDirectory: true)
            ?? fileManager.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Application Support/BSTextEditor", isDirectory: true)

        windowStateURL = supportURL.appendingPathComponent("windows.json", isDirectory: false)
        restoreRememberedWorkspaces()
    }

    func registerWorkspace(at rootURL: URL) -> WorkspaceID {
        let standardizedURL = rootURL.standardizedFileURL
        let id = WorkspaceID(rawValue: standardizedURL.path)
        workspaces[id] = WorkspaceDescriptor(id: id, rootURL: standardizedURL)
        rememberWorkspace(id)
        return id
    }

    func workspace(for id: WorkspaceID) -> WorkspaceDescriptor? {
        workspaces[id]
    }

    func defaultWorkspaceID() -> WorkspaceID {
        rememberedWorkspaceIDs.first ?? Self.emptyWorkspaceID
    }

    func additionalWorkspaceIDsToRestore(after visibleID: WorkspaceID) -> [WorkspaceID] {
        guard !didRestoreAdditionalWindows else { return [] }
        didRestoreAdditionalWindows = true
        return rememberedWorkspaceIDs.filter { $0 != visibleID }
    }

    func closeWorkspace(id: WorkspaceID) {
        guard id != Self.emptyWorkspaceID else { return }
        guard !isTerminating else { return }
        rememberedWorkspaceIDs.removeAll { $0 == id }
        saveWindowState()
    }

    func prepareForTermination() {
        isTerminating = true
        saveWindowState()
    }

    private func restoreRememberedWorkspaces() {
        guard let data = try? Data(contentsOf: windowStateURL),
              let state = try? JSONDecoder().decode(WindowState.self, from: data) else {
            return
        }

        for path in state.workspacePaths {
            let url = URL(fileURLWithPath: path).standardizedFileURL
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
                  isDirectory.boolValue else {
                continue
            }

            let id = WorkspaceID(rawValue: url.path)
            workspaces[id] = WorkspaceDescriptor(id: id, rootURL: url)
            rememberedWorkspaceIDs.append(id)
        }
    }

    private func rememberWorkspace(_ id: WorkspaceID) {
        rememberedWorkspaceIDs.removeAll { $0 == id }
        rememberedWorkspaceIDs.append(id)
        saveWindowState()
    }

    private func saveWindowState() {
        do {
            try FileManager.default.createDirectory(
                at: windowStateURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let state = WindowState(workspacePaths: rememberedWorkspaceIDs.map(\.rawValue))
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(state)
            try data.write(to: windowStateURL, options: .atomic)
        } catch {
            NSLog("Failed to save window state: \(error.localizedDescription)")
        }
    }
}

private struct WindowState: Codable {
    var workspacePaths: [String]
}

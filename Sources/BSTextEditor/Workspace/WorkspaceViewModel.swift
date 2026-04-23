import Foundation

@MainActor
final class WorkspaceViewModel: ObservableObject {
    let descriptor: WorkspaceDescriptor

    @Published var fileTree: [FileTreeNode] = []
    @Published var openBuffers: [EditorBuffer] = []
    @Published var selectedBufferID: EditorBuffer.ID?
    @Published var statusMessage: String = "Ready"

    var selectedBuffer: EditorBuffer? {
        guard let selectedBufferID else { return nil }
        return openBuffers.first { $0.id == selectedBufferID }
    }

    init(descriptor: WorkspaceDescriptor) {
        self.descriptor = descriptor
    }

    func reloadFileTree(showHiddenFiles: Bool) {
        fileTree = FileTreeBuilder.buildTree(
            rootURL: descriptor.rootURL,
            showHiddenFiles: showHiddenFiles
        )
        statusMessage = "Indexed \(descriptor.displayName)"
    }

    func openFile(_ url: URL) {
        if let existingBuffer = openBuffers.first(where: { $0.url == url }) {
            selectedBufferID = existingBuffer.id
            statusMessage = "Selected \(existingBuffer.displayName)"
            return
        }

        do {
            let buffer = try EditorBuffer(url: url)
            openBuffers.append(buffer)
            selectedBufferID = buffer.id
            statusMessage = "Opened \(url.lastPathComponent)"
        } catch {
            statusMessage = "Could not open \(url.lastPathComponent): \(error.localizedDescription)"
        }
    }

    func selectBuffer(id: EditorBuffer.ID) {
        guard openBuffers.contains(where: { $0.id == id }) else { return }
        selectedBufferID = id
    }

    func closeBuffer(id: EditorBuffer.ID) {
        guard let index = openBuffers.firstIndex(where: { $0.id == id }) else { return }
        let closedBuffer = openBuffers.remove(at: index)

        if selectedBufferID == id {
            selectedBufferID = openBuffers[safe: min(index, openBuffers.count - 1)]?.id
        }

        statusMessage = "Closed \(closedBuffer.displayName)"
    }

    func saveSelectedBuffer() {
        guard let selectedBuffer else {
            statusMessage = "No file selected"
            return
        }

        do {
            try selectedBuffer.save()
            statusMessage = "Saved \(selectedBuffer.displayName)"
        } catch {
            statusMessage = "Could not save \(selectedBuffer.displayName): \(error.localizedDescription)"
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

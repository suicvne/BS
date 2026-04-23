import Foundation

@MainActor
final class EditorBuffer: ObservableObject, Identifiable {
    let id = UUID()
    let url: URL

    @Published private(set) var text: String
    @Published private(set) var isDirty: Bool = false

    var displayName: String {
        url.lastPathComponent
    }

    init(url: URL) throws {
        self.url = url
        text = try String(contentsOf: url, encoding: .utf8)
    }

    func replaceText(_ newText: String) {
        guard newText != text else { return }
        text = newText
        isDirty = true
    }

    func save() throws {
        try text.write(to: url, atomically: true, encoding: .utf8)
        isDirty = false
    }
}

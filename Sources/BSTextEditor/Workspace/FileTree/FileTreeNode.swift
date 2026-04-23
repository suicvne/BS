import Foundation

struct FileTreeNode: Identifiable, Hashable {
    let id: URL
    let url: URL
    let name: String
    let isDirectory: Bool
    let children: [FileTreeNode]?

    init(url: URL, isDirectory: Bool, children: [FileTreeNode]? = nil) {
        self.id = url
        self.url = url
        self.name = url.lastPathComponent
        self.isDirectory = isDirectory
        self.children = children
    }
}

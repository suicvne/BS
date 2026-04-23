import SwiftUI

struct FileTreeView: View {
    let nodes: [FileTreeNode]
    let selectedURL: URL?
    let onOpenFile: (URL) -> Void

    @State private var selectedNodeURL: URL?

    var body: some View {
        List(selection: $selectedNodeURL) {
            OutlineGroup(nodes, children: \.children) { node in
                row(for: node)
                    .tag(node.url)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .onAppear {
            selectedNodeURL = selectedURL
        }
        .onChange(of: selectedURL) { _, newValue in
            selectedNodeURL = newValue
        }
        .onChange(of: selectedNodeURL) { _, newValue in
            guard let newValue,
                  let node = node(for: newValue, in: nodes),
                  !node.isDirectory else {
                return
            }

            onOpenFile(node.url)
        }
    }

    private func row(for node: FileTreeNode) -> some View {
        Label(node.name, systemImage: node.isDirectory ? "folder" : LanguageIdentifier.identify(url: node.url).symbolName)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func node(for url: URL, in nodes: [FileTreeNode]) -> FileTreeNode? {
        for node in nodes {
            if node.url == url {
                return node
            }

            if let children = node.children,
               let match = self.node(for: url, in: children) {
                return match
            }
        }

        return nil
    }
}

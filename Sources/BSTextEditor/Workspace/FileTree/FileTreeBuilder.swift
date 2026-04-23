import Foundation

enum FileTreeBuilder {
    static func buildTree(rootURL: URL, showHiddenFiles: Bool) -> [FileTreeNode] {
        children(of: rootURL, showHiddenFiles: showHiddenFiles)
    }

    private static func children(of directoryURL: URL, showHiddenFiles: Bool) -> [FileTreeNode] {
        let resourceKeys: Set<URLResourceKey> = [.isDirectoryKey, .isPackageKey]
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: Array(resourceKeys),
            options: showHiddenFiles ? [] : [.skipsHiddenFiles]
        ) else {
            return []
        }

        return contents
            .filter { showHiddenFiles || !$0.lastPathComponent.hasPrefix(".") }
            .sorted { left, right in
                let leftIsDirectory = (try? left.resourceValues(forKeys: resourceKeys).isDirectory) ?? false
                let rightIsDirectory = (try? right.resourceValues(forKeys: resourceKeys).isDirectory) ?? false

                if leftIsDirectory != rightIsDirectory {
                    return leftIsDirectory
                }

                return left.lastPathComponent.localizedStandardCompare(right.lastPathComponent) == .orderedAscending
            }
            .map { url in
                let values = try? url.resourceValues(forKeys: resourceKeys)
                let isDirectory = values?.isDirectory == true
                let isPackage = values?.isPackage == true

                if isDirectory && !isPackage {
                    return FileTreeNode(
                        url: url,
                        isDirectory: true,
                        children: children(of: url, showHiddenFiles: showHiddenFiles)
                    )
                }

                return FileTreeNode(url: url, isDirectory: false)
            }
    }
}

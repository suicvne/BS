import Foundation

struct AppSettings: Codable, Equatable {
    var editorFontName: String
    var editorFontSize: Double
    var tabWidth: Int
    var showHiddenFiles: Bool
    var terminalShell: String
    var themeName: String
    var languageServers: [String: String]

    static let defaults = AppSettings(
        editorFontName: "SF Mono",
        editorFontSize: 13,
        tabWidth: 4,
        showHiddenFiles: false,
        terminalShell: "/bin/zsh",
        themeName: "Default Dark",
        languageServers: [
            "c": "clangd",
            "cpp": "clangd",
            "csharp": "csharp-ls",
            "json": "vscode-json-languageserver --stdio",
            "lua": "lua-language-server"
        ]
    )
}

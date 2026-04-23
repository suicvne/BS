import Foundation

enum LanguageIdentifier: String, Codable, CaseIterable {
    case c
    case cpp
    case csharp
    case json
    case lua
    case text

    var displayName: String {
        switch self {
        case .c: "C"
        case .cpp: "C++"
        case .csharp: "C#"
        case .json: "JSON"
        case .lua: "Lua"
        case .text: "Plain Text"
        }
    }

    var symbolName: String {
        switch self {
        case .json: "curlybraces"
        case .c, .cpp, .csharp: "chevron.left.forwardslash.chevron.right"
        case .lua: "moon"
        case .text: "doc.text"
        }
    }

    static func identify(url: URL) -> LanguageIdentifier {
        switch url.pathExtension.lowercased() {
        case "c", "h":
            .c
        case "cc", "cpp", "cxx", "hpp", "hh", "hxx":
            .cpp
        case "cs":
            .csharp
        case "json":
            .json
        case "lua":
            .lua
        default:
            .text
        }
    }
}

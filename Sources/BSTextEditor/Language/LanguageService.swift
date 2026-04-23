import Foundation

protocol LanguageService {
    var language: LanguageIdentifier { get }
    func start(workspaceURL: URL, command: String) async throws
    func stop() async
}

struct LanguageServerConfiguration: Codable, Hashable {
    var language: LanguageIdentifier
    var command: String
}

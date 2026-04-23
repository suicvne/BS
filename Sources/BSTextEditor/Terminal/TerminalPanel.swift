import SwiftUI

struct TerminalPanel: View {
    var rootURL: URL
    var shellPath: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(rootURL.path)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text("$ \(shellPath)")
                .font(.system(.body, design: .monospaced))

            Text("PTY-backed terminal service placeholder")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(12)
        .background(Color(nsColor: .textBackgroundColor))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

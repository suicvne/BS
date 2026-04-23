import AppKit
import Foundation

struct EditorTheme: Codable, Hashable {
    var name: String
    var backgroundHex: String
    var foregroundHex: String
    var selectionHex: String
    var caretHex: String

    static let defaultDark = EditorTheme(
        name: "Default Dark",
        backgroundHex: "#1E1F24",
        foregroundHex: "#D7DCE2",
        selectionHex: "#3A5F8A",
        caretHex: "#F5F7FA"
    )

    var backgroundColor: NSColor {
        NSColor(hex: backgroundHex) ?? .textBackgroundColor
    }

    var foregroundColor: NSColor {
        NSColor(hex: foregroundHex) ?? .textColor
    }

    var selectionColor: NSColor {
        NSColor(hex: selectionHex) ?? .selectedTextBackgroundColor
    }

    var caretColor: NSColor {
        NSColor(hex: caretHex) ?? .textColor
    }
}

private extension NSColor {
    convenience init?(hex: String) {
        let value = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard value.count == 6, let integer = Int(value, radix: 16) else {
            return nil
        }

        let red = CGFloat((integer >> 16) & 0xFF) / 255
        let green = CGFloat((integer >> 8) & 0xFF) / 255
        let blue = CGFloat(integer & 0xFF) / 255

        self.init(calibratedRed: red, green: green, blue: blue, alpha: 1)
    }
}

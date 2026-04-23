import AppKit
import SwiftUI

struct SourceEditorView: NSViewRepresentable {
    @Binding var text: String
    var settings: AppSettings
    var theme: EditorTheme

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.allowsUndo = true
        textView.string = text
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true
        textView.textContainer?.containerSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = false

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.documentView = textView
        applyAppearance(to: textView)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
        }

        applyAppearance(to: textView)
        context.coordinator.text = $text
    }

    private func applyAppearance(to textView: NSTextView) {
        let font = NSFont(name: settings.editorFontName, size: settings.editorFontSize)
            ?? NSFont.monospacedSystemFont(ofSize: settings.editorFontSize, weight: .regular)

        textView.font = font
        textView.textColor = theme.foregroundColor
        textView.backgroundColor = theme.backgroundColor
        textView.insertionPointColor = theme.caretColor
        textView.selectedTextAttributes = [
            .backgroundColor: theme.selectionColor
        ]
        textView.defaultParagraphStyle = paragraphStyle(tabWidth: settings.tabWidth, font: font)
    }

    private func paragraphStyle(tabWidth: Int, font: NSFont) -> NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        let tabInterval = CGFloat(tabWidth) * " ".size(withAttributes: [.font: font]).width
        paragraphStyle.defaultTabInterval = tabInterval
        paragraphStyle.tabStops = []
        return paragraphStyle
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
        }
    }
}

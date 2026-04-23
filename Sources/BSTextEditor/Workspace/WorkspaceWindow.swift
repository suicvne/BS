import AppKit
import SwiftUI

struct WorkspaceWindow: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var applicationModel: ApplicationModel
    @EnvironmentObject private var settingsStore: SettingsStore
    @StateObject private var workspace: WorkspaceViewModel
    @State private var sidebarWidth: CGFloat = 280
    @State private var isSidebarVisible = true
    @State private var isBottomPanelVisible = true
    private let panelAnimation = Animation.interpolatingSpring(duration: 0.28, bounce: 0.12)

    init(descriptor: WorkspaceDescriptor) {
        _workspace = StateObject(wrappedValue: WorkspaceViewModel(descriptor: descriptor))
    }

    var body: some View {
        WorkspaceSplitView(
            sidebarWidth: $sidebarWidth,
            isSidebarVisible: isSidebarVisible,
            isBottomPanelVisible: isBottomPanelVisible,
            sidebar: sidebarPane,
            editor: editorPane,
            bottomPanel: bottomPanel
        )
        .ignoresSafeArea(.container, edges: .top)
        .frame(minWidth: 920, idealWidth: 1180, maxWidth: .infinity, minHeight: 620, idealHeight: 760, maxHeight: .infinity)
        .navigationTitle(workspace.descriptor.displayName)
        .background {
            WorkspaceWindowChrome()

            TitlebarTabAccessory(
                sidebarWidth: isSidebarVisible ? sidebarWidth : 0,
                buffers: workspace.openBuffers,
                selectedBufferID: workspace.selectedBufferID,
                onSelect: workspace.selectBuffer,
                onClose: workspace.closeBuffer
            )
        }
        .safeAreaInset(edge: .bottom) {
            StatusBar(
                message: workspace.statusMessage,
                settingsURL: settingsStore.settingsURL,
                isSidebarVisible: isSidebarVisible,
                isBottomPanelVisible: isBottomPanelVisible,
                onToggleSidebar: toggleSidebar,
                onToggleBottomPanel: toggleBottomPanel
            )
        }
        .animation(panelAnimation, value: isSidebarVisible)
        .animation(panelAnimation, value: isBottomPanelVisible)
        .onAppear {
            workspace.reloadFileTree(showHiddenFiles: settingsStore.settings.showHiddenFiles)
            restoreAdditionalWorkspaceWindows()
        }
        .onDisappear {
            applicationModel.closeWorkspace(id: workspace.descriptor.id)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
            applicationModel.prepareForTermination()
        }
        .onReceive(NotificationCenter.default.publisher(for: .reloadCurrentWorkspace)) { _ in
            workspace.reloadFileTree(showHiddenFiles: settingsStore.settings.showHiddenFiles)
        }
        .onReceive(NotificationCenter.default.publisher(for: .saveCurrentEditor)) { _ in
            workspace.saveSelectedBuffer()
        }
    }

    private func toggleSidebar() {
        withAnimation(panelAnimation) {
            isSidebarVisible.toggle()
        }
    }

    private func toggleBottomPanel() {
        withAnimation(panelAnimation) {
            isBottomPanelVisible.toggle()
        }
    }

    private var sidebarPane: some View {
        FileTreeView(
            nodes: workspace.fileTree,
            selectedURL: workspace.selectedBuffer?.url,
            onOpenFile: workspace.openFile
        )
        .frame(minWidth: 220, idealWidth: 280, maxWidth: 380, maxHeight: .infinity)
    }

    private var bottomPanel: some View {
        TerminalPanel(
            rootURL: workspace.descriptor.rootURL,
            shellPath: settingsStore.settings.terminalShell
        )
        .frame(minHeight: 120, idealHeight: 180, maxHeight: .infinity)
    }

    private func restoreAdditionalWorkspaceWindows() {
        let additionalIDs = applicationModel.additionalWorkspaceIDsToRestore(
            after: workspace.descriptor.id
        )

        for id in additionalIDs {
            openWindow(id: "workspace", value: id)
        }
    }

    @ViewBuilder
    private var editorPane: some View {
        VStack(spacing: 0) {
            if let buffer = workspace.selectedBuffer {
                SourceEditorView(
                    text: Binding(
                        get: { buffer.text },
                        set: { buffer.replaceText($0) }
                    ),
                    settings: settingsStore.settings,
                    theme: EditorTheme.defaultDark
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView(
                    "Select a File",
                    systemImage: "doc.text",
                    description: Text("Choose a source file from the project tree.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct WorkspaceWindowChrome: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            configure(window: view.window)
        }
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        DispatchQueue.main.async {
            configure(window: view.window)
        }
    }

    private func configure(window: NSWindow?) {
        guard let window else { return }
        window.styleMask.insert(.fullSizeContentView)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .visible
    }
}

private struct WorkspaceSplitView: NSViewControllerRepresentable {
    @Binding var sidebarWidth: CGFloat
    var isSidebarVisible: Bool
    var isBottomPanelVisible: Bool
    var sidebar: AnyView
    var editor: AnyView
    var bottomPanel: AnyView

    init<Sidebar: View, Editor: View, BottomPanel: View>(
        sidebarWidth: Binding<CGFloat>,
        isSidebarVisible: Bool,
        isBottomPanelVisible: Bool,
        sidebar: Sidebar,
        editor: Editor,
        bottomPanel: BottomPanel
    ) {
        _sidebarWidth = sidebarWidth
        self.isSidebarVisible = isSidebarVisible
        self.isBottomPanelVisible = isBottomPanelVisible
        self.sidebar = AnyView(sidebar)
        self.editor = AnyView(editor)
        self.bottomPanel = AnyView(bottomPanel)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(sidebarWidth: $sidebarWidth)
    }

    func makeNSViewController(context: Context) -> NSSplitViewController {
        context.coordinator.makeSplitViewController(
            sidebar: sidebar,
            editor: editor,
            bottomPanel: bottomPanel,
            isSidebarVisible: isSidebarVisible,
            isBottomPanelVisible: isBottomPanelVisible
        )
    }

    func updateNSViewController(_ splitViewController: NSSplitViewController, context: Context) {
        context.coordinator.update(
            sidebar: sidebar,
            editor: editor,
            bottomPanel: bottomPanel,
            isSidebarVisible: isSidebarVisible,
            isBottomPanelVisible: isBottomPanelVisible
        )
    }

    @MainActor
    final class Coordinator: NSObject {
        private let sidebarWidth: Binding<CGFloat>
        private var rootController: NSSplitViewController?
        private var mainController: NSSplitViewController?
        private var sidebarHost: NSHostingController<AnyView>?
        private var editorHost: NSHostingController<AnyView>?
        private var bottomPanelHost: NSHostingController<AnyView>?
        private var sidebarItem: NSSplitViewItem?
        private var bottomPanelItem: NSSplitViewItem?
        private var didApplyInitialSizes = false
        private var isApplyingInitialSizes = false

        init(sidebarWidth: Binding<CGFloat>) {
            self.sidebarWidth = sidebarWidth
        }

        func makeSplitViewController(
            sidebar: AnyView,
            editor: AnyView,
            bottomPanel: AnyView,
            isSidebarVisible: Bool,
            isBottomPanelVisible: Bool
        ) -> NSSplitViewController {
            let rootController = NSSplitViewController()
            rootController.splitView.isVertical = true
            rootController.splitView.dividerStyle = .thin

            let mainController = NSSplitViewController()
            mainController.splitView.isVertical = false
            mainController.splitView.dividerStyle = .thin

            let sidebarHost = NSHostingController(rootView: sidebar)
            let editorHost = NSHostingController(rootView: editor)
            let bottomPanelHost = NSHostingController(rootView: bottomPanel)

            let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebarHost)
            sidebarItem.minimumThickness = 220
            sidebarItem.maximumThickness = 380
            sidebarItem.preferredThicknessFraction = 0.24
            sidebarItem.canCollapse = true

            let mainItem = NSSplitViewItem(viewController: mainController)
            mainItem.minimumThickness = 360

            let editorItem = NSSplitViewItem(viewController: editorHost)
            editorItem.minimumThickness = 260

            let bottomPanelItem = NSSplitViewItem(viewController: bottomPanelHost)
            bottomPanelItem.minimumThickness = 120
            bottomPanelItem.preferredThicknessFraction = 0.24
            bottomPanelItem.canCollapse = true

            mainController.addSplitViewItem(editorItem)
            mainController.addSplitViewItem(bottomPanelItem)

            rootController.addSplitViewItem(sidebarItem)
            rootController.addSplitViewItem(mainItem)

            self.rootController = rootController
            self.mainController = mainController
            self.sidebarHost = sidebarHost
            self.editorHost = editorHost
            self.bottomPanelHost = bottomPanelHost
            self.sidebarItem = sidebarItem
            self.bottomPanelItem = bottomPanelItem
            observeResize(of: rootController.splitView)
            observeResize(of: mainController.splitView)

            DispatchQueue.main.async {
                let didApplySizes = self.applyInitialSizesIfPossible()
                self.set(sidebarItem, collapsed: !isSidebarVisible, animated: false)
                self.set(bottomPanelItem, collapsed: !isBottomPanelVisible, animated: false)
                if didApplySizes {
                    self.updateSidebarWidth()
                }
            }

            return rootController
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        func update(
            sidebar: AnyView,
            editor: AnyView,
            bottomPanel: AnyView,
            isSidebarVisible: Bool,
            isBottomPanelVisible: Bool
        ) {
            sidebarHost?.rootView = sidebar
            editorHost?.rootView = editor
            bottomPanelHost?.rootView = bottomPanel

            _ = applyInitialSizesIfPossible()
            set(sidebarItem, collapsed: !isSidebarVisible, animated: true)
            set(bottomPanelItem, collapsed: !isBottomPanelVisible, animated: true)

            if isSidebarVisible, didApplyInitialSizes {
                updateSidebarWidth()
            }
        }

        private func applyInitialSizesIfPossible() -> Bool {
            guard !didApplyInitialSizes, !isApplyingInitialSizes else { return false }
            guard let rootSplitView = rootController?.splitView,
                  let mainSplitView = mainController?.splitView,
                  rootSplitView.arrangedSubviews.count >= 2,
                  mainSplitView.arrangedSubviews.count >= 2,
                  rootSplitView.bounds.width > 0,
                  mainSplitView.bounds.height > 0 else {
                return false
            }

            isApplyingInitialSizes = true
            didApplyInitialSizes = true
            defer {
                isApplyingInitialSizes = false
            }

            rootSplitView.setPosition(sidebarWidth.wrappedValue, ofDividerAt: 0)

            let bottomHeight: CGFloat = 180
            let bottomDividerPosition = max(260, mainSplitView.bounds.height - bottomHeight)
            mainSplitView.setPosition(bottomDividerPosition, ofDividerAt: 0)
            return true
        }

        private func set(_ item: NSSplitViewItem?, collapsed: Bool, animated: Bool) {
            guard let item, item.isCollapsed != collapsed else { return }

            if animated {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.22
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    item.animator().isCollapsed = collapsed
                } completionHandler: {
                    DispatchQueue.main.async {
                        self.updateSidebarWidth()
                    }
                }
            } else {
                item.isCollapsed = collapsed
            }
        }

        private func updateSidebarWidth() {
            guard let sidebarItem,
                  !sidebarItem.isCollapsed,
                  let sidebarView = sidebarHost?.view else {
                return
            }

            let width = sidebarView.frame.width
            guard width.isFinite, width > 0 else { return }
            sidebarWidth.wrappedValue = width
        }

        private func observeResize(of splitView: NSSplitView) {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(splitViewDidResizeSubviews(_:)),
                name: NSSplitView.didResizeSubviewsNotification,
                object: splitView,
            )
        }

        @objc
        private func splitViewDidResizeSubviews(_ notification: Notification) {
            guard !isApplyingInitialSizes else { return }

            if !didApplyInitialSizes {
                DispatchQueue.main.async {
                    guard !self.isApplyingInitialSizes else { return }
                    if self.applyInitialSizesIfPossible() {
                        self.updateSidebarWidth()
                    }
                }
                return
            }

            if didApplyInitialSizes {
                updateSidebarWidth()
            }
        }
    }
}

private struct TitlebarTabAccessory: NSViewRepresentable {
    let sidebarWidth: CGFloat
    let buffers: [EditorBuffer]
    let selectedBufferID: EditorBuffer.ID?
    let onSelect: @MainActor (EditorBuffer.ID) -> Void
    let onClose: @MainActor (EditorBuffer.ID) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            context.coordinator.attachIfNeeded(to: view.window)
            context.coordinator.update(
                sidebarWidth: sidebarWidth,
                buffers: buffers,
                selectedBufferID: selectedBufferID,
                onSelect: onSelect,
                onClose: onClose
            )
        }
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.attachIfNeeded(to: view.window)
            context.coordinator.update(
                sidebarWidth: sidebarWidth,
                buffers: buffers,
                selectedBufferID: selectedBufferID,
                onSelect: onSelect,
                onClose: onClose
            )
        }
    }

    static func dismantleNSView(_ view: NSView, coordinator: Coordinator) {
        coordinator.detach()
    }

    @MainActor
    final class Coordinator {
        private weak var window: NSWindow?
        private var accessory: NSTitlebarAccessoryViewController?
        private var hostingView: NSHostingView<AnyView>?

        func attachIfNeeded(to window: NSWindow?) {
            guard let window else { return }
            guard self.window !== window else { return }

            detach()

            let accessory = NSTitlebarAccessoryViewController()
            accessory.layoutAttribute = .right

            let hostingView = NSHostingView(rootView: AnyView(EmptyView()))
            hostingView.frame = NSRect(x: 0, y: 0, width: 720, height: 28)
            hostingView.autoresizingMask = [.width]
            accessory.view = hostingView

            window.addTitlebarAccessoryViewController(accessory)

            self.window = window
            self.accessory = accessory
            self.hostingView = hostingView
        }

        func update(
            sidebarWidth: CGFloat,
            buffers: [EditorBuffer],
            selectedBufferID: EditorBuffer.ID?,
            onSelect: @escaping @MainActor (EditorBuffer.ID) -> Void,
            onClose: @escaping @MainActor (EditorBuffer.ID) -> Void
        ) {
            if let window,
               let frameView = window.contentView?.superview {
                let leftInset = titlebarTabLeftInset(for: window, sidebarWidth: sidebarWidth)
                let width = max(0, frameView.bounds.width - leftInset)
                hostingView?.frame = NSRect(x: 0, y: 0, width: width, height: 28)
            }

            hostingView?.rootView = AnyView(
                EditorTabBar(
                    buffers: buffers,
                    selectedBufferID: selectedBufferID,
                    onSelect: onSelect,
                    onClose: onClose
                )
            )
            hostingView?.isHidden = buffers.isEmpty
        }

        private func titlebarTabLeftInset(for window: NSWindow, sidebarWidth: CGFloat) -> CGFloat {
            guard let frameView = window.contentView?.superview else {
                return sidebarWidth
            }

            let buttonRightEdge = [
                NSWindow.ButtonType.closeButton,
                .miniaturizeButton,
                .zoomButton
            ]
            .compactMap { window.standardWindowButton($0) }
            .map { button in
                button.convert(button.bounds, to: frameView).maxX
            }
            .max() ?? 0

            let titleTextField = titleTextField(in: frameView, title: window.title)
            let titleRightEdge = titleTextField?
                .convert(titleTextField?.bounds ?? .zero, to: frameView)
                .maxX ?? 0

            return max(sidebarWidth, buttonRightEdge + 28, titleRightEdge + 16)
        }

        private func titleTextField(in view: NSView, title: String) -> NSTextField? {
            for subview in view.subviews {
                if let textField = subview as? NSTextField,
                   textField.stringValue == title {
                    return textField
                }

                if let match = titleTextField(in: subview, title: title) {
                    return match
                }
            }

            return nil
        }

        func detach() {
            if let accessory,
               let window,
               let index = window.titlebarAccessoryViewControllers.firstIndex(of: accessory) {
                window.removeTitlebarAccessoryViewController(at: index)
            }

            window = nil
            accessory = nil
            hostingView = nil
        }
    }
}

private struct EditorTabBar: View {
    let buffers: [EditorBuffer]
    let selectedBufferID: EditorBuffer.ID?
    let onSelect: @MainActor (EditorBuffer.ID) -> Void
    let onClose: @MainActor (EditorBuffer.ID) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(buffers) { buffer in
                    EditorTab(
                        buffer: buffer,
                        isSelected: buffer.id == selectedBufferID,
                        onSelect: { onSelect(buffer.id) },
                        onClose: { onClose(buffer.id) }
                    )
                }
            }
        }
        .contentMargins(0, for: .scrollContent)
        .scrollIndicators(.never)
        .frame(height: 28)
        .background(Color.clear)
    }
}

private struct EditorTab: View {
    @ObservedObject var buffer: EditorBuffer
    var isSelected: Bool
    var onSelect: () -> Void
    var onClose: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 6) {
                Image(systemName: LanguageIdentifier.identify(url: buffer.url).symbolName)
                    .foregroundStyle(.secondary)
                    .imageScale(.small)

                Text(buffer.displayName)
                    .lineLimit(1)

                if buffer.isDirty {
                    Circle()
                        .fill(.secondary)
                        .frame(width: 6, height: 6)
                }

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 14, height: 14)
                }
                .buttonStyle(.plain)
            }
            .font(.caption)
            .padding(.horizontal, 10)
            .frame(minWidth: 120, maxWidth: 220, minHeight: 28, maxHeight: 28, alignment: .center)
            .contentShape(Rectangle())
            .overlay(alignment: .trailing) {
                Divider()
            }
        }
        .buttonStyle(.plain)
    }
}

private struct StatusBar: View {
    var message: String
    var settingsURL: URL
    var isSidebarVisible: Bool
    var isBottomPanelVisible: Bool
    var onToggleSidebar: () -> Void
    var onToggleBottomPanel: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            PanelToggleGroup(
                isSidebarVisible: isSidebarVisible,
                isBottomPanelVisible: isBottomPanelVisible,
                onToggleSidebar: onToggleSidebar,
                onToggleBottomPanel: onToggleBottomPanel
            )

            Text(message)
                .lineLimit(1)

            Spacer()

            Text(settingsURL.path)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .frame(height: 24)
        .background(.bar)
    }
}

private struct PanelToggleGroup: View {
    var isSidebarVisible: Bool
    var isBottomPanelVisible: Bool
    var onToggleSidebar: () -> Void
    var onToggleBottomPanel: () -> Void

    var body: some View {
        HStack(spacing: 1) {
            PanelToggleButton(
                title: "Files",
                systemImage: "sidebar.left",
                isActive: isSidebarVisible,
                shortcut: "b",
                action: onToggleSidebar
            )

            PanelToggleButton(
                title: "Terminal",
                systemImage: "rectangle.bottomthird.inset.filled",
                isActive: isBottomPanelVisible,
                shortcut: "j",
                action: onToggleBottomPanel
            )
        }
        .padding(2)
        .background {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.85))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.7))
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Panel toggles")
    }
}

private struct PanelToggleButton: View {
    var title: String
    var systemImage: String
    var isActive: Bool
    var shortcut: KeyEquivalent
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .symbolVariant(isActive ? .fill : .none)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isActive ? Color.accentColor : Color.secondary)
                .frame(width: 22, height: 16)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .keyboardShortcut(shortcut, modifiers: [.command])
        .background {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(isActive ? Color.accentColor.opacity(0.14) : Color.clear)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .strokeBorder(isActive ? Color.accentColor.opacity(0.24) : Color.clear)
        }
        .help("\(title) panel \(isActive ? "visible" : "hidden")")
        .accessibilityLabel(title)
        .accessibilityValue(isActive ? "Visible" : "Hidden")
    }
}

import AppKit
import LilshotCore
import LilshotMac

/// Editor window: tools, crop, copy, save, undo/redo, zoom.
@MainActor
final class EditorWindowController: NSWindowController, NSWindowDelegate {
    static let shared = EditorWindowController()

    private var toolbar: EditorToolbarView?
    private var canvas: EditorCanvasView?
    private var model = EditorModel(canvasSize: .zero)
    private var image: CGImage?
    private var imageUndo: [CGImage] = []
    private var imageRedo: [CGImage] = []
    private var actualSize = false
    private var keyMonitor: Any?

    private init() { super.init(window: nil) }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func present(_ image: CGImage) {
        self.image = image
        model = EditorModel(canvasSize: CGSize(width: image.width, height: image.height))
        imageUndo = []
        imageRedo = []
        actualSize = false
        if window == nil {
            window = makeWindow()
            window?.delegate = self
        }
        syncViews()
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.makeFirstResponder(canvas)
    }

    @objc func copy(_ sender: Any?) {
        guard let flat = flattenedImage() else { return }
        do {
            try ClipboardImageWriter.write(flat)
            CaptureFeedback.playSuccess()
        } catch {
            fputs("editor copy failed: \(error.localizedDescription)\n", stderr)
            CaptureFeedback.playError()
        }
    }

    @objc func saveDocument(_ sender: Any?) {
        guard let flat = flattenedImage() else { return }
        do {
            try PNGImageWriter.write(flat, to: EditorExportPath.desktopPNG())
            CaptureFeedback.playSuccess()
        } catch {
            fputs("editor save failed: \(error.localizedDescription)\n", stderr)
            CaptureFeedback.playError()
        }
    }

    @objc func undo(_ sender: Any?) {
        guard model.canUndo else { return }
        model.undo()
        if let previous = imageUndo.popLast() {
            if let current = image { imageRedo.append(current) }
            image = previous
        }
        syncViews()
    }

    @objc func redo(_ sender: Any?) {
        guard model.canRedo else { return }
        model.redo()
        if let next = imageRedo.popLast() {
            if let current = image { imageUndo.append(current) }
            image = next
        }
        syncViews()
    }

    @objc func applyCrop(_ sender: Any?) {
        guard let image,
              let draft = model.cropDraft,
              draft.width >= 2, draft.height >= 2,
              let cropped = ImageCropping.crop(image, to: draft)
        else { return }
        imageUndo.append(image)
        imageRedo.removeAll()
        self.image = cropped
        model.applyCrop()
        syncViews()
    }

    @objc func zoomToFit(_ sender: Any?) { actualSize = false; syncViews() }
    @objc func zoomActualSize(_ sender: Any?) { actualSize = true; syncViews() }

    func applyModel(_ body: (inout EditorModel) -> Void) {
        body(&model)
        syncViews()
    }

    func mutateModel(_ body: (inout EditorModel) -> Void) { body(&model) }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 640),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "lilshot"
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 480, height: 320)
        window.center()

        let toolbar = EditorToolbarView(frame: .zero)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.onSelectTool = { [weak self] tool in self?.selectTool(tool) }
        toolbar.onSelectColor = { [weak self] color in self?.selectColor(color) }
        self.toolbar = toolbar

        let canvas = EditorCanvasView(frame: .zero)
        canvas.translatesAutoresizingMaskIntoConstraints = false
        wireEditorCanvas(canvas)
        self.canvas = canvas

        let root = NSView(frame: .zero)
        root.addSubview(toolbar)
        root.addSubview(canvas)
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: root.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            canvas.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            canvas.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            canvas.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            canvas.bottomAnchor.constraint(equalTo: root.bottomAnchor),
        ])
        window.contentView = root
        installKeyMonitor()
        return window
    }

    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, event.window === self.window else { return event }
            return EditorWindowKeyHandling.handle(
                event,
                actions: EditorWindowKeyHandling.Actions(
                    selectTool: { [weak self] tool in self?.selectTool(tool) },
                    applyCrop: { [weak self] in self?.applyCrop(nil) },
                    deleteSelected: { [weak self] in
                        self?.applyModel { $0.deleteSelected() }
                    },
                    close: { [weak self] in self?.window?.performClose(nil) },
                    setActualSize: { [weak self] actual in
                        self?.actualSize = actual
                        self?.syncViews()
                    },
                    isEditingText: { [weak self] in self?.canvas?.isEditingText == true },
                    currentTool: { [weak self] in self?.model.tool ?? .crop }
                )
            )
        }
    }

    private func selectTool(_ tool: EditorTool) {
        model.selectTool(tool)
        if tool != .crop { model.clearCropDraft() }
        if tool != .select { model.clearSelection() }
        syncViews()
    }

    private func selectColor(_ color: AnnotationColor) {
        model.color = color
        toolbar?.setColor(color)
    }

    private func syncViews() {
        canvas?.image = image
        canvas?.model = model
        canvas?.actualSize = actualSize
        toolbar?.setTool(model.tool)
        toolbar?.setColor(model.color)
        canvas?.needsDisplay = true
    }

    private func flattenedImage() -> CGImage? {
        guard let image else { return nil }
        return AnnotationRenderer.render(base: image, annotations: model.annotations) ?? image
    }
}

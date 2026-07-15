import AppKit
import LilshotCore
import LilshotMac

/// Single reusable editor window: draw tools, crop, copy, save, undo/redo.
@MainActor
final class EditorWindowController: NSWindowController, NSWindowDelegate {
    static let shared = EditorWindowController()

    private var toolbar: EditorToolbarView?
    private var canvas: EditorCanvasView?
    private var model = EditorModel(canvasSize: .zero)
    private var image: CGImage?
    private var imageUndo: [CGImage] = []
    private var imageRedo: [CGImage] = []
    private var keyMonitor: Any?

    private init() { super.init(window: nil) }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func present(_ image: CGImage) {
        self.image = image
        model = EditorModel(canvasSize: CGSize(width: image.width, height: image.height))
        imageUndo = []
        imageRedo = []
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
        wireCanvas(canvas)
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

    private func wireCanvas(_ canvas: EditorCanvasView) {
        canvas.onCropDraftChanged = { [weak self] a, b in
            self?.model.setCropDraft(from: a, to: b)
            self?.syncViews()
        }
        canvas.onCropDraftCleared = { [weak self] in
            self?.model.clearCropDraft()
            self?.syncViews()
        }
        canvas.onCommitArrow = { [weak self] a, b in
            self?.model.addArrow(from: a, to: b)
            self?.syncViews()
        }
        canvas.onCommitRect = { [weak self] a, b in
            self?.model.addRect(from: a, to: b)
            self?.syncViews()
        }
        canvas.onCommitStep = { [weak self] point in
            self?.model.addStepNumber(at: point)
            self?.syncViews()
        }
        canvas.onCommitText = { [weak self] origin, string in
            self?.model.addText(at: origin, string: string)
            self?.syncViews()
        }
    }

    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, event.window === self.window else { return event }
            if self.canvas?.isEditingText == true { return event }
            if event.keyCode == 36, self.model.tool == .crop {
                self.applyCrop(nil)
                return nil
            }
            if event.keyCode == 53 {
                self.window?.performClose(nil)
                return nil
            }
            return event
        }
    }

    private func selectTool(_ tool: EditorTool) {
        model.selectTool(tool)
        if tool != .crop { model.clearCropDraft() }
        syncViews()
    }

    private func selectColor(_ color: AnnotationColor) {
        model.color = color
        toolbar?.setColor(color)
    }

    private func syncViews() {
        canvas?.image = image
        canvas?.model = model
        toolbar?.setTool(model.tool)
        toolbar?.setColor(model.color)
        canvas?.needsDisplay = true
    }

    private func flattenedImage() -> CGImage? {
        guard let image else { return nil }
        return AnnotationRenderer.render(base: image, annotations: model.annotations) ?? image
    }
}

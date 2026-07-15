import AppKit
import LilshotCore

/// Top toolbar: draw/crop tools and the five-color palette.
final class EditorToolbarView: NSView {
    var onSelectTool: ((EditorTool) -> Void)?
    var onSelectColor: ((AnnotationColor) -> Void)?

    private var toolButtons: [EditorTool: NSButton] = [:]
    private var colorButtons: [NSButton] = []
    private var selectedTool: EditorTool = .crop
    private var selectedColor: AnnotationColor = .amber

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        build()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setTool(_ tool: EditorTool) {
        selectedTool = tool
        refreshToolChrome()
    }

    func setColor(_ color: AnnotationColor) {
        selectedColor = color
        refreshColorChrome()
    }

    private func build() {
        let tools: [(EditorTool, String)] = [
            (.select, "V"),
            (.arrow, "A"),
            (.rect, "R"),
            (.text, "T"),
            (.blur, "B"),
            (.stepNumber, "N"),
            (.crop, "C"),
        ]

        let toolStack = NSStackView()
        toolStack.orientation = .horizontal
        toolStack.spacing = 4
        toolStack.translatesAutoresizingMaskIntoConstraints = false

        for (tool, title) in tools {
            let button = NSButton(title: title, target: self, action: #selector(toolClicked(_:)))
            button.bezelStyle = .flexiblePush
            button.setButtonType(.pushOnPushOff)
            button.tag = tools.firstIndex(where: { $0.0 == tool }) ?? 0
            button.toolTip = tooltip(for: tool)
            toolButtons[tool] = button
            toolStack.addArrangedSubview(button)
        }

        let colors: [AnnotationColor] = [.amber, .red, .blue, .black, .white]
        let colorStack = NSStackView()
        colorStack.orientation = .horizontal
        colorStack.spacing = 4
        colorStack.translatesAutoresizingMaskIntoConstraints = false

        for (index, color) in colors.enumerated() {
            let button = NSButton(title: "●", target: self, action: #selector(colorClicked(_:)))
            button.bezelStyle = .flexiblePush
            button.setButtonType(.pushOnPushOff)
            button.tag = index
            button.contentTintColor = nsColor(color)
            button.toolTip = colorTip(color)
            colorButtons.append(button)
            colorStack.addArrangedSubview(button)
        }

        addSubview(toolStack)
        addSubview(colorStack)
        NSLayoutConstraint.activate([
            toolStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            toolStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            colorStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            colorStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            heightAnchor.constraint(equalToConstant: 40),
        ])

        refreshToolChrome()
        refreshColorChrome()
    }

    @objc private func toolClicked(_ sender: NSButton) {
        let tools: [EditorTool] = [.select, .arrow, .rect, .text, .blur, .stepNumber, .crop]
        guard sender.tag >= 0, sender.tag < tools.count else { return }
        onSelectTool?(tools[sender.tag])
    }

    @objc private func colorClicked(_ sender: NSButton) {
        let colors: [AnnotationColor] = [.amber, .red, .blue, .black, .white]
        guard sender.tag >= 0, sender.tag < colors.count else { return }
        onSelectColor?(colors[sender.tag])
    }

    private func refreshToolChrome() {
        let active: Set<EditorTool> = [.arrow, .rect, .text, .stepNumber, .crop]
        for (tool, button) in toolButtons {
            button.state = (tool == selectedTool) ? .on : .off
            // Select/blur stay visible but inactive until manipulation tools land.
            button.isEnabled = active.contains(tool)
        }
    }

    private func refreshColorChrome() {
        let colors: [AnnotationColor] = [.amber, .red, .blue, .black, .white]
        for (index, button) in colorButtons.enumerated() {
            let color = colors[index]
            button.state = (color == selectedColor) ? .on : .off
        }
    }

    private func tooltip(for tool: EditorTool) -> String {
        switch tool {
        case .select: return "Select"
        case .arrow: return "Arrow"
        case .rect: return "Rectangle"
        case .text: return "Text"
        case .blur: return "Blur"
        case .stepNumber: return "Number"
        case .crop: return "Crop"
        }
    }

    private func colorTip(_ color: AnnotationColor) -> String {
        if color == .amber { return "Amber" }
        if color == .red { return "Red" }
        if color == .blue { return "Blue" }
        if color == .black { return "Black" }
        return "White"
    }

    private func nsColor(_ color: AnnotationColor) -> NSColor {
        NSColor(
            srgbRed: color.red,
            green: color.green,
            blue: color.blue,
            alpha: color.alpha
        )
    }
}

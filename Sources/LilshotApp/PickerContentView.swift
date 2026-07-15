import SwiftUI
import LilshotCore

struct PickerContentView: View {
    @ObservedObject var session: PickerSession
    @ObservedObject var previewStore: PreviewStore
    var onCapture: () -> Void
    var onCancel: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            listPane
                .frame(width: 300)
            Divider()
            previewPane
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(KeyEventCatcher(
            onUp: { session.moveSelection(-1) },
            onDown: { session.moveSelection(1) },
            onEnter: onCapture,
            onEscape: onCancel
        ))
    }

    private var listPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Search windows", text: $session.query)
                .textFieldStyle(.roundedBorder)
                .onSubmit(onCapture)

            if session.rows.isEmpty {
                Text("No windows")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            } else {
                List(Array(session.rows.enumerated()), id: \.element.id) { index, window in
                    WindowRowView(window: window, isSelected: index == session.selectedIndex)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            session.selectIndex(index)
                        }
                        .listRowBackground(
                            index == session.selectedIndex
                                ? Color.accentColor.opacity(0.2)
                                : Color.clear
                        )
                }
                .listStyle(.plain)
            }
        }
        .padding(12)
    }

    private var previewPane: some View {
        Group {
            if let window = session.selectedWindow {
                ZStack {
                    if let image = previewStore.image(for: window.id) {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(16)
                    } else if previewStore.isLoading(window.id) {
                        ProgressView("Loading preview…")
                    } else {
                        Text("No preview")
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text("Select a window")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

private struct WindowRowView: View {
    let window: WindowInfo
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(window.appName)
                .font(.body.weight(isSelected ? .semibold : .regular))
                .lineLimit(1)
            Text(window.title.isEmpty ? "(untitled)" : window.title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text("\(window.width)×\(window.height)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}

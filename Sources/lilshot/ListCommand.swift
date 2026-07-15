import ArgumentParser
import Foundation
import LilshotCore
import LilshotMac

struct ListCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List capturable windows."
    )

    @Flag(name: .long, help: "Emit a JSON array for agent consumption.")
    var json = false

    func run() async throws {
        try ScreenRecordingPermission.ensureGranted()

        let provider = ScreenCaptureWindowProvider()
        let windows = WindowNoiseFilter.apply(to: try await provider.windows())

        if json {
            try printJSON(windows)
        } else {
            printTable(windows)
        }
    }

    private func printTable(_ windows: [WindowInfo]) {
        for window in windows {
            let title = window.title.isEmpty ? "-" : window.title
            print(
                "\(window.id)\t\(window.isOnScreen)\t\(window.appName)\t\(title)\t\(window.width)x\(window.height)"
            )
        }
    }

    private func printJSON(_ windows: [WindowInfo]) throws {
        let payload: [[String: Any]] = windows.map { window in
            [
                "id": window.id,
                "onScreen": window.isOnScreen,
                "app": window.appName,
                "title": window.title,
                "width": window.width,
                "height": window.height,
            ]
        }
        do {
            let data = try JSONSerialization.data(
                withJSONObject: payload,
                options: [.prettyPrinted, .sortedKeys]
            )
            FileHandle.standardOutput.write(data)
            FileHandle.standardOutput.write(Data("\n".utf8))
        } catch {
            fputs("Failed to encode JSON: \(error.localizedDescription)\n", stderr)
            throw ExitCode(1)
        }
    }
}

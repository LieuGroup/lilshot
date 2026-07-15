import AppKit
import Foundation
import ScreenCaptureKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

@main
struct SCKSpike {
    static func main() async {
        let args = Array(CommandLine.arguments.dropFirst())
        guard let command = args.first else {
            printUsageAndExit()
        }

        switch command {
        case "list":
            await runList()
        case "capture":
            guard args.count >= 3,
                  let windowID = UInt32(args[1]) else {
                fputs("usage: sck-spike capture <windowID> <output.png>\n", stderr)
                exit(1)
            }
            await runCapture(windowID: windowID, outputPath: args[2])
        default:
            printUsageAndExit()
        }
    }

    static func printUsageAndExit() -> Never {
        fputs("""
        usage:
          sck-spike list
          sck-spike capture <windowID> <output.png>
        """, stderr)
        exit(1)
    }

    /// Screen Recording TCC gate — required before any SCShareableContent call.
    static func ensureScreenRecordingPermission() {
        if CGPreflightScreenCaptureAccess() {
            return
        }
        _ = CGRequestScreenCaptureAccess()
        fputs(
            "Screen Recording permission is required.\n"
            + "Grant it in System Settings → Privacy & Security → Screen Recording, then re-run.\n",
            stderr
        )
        exit(1)
    }

    static func fetchShareableContent() async throws -> SCShareableContent {
        // onScreenWindowsOnly: false includes occluded, off-Space, and minimized windows.
        try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: false)
    }

    static func runList() async {
        ensureScreenRecordingPermission()
        do {
            let content = try await fetchShareableContent()
            let windows = content.windows
                .filter { $0.frame.width >= 40 && $0.frame.height >= 40 }
                .sorted { lhs, rhs in
                    // Offscreen first so interesting capture candidates surface at top.
                    if lhs.isOnScreen != rhs.isOnScreen {
                        return !lhs.isOnScreen && rhs.isOnScreen
                    }
                    return lhs.windowID < rhs.windowID
                }

            for window in windows {
                let appName = window.owningApplication?.applicationName ?? "?"
                let title = window.title?.isEmpty == false ? window.title! : "-"
                let w = Int(window.frame.width.rounded())
                let h = Int(window.frame.height.rounded())
                print(
                    "\(window.windowID)\t\(window.isOnScreen)\t\(window.isActive)\t\(appName)\t\(title)\t\(w)x\(h)"
                )
            }
        } catch {
            fputs("list failed: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }

    static func runCapture(windowID: UInt32, outputPath: String) async {
        ensureScreenRecordingPermission()
        // SCScreenshotManager needs a WindowServer connection; a bare CLI process
        // has none and hits CGS_REQUIRE_INIT. Touching NSApplication establishes it.
        _ = await MainActor.run { NSApplication.shared }
        do {
            let content = try await fetchShareableContent()
            guard let window = content.windows.first(where: { $0.windowID == windowID }) else {
                fputs("No window found with ID \(windowID)\n", stderr)
                exit(1)
            }

            let filter = SCContentFilter(desktopIndependentWindow: window)

            let config = SCStreamConfiguration()
            let scale: CGFloat = 2
            config.width = Int(window.frame.width * scale)
            config.height = Int(window.frame.height * scale)
            config.showsCursor = false
            if #available(macOS 14.0, *) {
                config.captureResolution = .best
            }

            let image = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            )

            let url = URL(fileURLWithPath: outputPath)
            guard let destination = CGImageDestinationCreateWithURL(
                url as CFURL,
                UTType.png.identifier as CFString,
                1,
                nil
            ) else {
                fputs("Failed to create image destination at \(outputPath)\n", stderr)
                exit(1)
            }
            CGImageDestinationAddImage(destination, image, nil)
            guard CGImageDestinationFinalize(destination) else {
                fputs("Failed to write PNG to \(outputPath)\n", stderr)
                exit(1)
            }

            let attrs = try FileManager.default.attributesOfItem(atPath: outputPath)
            let fileSize = attrs[.size] as? Int ?? 0
            let title = window.title?.isEmpty == false ? window.title! : "-"
            print("title:\t\(title)")
            print("isOnScreen:\t\(window.isOnScreen)")
            print("pixels:\t\(image.width)x\(image.height)")
            print("output:\t\(outputPath)")
            print("bytes:\t\(fileSize)")
        } catch {
            fputs("capture failed: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }
}

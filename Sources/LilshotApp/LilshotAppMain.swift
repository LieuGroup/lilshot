import AppKit

@main
enum LilshotAppMain {
    static func main() {
        terminateIfAnotherInstanceRunning()

        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }

    /// Stale instances keep Carbon hotkeys; a second launch's RegisterEventHotKey fails silently.
    /// Skip when bundleIdentifier is nil (e.g. `swift run` without an Info.plist).
    private static func terminateIfAnotherInstanceRunning() {
        guard let bundleID = Bundle.main.bundleIdentifier else { return }
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            .filter { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
        guard !others.isEmpty else { return }
        fputs(
            "lilshot: another instance is already running (pid \(others[0].processIdentifier)); exiting\n",
            stderr
        )
        exit(0)
    }
}

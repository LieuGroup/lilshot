import AppKit

/// Shared capture success/error feedback: shutter/error sounds and a brief white flash.
@MainActor
enum CaptureFeedback {
    private static let screenCaptureSoundPath =
        "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/Screen Capture.aif"
    private static let shutterSoundPath =
        "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/Shutter.aif"

    static func playSuccess() {
        if let sound = NSSound(contentsOfFile: screenCaptureSoundPath, byReference: true)
            ?? NSSound(contentsOfFile: shutterSoundPath, byReference: true)
            ?? NSSound(named: NSSound.Name("Pop"))
        {
            sound.play()
        }
    }

    static func playError() {
        NSSound(named: NSSound.Name("Basso"))?.play()
    }

    /// White flash over `rect` (AppKit coords). Call only after capture completes so flash is not in the shot.
    static func flash(over rect: CGRect, duration: TimeInterval = 0.18) {
        guard rect.width > 0, rect.height > 0 else { return }

        let panel = NSPanel(
            contentRect: rect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .white
        panel.alphaValue = 0.85
        panel.level = .screenSaver
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.hasShadow = false
        panel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = duration
            panel.animator().alphaValue = 0
        }, completionHandler: {
            panel.orderOut(nil)
            panel.close()
        })
    }
}

import AppKit

/// Plays match sounds directly, independent of the notification system, so they
/// are always audible — even when notification permission was never granted, the
/// app is in the background, or banners are silenced by a Focus mode. The
/// notification banner is purely visual; this is the audio.
@MainActor
final class SoundPlayer {
    static let shared = SoundPlayer()

    private let goal: NSSound?     // horn — a favorite team scores
    private let start: NSSound?    // kick-off and half-time
    private let finish: NSSound?   // full time

    private init() {
        // Bundled into the .app's Contents/Resources by the Makefile. Absent in a
        // bare `swift run`, where we fall back to a system sound below.
        goal = Self.load("goal")
        start = Self.load("start")
        finish = Self.load("finish")
    }

    func playGoal()   { play(goal, fallback: "Hero") }
    func playStart()  { play(start, fallback: "Tink") }   // also used for half-time
    func playFinish() { play(finish, fallback: "Glass") }

    private func play(_ sound: NSSound?, fallback: String) {
        guard WidgetSettings.soundEnabled else { return }
        guard let sound else {
            NSSound(named: fallback)?.play()   // fallback for bare-binary dev runs
            return
        }
        if sound.isPlaying { sound.stop() }    // restart cleanly on rapid events
        sound.play()
    }

    private static func load(_ name: String) -> NSSound? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "caf") else { return nil }
        return NSSound(contentsOf: url, byReference: true)
    }
}

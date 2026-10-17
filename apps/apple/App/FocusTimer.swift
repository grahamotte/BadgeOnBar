import Foundation
import Observation

@MainActor
@Observable
final class FocusTimer {
    private(set) var completedSessions: Int
    private(set) var isRunning = false
    private(set) var minutes: Int
    private(set) var remainingSeconds: Int

    private let defaults: UserDefaults

    init(minutes: Int = 25, defaults: UserDefaults = .standard) {
        self.minutes = minutes
        self.remainingSeconds = minutes * 60
        self.defaults = defaults
        self.completedSessions = defaults.integer(forKey: "completedSessions")
    }

    var progress: Double {
        Double(remainingSeconds) / Double(minutes * 60)
    }

    var timeText: String {
        String(format: "%02d:%02d", remainingSeconds / 60, remainingSeconds % 60)
    }

    func select(_ minutes: Int) {
        guard !isRunning, minutes > 0 else { return }

        self.minutes = minutes
        remainingSeconds = minutes * 60
    }

    func toggle() {
        if remainingSeconds == 0 {
            remainingSeconds = minutes * 60
        }
        isRunning.toggle()
    }

    func reset() {
        isRunning = false
        remainingSeconds = minutes * 60
    }

    func tick() {
        guard isRunning else { return }

        if remainingSeconds > 1 {
            remainingSeconds -= 1
        } else {
            remainingSeconds = 0
            isRunning = false
            completedSessions += 1
            defaults.set(completedSessions, forKey: "completedSessions")
        }
    }
}

import XCTest
@testable import AppCore

final class FocusTimerTests: XCTestCase {
    func testSessionControls() async {
        await MainActor.run {
            let defaults = UserDefaults(suiteName: "FocusTimerTests")!
            defaults.removePersistentDomain(forName: "FocusTimerTests")
            let timer = FocusTimer(minutes: 1, defaults: defaults)

            XCTAssertEqual(timer.timeText, "01:00")
            timer.select(2)
            XCTAssertEqual(timer.remainingSeconds, 120)

            timer.toggle()
            timer.tick()
            XCTAssertEqual(timer.remainingSeconds, 119)

            timer.toggle()
            timer.tick()
            XCTAssertEqual(timer.remainingSeconds, 119)

            timer.reset()
            XCTAssertEqual(timer.remainingSeconds, 120)
        }
    }

    func testCompletesAndPersistsSession() async {
        await MainActor.run {
            let defaults = UserDefaults(suiteName: "FocusTimerTests")!
            defaults.removePersistentDomain(forName: "FocusTimerTests")
            let timer = FocusTimer(minutes: 1, defaults: defaults)
            timer.toggle()

            for _ in 0..<60 {
                timer.tick()
            }

            XCTAssertEqual(timer.remainingSeconds, 0)
            XCTAssertEqual(timer.completedSessions, 1)
            XCTAssertFalse(timer.isRunning)
            XCTAssertEqual(FocusTimer(defaults: defaults).completedSessions, 1)
        }
    }
}

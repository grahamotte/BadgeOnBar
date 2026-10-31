import SwiftUI

@main
struct CodemotoApp: App {
    init() {
        #if APP_DEV && os(macOS)
        DebugHooks.install()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            AppView()
        }
    }
}

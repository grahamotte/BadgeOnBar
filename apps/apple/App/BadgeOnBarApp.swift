import SwiftUI
import AppKit

private let configWindowID = "config"

@main
struct BadgeOnBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("Badge on Bar", id: configWindowID) {
            ConfigurationWindow(appDelegate: appDelegate)
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.presented)
    }
}

private struct ConfigurationWindow: View {
    let appDelegate: AppDelegate
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        ConfigurationView()
            .environment(appDelegate.settings)
            .environment(appDelegate.monitor)
            .onAppear {
                appDelegate.openConfigWindow = { openWindow(id: configWindowID) }
                appDelegate.setConfigWindowOpen(true)
            }
            .onDisappear { appDelegate.setConfigWindowOpen(false) }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let settings = AppSettings()
    let monitor = BadgeMonitor()
    var openConfigWindow: (() -> Void)?
    private var statusBarManager: StatusBarManager?

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarManager = StatusBarManager(settings: settings, monitor: monitor)
        statusBarManager?.onShowConfig = { [weak self] in self?.showConfigWindow() }
        monitor.start()
        PermissionsManager.checkOrPrompt()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showConfigWindow()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
    }

    func setConfigWindowOpen(_ isOpen: Bool) {
        NSApp.setActivationPolicy(isOpen ? .regular : .accessory)
        if isOpen { NSApp.activate() }
    }

    func showConfigWindow() {
        let window = NSApp.windows.first { $0.identifier?.rawValue == configWindowID }
        window?.collectionBehavior.insert(.moveToActiveSpace)
        openConfigWindow?()
        NSApp.activate()
        window?.orderFrontRegardless()
    }
}

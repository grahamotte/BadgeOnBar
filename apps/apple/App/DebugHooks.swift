#if APP_DEV && os(macOS)
import AppKit

enum DebugHooks {
    static func install(custom: @escaping @MainActor (String, [String]) -> Void = { _, _ in }) {
        let name = Notification.Name("\(Bundle.main.bundleIdentifier ?? "app").debug")
        DistributedNotificationCenter.default().addObserver(forName: name, object: nil, queue: .main) { note in
            let command = note.object as? String ?? ""
            MainActor.assumeIsolated { run(command, custom: custom) }
        }
    }

    static func run(_ command: String, custom: (String, [String]) -> Void) {
        guard let command = DebugCommand(command) else { return }
        switch command {
        case .snap(let path, let title):
            guard let view = window(titled: title)?.contentView?.superview,
                  let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
            view.cacheDisplay(in: view.bounds, to: rep)
            try? rep.representation(using: .png, properties: [:])?.write(to: URL(filePath: path))
        case .frame(let width, let height):
            guard let window = window(titled: nil) else { return }
            let frame = window.frame
            window.setFrame(NSRect(x: frame.minX, y: frame.maxY - height, width: width, height: height), display: true)
        case .action(let name):
            if !NSApp.sendAction(Selector(name), to: nil, from: nil) {
                _ = window(titled: nil)?.firstResponder?.tryToPerform(Selector(name), with: nil)
            }
        case .key(let code, let modifiers, let characters):
            guard let window = window(titled: nil) else { return }
            let flags = modifiers.reduce(into: NSEvent.ModifierFlags()) { $0.insert(flag(for: $1)) }
            for type in [NSEvent.EventType.keyDown, .keyUp] {
                guard let event = NSEvent.keyEvent(with: type, location: .zero, modifierFlags: flags, timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber, context: nil, characters: characters, charactersIgnoringModifiers: characters, isARepeat: false, keyCode: code) else { continue }
                if type == .keyDown, NSApp.mainMenu?.performKeyEquivalent(with: event) == true || window.performKeyEquivalent(with: event) { continue }
                window.sendEvent(event)
            }
        case .type(let text):
            (window(titled: nil)?.firstResponder as? NSTextInputClient)?.insertText(text, replacementRange: NSRange(location: NSNotFound, length: 0))
        case .custom(let name, let arguments):
            custom(name, arguments)
        }
    }

    private static func window(titled title: String?) -> NSWindow? {
        if let title {
            return NSApp.windows.first { $0.title == title }
        }
        return NSApp.mainWindow ?? NSApp.orderedWindows.first { $0.isVisible && $0.canBecomeMain }
    }

    private static func flag(for modifier: DebugCommand.Modifier) -> NSEvent.ModifierFlags {
        switch modifier {
        case .command: .command
        case .shift: .shift
        case .option: .option
        case .control: .control
        case .function: .function
        case .numericPad: .numericPad
        }
    }
}
#endif

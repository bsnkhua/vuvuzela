import AppKit
import ServiceManagement
import Sparkle
import SwiftUI
import VuvuzelaCore

@main
struct VuvuzelaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @AppStorage(WidgetSettings.positionLockedKey) private var positionLocked = false
    @AppStorage(WidgetSettings.backgroundOpacityKey) private var backgroundOpacity = WidgetSettings.defaultOpacity

    var body: some Scene {
        MenuBarExtra {
            Button("Vuvuzela v\(appDelegate.currentVersion)") {
                NSWorkspace.shared.open(URL(string: "https://github.com/bsnkhua/vuvuzela")!)
            }
            Button("Report an Issue") {
                NSWorkspace.shared.open(URL(string: "https://github.com/bsnkhua/vuvuzela/issues")!)
            }
            Divider()
            Toggle("Lock position", isOn: $positionLocked)
            LaunchAtLoginToggle()
            if #unavailable(macOS 26) {
                Menu("Opacity") {
                    Picker("Opacity", selection: $backgroundOpacity) {
                        Text("100%").tag(1.0)
                        Text("92%").tag(0.92)
                        Text("85%").tag(0.85)
                        Text("70%").tag(0.7)
                    }
                }
            }
            Divider()
            Button("Check for Updates…") {
                appDelegate.updaterController.updater.checkForUpdates()
            }
            .disabled(!appDelegate.updaterController.updater.canCheckForUpdates)
            Button("Refresh Now") {
                Task { await appDelegate.store.refresh() }
            }
            .keyboardShortcut("r")
            Divider()
            Button("Quit Vuvuzela") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        } label: {
            Text("⚽")
                .font(.system(size: 13))
        }
    }
}

private struct LaunchAtLoginToggle: View {
    @State private var enabled = SMAppService.mainApp.status == .enabled

    var body: some View {
        Toggle("Launch at login", isOn: Binding(
            get: { enabled },
            set: { newValue in
                do {
                    if newValue { try SMAppService.mainApp.register() }
                    else { try SMAppService.mainApp.unregister() }
                    enabled = newValue
                } catch {
                    enabled = SMAppService.mainApp.status == .enabled
                }
            }
        ))
    }
}

private var isDraggingAllowed: Bool {
    !UserDefaults.standard.bool(forKey: WidgetSettings.positionLockedKey)
}

final class WidgetHostingView<Content: View>: NSHostingView<Content> {
    override var mouseDownCanMoveWindow: Bool { false }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

final class DesktopWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    override func mouseDown(with event: NSEvent) {
        if event.type == .leftMouseDown, isDraggingAllowed {
            performDrag(with: event)
        } else {
            super.mouseDown(with: event)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: DesktopWindow?
    let store = WorldCupStore()
    let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        if SMAppService.mainApp.status == .enabled {
            try? SMAppService.mainApp.register()
        }

        store.start()

        let window = DesktopWindow(
            contentRect: NSRect(x: 0, y: 0, width: WidgetSettings.defaultWidth, height: 500),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false

        let hostingView = WidgetHostingView(rootView: ContentView(store: store))
        window.contentView = hostingView

        let fitting = hostingView.fittingSize
        if fitting.width > 0, fitting.height > 0 {
            window.setContentSize(fitting)
        }

        window.center()
        window.setFrameAutosaveName("VuvuzelaWindow")
        window.orderFrontRegardless()
        self.window = window

        NotificationCenter.default.addObserver(
            forName: NSWindow.didChangeOcclusionStateNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, let w = self.window else { return }
                if w.occlusionState.contains(.visible) { self.store.resume() }
                else { self.store.suspend() }
            }
        }

        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.syncWindowSize() }
        }

        syncWindowSize()
    }

    private func syncWindowSize() {
        guard let window else { return }
        let stored = UserDefaults.standard.object(forKey: WidgetSettings.widgetWidthKey) as? Double
            ?? WidgetSettings.defaultWidth
        let targetWidth = WidgetSettings.clampWidth(stored)
        let widthChanged = abs(window.frame.width - targetWidth) > 0.5
        DispatchQueue.main.async { [weak self] in
            guard let self, let window = self.window, let cv = window.contentView else { return }
            let fh = cv.fittingSize.height
            let heightChanged = fh > 0 && abs(window.frame.height - fh) > 0.5
            if widthChanged || heightChanged {
                window.setContentSize(NSSize(
                    width: widthChanged ? targetWidth : window.frame.width,
                    height: heightChanged ? fh : window.frame.height
                ))
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        store.stop()
    }
}

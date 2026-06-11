import MeowPlannerCore
import SwiftData
import SwiftUI

#if os(macOS)
import AppKit

private let mainWindowDefaultContentSize = NSSize(width: 1240, height: 760)
private let mainWindowCompactContentMinSize = NSSize(width: 240, height: 180)

private final class MeowPlannerApplicationDelegate: NSObject, NSApplicationDelegate {
    override init() {
        UserDefaults.standard.set(true, forKey: "ApplePersistenceIgnoreState")
        UserDefaults.standard.set(false, forKey: "NSQuitAlwaysKeepsWindows")
    }

    func applicationShouldRestoreApplicationState(_ app: NSApplication) -> Bool {
        false
    }

    func applicationShouldSaveApplicationState(_ app: NSApplication) -> Bool {
        false
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        requestMainWindowRestore()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        requestMainWindowRestore()
        return true
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard urls.contains(where: { $0.scheme?.lowercased() == "meowplanner" }) else {
            return
        }

        requestExternalURLMainWindowOpen()
    }

    private func requestMainWindowRestore() {
        let delays: [UInt64] = [120_000_000, 450_000_000, 900_000_000]
        for delay in delays {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: delay)
                AppMainWindowPresenter.shared.openConfiguredMainWindow()
                NotificationCenter.default.post(name: .meowPlannerRestoreMainWindow, object: nil)
            }
        }
    }

    private func requestExternalURLMainWindowOpen() {
        let delays: [UInt64] = [0, 80_000_000, 220_000_000, 520_000_000]
        for delay in delays {
            Task { @MainActor in
                if delay > 0 {
                    try? await Task.sleep(nanoseconds: delay)
                }
                AppMainWindowPresenter.shared.openConfiguredMainWindow()
                NotificationCenter.default.post(name: .meowPlannerExternalOpenURL, object: nil)
            }
        }
    }
}
#endif

@main
struct MeowPlannerApp: App {
    private let modelContainer: ModelContainer
    @AppStorage(AppLanguage.storageKey) private var appLanguageID = AppLanguage.english.rawValue
    @AppStorage(AppAppearancePreference.storageKey) private var appearanceID = AppAppearancePreference.system.rawValue
    @AppStorage(AppDockIconController.storageKey) private var showDockIcon = AppDockIconController.defaultShowDockIcon
    @StateObject private var focusTimerStore: FocusTimerStore
    #if os(macOS)
    @NSApplicationDelegateAdaptor(MeowPlannerApplicationDelegate.self) private var appDelegate
    #endif

    init() {
        let focusTimerStore = FocusTimerStore()
        _focusTimerStore = StateObject(wrappedValue: focusTimerStore)

        let initialShowDockIcon = UserDefaults.standard.object(forKey: AppDockIconController.storageKey) as? Bool
            ?? AppDockIconController.defaultShowDockIcon
        AppIconInstaller.apply(showDockIcon: initialShowDockIcon)

        do {
            modelContainer = try ModelContainerFactory.make(cloudKitEnabled: false)
        } catch {
            fatalError("Unable to create MeowPlanner model container: \(error)")
        }

        #if os(macOS)
        AppMainWindowPresenter.shared.configure(
            modelContainer: modelContainer,
            focusTimerStore: focusTimerStore
        )
        #endif
    }

    var body: some Scene {
        #if os(macOS)
        WindowGroup("MeowPlanner", id: "main") {
            RootView()
                .environment(\.appLanguage, appLanguage)
                .environmentObject(focusTimerStore)
                .modelContainer(modelContainer)
                .preferredColorScheme(appAppearance.preferredColorScheme)
                .onAppear {
                    AppAppearancePreferenceApplicator.apply(appAppearance)
                    AppIconInstaller.apply(showDockIcon: showDockIcon)
                }
                .onChange(of: appearanceID) { _, newValue in
                    AppAppearancePreferenceApplicator.apply(AppAppearancePreference(storedValue: newValue))
                }
                .onChange(of: showDockIcon) { _, newValue in
                    AppDockIconController.apply(showDockIcon: newValue)
                }
        }
        .defaultSize(width: mainWindowDefaultContentSize.width, height: mainWindowDefaultContentSize.height)
        #else
        WindowGroup(id: "main") {
            RootView()
                .environment(\.appLanguage, appLanguage)
                .environmentObject(focusTimerStore)
                .modelContainer(modelContainer)
                .preferredColorScheme(appAppearance.preferredColorScheme)
        }
        #endif

        #if os(macOS)
        MenuBarExtra {
            MeowPlannerMenuBarView(openAppKitMainWindow: openAppKitMainWindow)
                .environment(\.appLanguage, appLanguage)
                .environmentObject(focusTimerStore)
                .modelContainer(modelContainer)
        } label: {
            MeowPlannerMenuBarLabel(openAppKitMainWindow: openAppKitMainWindow)
                .environment(\.appLanguage, appLanguage)
                .environmentObject(focusTimerStore)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(\.appLanguage, appLanguage)
                .modelContainer(modelContainer)
                .preferredColorScheme(appAppearance.preferredColorScheme)
                .onAppear {
                    AppAppearancePreferenceApplicator.apply(appAppearance)
                }
                .onChange(of: appearanceID) { _, newValue in
                    AppAppearancePreferenceApplicator.apply(AppAppearancePreference(storedValue: newValue))
                }
        }
        #endif
    }

    private var appLanguage: AppLanguage {
        AppLanguage(storedValue: appLanguageID)
    }

    private var appAppearance: AppAppearancePreference {
        AppAppearancePreference(storedValue: appearanceID)
    }

    #if os(macOS)
    @MainActor
    private func openAppKitMainWindow() {
        AppMainWindowPresenter.shared.open(
            modelContainer: modelContainer,
            focusTimerStore: focusTimerStore
        )
    }
    #endif
}

#if os(macOS)
@MainActor
private final class AppMainWindowPresenter {
    static let shared = AppMainWindowPresenter()

    private var window: NSWindow?
    private var modelContainer: ModelContainer?
    private var focusTimerStore: FocusTimerStore?

    func configure(modelContainer: ModelContainer, focusTimerStore: FocusTimerStore) {
        self.modelContainer = modelContainer
        self.focusTimerStore = focusTimerStore
    }

    func openConfiguredMainWindow() {
        guard let modelContainer,
              let focusTimerStore
        else {
            return
        }

        open(modelContainer: modelContainer, focusTimerStore: focusTimerStore)
    }

    func open(modelContainer: ModelContainer, focusTimerStore: FocusTimerStore) {
        if let existingWindow = window ?? existingMainWindow() {
            window = existingWindow
            show(existingWindow)
            return
        }

        let rootView = AppHostedMainWindowRoot(
            modelContainer: modelContainer,
            focusTimerStore: focusTimerStore
        )
        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hostingController)
        window.identifier = NSUserInterfaceItemIdentifier("main")
        window.title = "MeowPlanner"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.contentMinSize = mainWindowCompactContentMinSize
        window.setContentSize(mainWindowDefaultContentSize)
        window.setFrameAutosaveName("MeowPlanner.MainWindow")
        window.isReleasedWhenClosed = false
        window.center()
        self.window = window
        show(window)
    }

    private func show(_ window: NSWindow) {
        let showDockIcon = AppDockIconController.currentShowDockIconPreference
        AppDockIconController.prepareForMainWindowPresentation(showDockIcon: showDockIcon)

        if window.isMiniaturized {
            window.deminiaturize(nil)
        }

        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApplication.shared.activate(ignoringOtherApps: true)
        AppDockIconController.restorePreferredActivationPolicyAfterMainWindowPresentation(showDockIcon: showDockIcon)
    }

    private func existingMainWindow() -> NSWindow? {
        NSApplication.shared.windows.first { window in
            window.identifier?.rawValue == "main" || window.title == "MeowPlanner"
        }
    }
}

private struct AppHostedMainWindowRoot: View {
    let modelContainer: ModelContainer
    @ObservedObject var focusTimerStore: FocusTimerStore
    @AppStorage(AppLanguage.storageKey) private var appLanguageID = AppLanguage.english.rawValue
    @AppStorage(AppAppearancePreference.storageKey) private var appearanceID = AppAppearancePreference.system.rawValue

    var body: some View {
        RootView()
            .environment(\.appLanguage, appLanguage)
            .environmentObject(focusTimerStore)
            .modelContainer(modelContainer)
            .preferredColorScheme(appAppearance.preferredColorScheme)
            .onAppear {
                AppAppearancePreferenceApplicator.apply(appAppearance)
            }
            .onChange(of: appearanceID) { _, newValue in
                AppAppearancePreferenceApplicator.apply(AppAppearancePreference(storedValue: newValue))
            }
    }

    private var appLanguage: AppLanguage {
        AppLanguage(storedValue: appLanguageID)
    }

    private var appAppearance: AppAppearancePreference {
        AppAppearancePreference(storedValue: appearanceID)
    }
}
#endif

#if os(macOS)
@MainActor
private enum AppAppearancePreferenceApplicator {
    static func apply(_ preference: AppAppearancePreference) {
        switch preference {
        case .system:
            NSApp.appearance = nil
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }
}
#endif

private extension AppAppearancePreference {
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}

import FirebaseCore
#if os(iOS)
import FirebaseAuth
#endif
import MeowPlannerCore
import SwiftData
import SwiftUI

#if os(macOS)
import AppKit
import Darwin

private let mainWindowDefaultContentSize = NSSize(width: 1240, height: 760)
private let mainWindowCompactContentMinSize = NSSize(width: 240, height: 180)

private enum MeowPlannerSingleInstanceGuard {
    static func exitIfAnotherInstanceIsRunning() {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.yuelingqiu.MeowPlanner"
        let currentProcessIdentifier = ProcessInfo.processInfo.processIdentifier
        let existingApplication = NSRunningApplication
            .runningApplications(withBundleIdentifier: bundleIdentifier)
            .first { application in
                application.processIdentifier != currentProcessIdentifier && !application.isTerminated
            }

        guard let existingApplication else {
            return
        }

        DistributedNotificationCenter.default().postNotificationName(
            .meowPlannerDuplicateLaunchRequested,
            object: bundleIdentifier,
            userInfo: nil,
            deliverImmediately: true
        )
        existingApplication.activate(options: [.activateAllWindows])
        exit(0)
    }
}

@MainActor
enum MainWindowChromeConfigurator {
    static func apply(to window: NSWindow) {
        window.styleMask.formUnion([.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView])
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = NSColor(MeowPlannerTheme.fufuPlannerBackground)
        window.titlebarSeparatorStyle = .none
        window.contentMinSize = mainWindowCompactContentMinSize
    }
}

private final class MeowPlannerApplicationDelegate: NSObject, NSApplicationDelegate {
    override init() {
        UserDefaults.standard.set(true, forKey: "ApplePersistenceIgnoreState")
        UserDefaults.standard.set(false, forKey: "NSQuitAlwaysKeepsWindows")
        super.init()
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleDuplicateLaunchRequest(_:)),
            name: .meowPlannerDuplicateLaunchRequested,
            object: Bundle.main.bundleIdentifier ?? "com.yuelingqiu.MeowPlanner"
        )
    }

    deinit {
        DistributedNotificationCenter.default().removeObserver(self)
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

    @objc private func handleDuplicateLaunchRequest(_ notification: Notification) {
        requestMainWindowRestore()
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

#if os(iOS)
private enum FirebaseAuthKeychainConfigurator {
    static func apply() {
        guard let accessGroup = currentKeychainAccessGroup() else {
            return
        }

        try? Auth.auth().useUserAccessGroup(accessGroup)
    }

    private static func currentKeychainAccessGroup() -> String? {
        guard let rawPrefix = Bundle.main.object(forInfoDictionaryKey: "AppIdentifierPrefix") as? String,
              !rawPrefix.isEmpty,
              !rawPrefix.contains("$(") else {
            return nil
        }

        let prefix = rawPrefix.hasSuffix(".") ? rawPrefix : "\(rawPrefix)."
        return "\(prefix)com.yuelingqiu.MeowPlanner"
    }
}
#endif

@main
struct MeowPlannerApp: App {
    private let legacyModelContainer: ModelContainer
    @AppStorage(AppLanguage.storageKey) private var appLanguageID = AppLanguage.english.rawValue
    @AppStorage(AppAppearancePreference.storageKey) private var appearanceID = AppAppearancePreference.system.rawValue
    @AppStorage(AppDockIconController.storageKey) private var showDockIcon = AppDockIconController.defaultShowDockIcon
    @StateObject private var focusTimerStore: FocusTimerStore
    #if os(macOS)
    @AppStorage(AppMenuBarIconPreference.storageKey) private var showMenuBarIcon = AppMenuBarIconPreference.defaultShowMenuBarIcon
    @NSApplicationDelegateAdaptor(MeowPlannerApplicationDelegate.self) private var appDelegate
    #endif

    init() {
        AppAppearancePreference.migrateLegacyValueIfNeeded()

        #if os(macOS)
        MeowPlannerSingleInstanceGuard.exitIfAnotherInstanceIsRunning()
        #endif

        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        #if os(iOS)
        FirebaseAuthKeychainConfigurator.apply()
        #endif

        let focusTimerStore = FocusTimerStore()
        _focusTimerStore = StateObject(wrappedValue: focusTimerStore)

        let initialShowDockIcon = UserDefaults.standard.object(forKey: AppDockIconController.storageKey) as? Bool
            ?? AppDockIconController.defaultShowDockIcon
        AppIconInstaller.apply(showDockIcon: initialShowDockIcon)

        let launchSnapshotModelContainer: ModelContainer
        do {
            launchSnapshotModelContainer = try ModelContainerFactory.make(cloudKitEnabled: false)
            legacyModelContainer = launchSnapshotModelContainer
        } catch {
            fatalError("Unable to create MeowPlanner model container: \(error)")
        }

        #if os(macOS)
        AppMainWindowPresenter.shared.configure(
            legacyModelContainer: legacyModelContainer,
            focusTimerStore: focusTimerStore
        )
        AppLaunchWidgetSnapshotRefresher.schedule(legacyModelContainer: launchSnapshotModelContainer)
        #endif
    }

    var body: some Scene {
        #if os(macOS)
        WindowGroup("MeowPlanner", id: "main") {
            AccountGatedRootView(
                legacyModelContainer: legacyModelContainer,
                focusTimerStore: focusTimerStore
            )
                .environment(\.appLanguage, appLanguage)
                .environmentObject(focusTimerStore)
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
            AccountGatedRootView(
                legacyModelContainer: legacyModelContainer,
                focusTimerStore: focusTimerStore
            )
                .environment(\.appLanguage, appLanguage)
                .environmentObject(focusTimerStore)
                .preferredColorScheme(appAppearance.preferredColorScheme)
                .onOpenURL { url in
                    NotificationCenter.default.post(name: .meowPlannerExternalOpenURL, object: url)
                }
        }
        #endif

        #if os(macOS)
        MenuBarExtra(isInserted: $showMenuBarIcon) {
            MeowPlannerMenuBarView(
                legacyModelContainer: legacyModelContainer,
                openAppKitMainWindow: openAppKitMainWindow
            )
                .environment(\.appLanguage, appLanguage)
                .environmentObject(focusTimerStore)
        } label: {
            MeowPlannerMenuBarLabel(openAppKitMainWindow: openAppKitMainWindow)
                .environment(\.appLanguage, appLanguage)
                .environmentObject(focusTimerStore)
        }
        .menuBarExtraStyle(.window)

        Settings {
            AccountGatedSettingsView(legacyModelContainer: legacyModelContainer)
                .environment(\.appLanguage, appLanguage)
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
            legacyModelContainer: legacyModelContainer,
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
    private var legacyModelContainer: ModelContainer?
    private var focusTimerStore: FocusTimerStore?

    func configure(legacyModelContainer: ModelContainer, focusTimerStore: FocusTimerStore) {
        self.legacyModelContainer = legacyModelContainer
        self.focusTimerStore = focusTimerStore
    }

    func openConfiguredMainWindow() {
        guard let legacyModelContainer,
              let focusTimerStore
        else {
            return
        }

        open(legacyModelContainer: legacyModelContainer, focusTimerStore: focusTimerStore)
    }

    func open(legacyModelContainer: ModelContainer, focusTimerStore: FocusTimerStore) {
        if let existingWindow = window ?? existingMainWindow() {
            window = existingWindow
            MainWindowChromeConfigurator.apply(to: existingWindow)
            show(existingWindow)
            return
        }

        let rootView = AppHostedMainWindowRoot(
            legacyModelContainer: legacyModelContainer,
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
        MainWindowChromeConfigurator.apply(to: window)
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
    let legacyModelContainer: ModelContainer
    @ObservedObject var focusTimerStore: FocusTimerStore
    @AppStorage(AppLanguage.storageKey) private var appLanguageID = AppLanguage.english.rawValue
    @AppStorage(AppAppearancePreference.storageKey) private var appearanceID = AppAppearancePreference.system.rawValue

    var body: some View {
        AccountGatedRootView(
            legacyModelContainer: legacyModelContainer,
            focusTimerStore: focusTimerStore
        )
            .environment(\.appLanguage, appLanguage)
            .environmentObject(focusTimerStore)
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

@MainActor
private enum AppLaunchWidgetSnapshotRefresher {
    static func schedule(legacyModelContainer: ModelContainer) {
        for delay in [350_000_000, 1_200_000_000, 2_400_000_000] as [UInt64] {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: delay)
                publishSnapshot(legacyModelContainer: legacyModelContainer)
            }
        }
    }

    private static func publishSnapshot(legacyModelContainer: ModelContainer) {
        let accountStore = AccountSessionStore.shared
        let accountContainerStore = AccountScopedModelContainerStore.shared
        let container: ModelContainer

        if let currentProfile = accountStore.currentProfile {
            accountContainerStore.prepareContainer(
                for: currentProfile,
                legacyModelContainer: legacyModelContainer
            )

            guard accountContainerStore.activeUserID == currentProfile.remoteUserID,
                  let activeAccountContainer = accountContainerStore.modelContainer
            else {
                return
            }

            container = activeAccountContainer
        } else {
            accountContainerStore.prepareSignedOutContainer()

            guard let signedOutModelContainer = accountContainerStore.signedOutModelContainer else {
                return
            }

            container = signedOutModelContainer
        }

        let context = ModelContext(container)
        WidgetTimelineSyncService.publishSnapshotAndReload(using: context)
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

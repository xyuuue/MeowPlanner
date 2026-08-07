import SwiftUI

enum AppMenuBarIconPreference {
    static let storageKey = "meowplanner.showMenuBarIcon"
    static let defaultShowMenuBarIcon = true
}

#if os(macOS)
import AppKit

enum AppDockIconController {
    static let storageKey = "meowplanner.showDockIcon"
    static let defaultShowDockIcon = false

    static var currentShowDockIconPreference: Bool {
        UserDefaults.standard.object(forKey: storageKey) as? Bool ?? defaultShowDockIcon
    }

    @MainActor
    static func apply(showDockIcon: Bool, relaunchIfNeeded: Bool = false) {
        let application = NSApplication.shared
        let previousActivationPolicy = application.activationPolicy()
        _ = application.setActivationPolicy(showDockIcon ? .regular : .accessory)

        if showDockIcon {
            application.activate(ignoringOtherApps: true)
        }

        if showDockIcon && relaunchIfNeeded && previousActivationPolicy != .regular {
            scheduleRelaunchForDockRegistrationIfNeeded()
        }
    }

    @MainActor
    static func prepareForMainWindowPresentation(showDockIcon: Bool) {
        guard !showDockIcon else {
            return
        }

        let application = NSApplication.shared
        guard application.activationPolicy() != .regular else {
            return
        }

        _ = application.setActivationPolicy(.regular)
    }

    @MainActor
    static func restorePreferredActivationPolicyAfterMainWindowPresentation(showDockIcon: Bool) {
        guard !showDockIcon else {
            return
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 700_000_000)
            guard currentShowDockIconPreference == false else {
                return
            }

            let application = NSApplication.shared
            _ = application.setActivationPolicy(.accessory)
        }
    }

    @MainActor
    private static func scheduleRelaunchForDockRegistrationIfNeeded() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000)
            relaunch()
        }
    }

    @MainActor
    private static func relaunch() {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        configuration.createsNewApplicationInstance = true

        NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: configuration) { _, error in
            guard error == nil else {
                return
            }

            Task { @MainActor in
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
#else
enum AppDockIconController {
    static let storageKey = "meowplanner.showDockIcon"
    static let defaultShowDockIcon = false
    static var currentShowDockIconPreference: Bool { defaultShowDockIcon }

    static func apply(showDockIcon: Bool, relaunchIfNeeded: Bool = false) {}
    static func prepareForMainWindowPresentation(showDockIcon: Bool) {}
    static func restorePreferredActivationPolicyAfterMainWindowPresentation(showDockIcon: Bool) {}
}
#endif

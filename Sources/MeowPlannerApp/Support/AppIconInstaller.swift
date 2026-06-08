import SwiftUI

#if os(macOS)
import AppKit

enum AppIconInstaller {
    @MainActor
    static func apply(showDockIcon: Bool) {
        AppDockIconController.apply(showDockIcon: showDockIcon)

        guard let url = appIconURL(),
              let image = NSImage(contentsOf: url) else {
            return
        }

        NSApplication.shared.applicationIconImage = image
    }

    private static func appIconURL() -> URL? {
        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(
            forResource: "AppIcon",
            withExtension: "png",
            subdirectory: "AppIcon"
        ) {
            return url
        }
        #endif

        return Bundle.main.url(
            forResource: "AppIcon",
            withExtension: "png",
            subdirectory: "AppIcon"
        )
    }
}
#else
enum AppIconInstaller {
    static func apply(showDockIcon: Bool) {}
}
#endif

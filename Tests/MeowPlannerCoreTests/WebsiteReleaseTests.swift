import Foundation
import Testing

#if os(macOS)
import AppKit
#endif

@Suite("Website release downloads")
struct WebsiteReleaseTests {
    @Test("package script creates and syncs website DMG artifacts")
    func packageScriptCreatesAndSyncsWebsiteDMGArtifacts() throws {
        let root = try releasePackageRoot()
        let scriptFile = root
            .appendingPathComponent("script/package_dmg.sh")

        #expect(FileManager.default.fileExists(atPath: scriptFile.path))

        let script = try String(contentsOf: scriptFile, encoding: .utf8)
        #expect(script.contains("APP_NAME=\"MeowPlanner\""))
        #expect(script.contains("DMG_PATH=\"$DIST_DIR/$APP_NAME.dmg\""))
        #expect(script.contains("WEBSITE_DOWNLOAD_DIR=\"$ROOT_DIR/website/downloads\""))
        #expect(script.contains("WEBSITE_DMG=\"$WEBSITE_DOWNLOAD_DIR/$APP_NAME.dmg\""))
        #expect(script.contains("WEBSITE_SHA=\"$WEBSITE_DOWNLOAD_DIR/$APP_NAME.dmg.sha256\""))
        #expect(script.contains("XCODE_DESTINATION=generic/platform=macOS"))
        #expect(script.contains("ONLY_ACTIVE_ARCH=NO"))
        #expect(script.contains("script/build_and_run.sh --build-only"))
        #expect(script.contains("create-dmg"))
        #expect(script.contains("hdiutil create"))
        #expect(script.contains("hdiutil verify \"$DMG_PATH\""))
        #expect(script.contains("/usr/bin/ditto \"$DMG_PATH\" \"$WEBSITE_DMG\""))
        #expect(script.contains("shasum -a 256 \"$WEBSITE_DMG\""))
    }

    @Test("website exposes enabled DMG and checksum downloads")
    func websiteExposesEnabledDMGAndChecksumDownloads() throws {
        let root = try releasePackageRoot()
        let htmlFile = root
            .appendingPathComponent("website/index.html")
        let scriptFile = root
            .appendingPathComponent("website/script.js")

        let html = try String(contentsOf: htmlFile, encoding: .utf8)
        let script = try String(contentsOf: scriptFile, encoding: .utf8)

        #expect(html.contains("href=\"/downloads/MeowPlanner.dmg\""))
        #expect(html.contains("href=\"/downloads/MeowPlanner.dmg.sha256\""))
        #expect(html.contains("data-i18n=\"downloadButton\""))
        #expect(html.contains("data-i18n=\"checksumButton\""))
        #expect(!html.contains("data-disabled-download"))
        #expect(!html.contains("aria-disabled=\"true\""))
        #expect(!html.contains("is-disabled"))

        #expect(script.contains("navCta: \"Download\""))
        #expect(script.contains("primaryCta: \"Download DMG\""))
        #expect(script.contains("downloadTitle: \"Download MeowPlanner for Mac\""))
        #expect(script.contains("downloadButton: \"Download DMG\""))
        #expect(script.contains("checksumButton: \"View SHA-256\""))
        #expect(script.contains("navCta: \"下载\""))
        #expect(script.contains("primaryCta: \"下载 DMG\""))
        #expect(script.contains("downloadTitle: \"下载 MeowPlanner for Mac\""))
        #expect(script.contains("downloadButton: \"下载 DMG\""))
        #expect(script.contains("checksumButton: \"查看 SHA-256\""))
        #expect(!script.contains("data-disabled-download"))
        #expect(!script.contains("coming soon"))
        #expect(!script.contains("即将开放"))
    }

    @Test("website app icon matches bundled app icon")
    func websiteAppIconMatchesBundledAppIcon() throws {
        let root = try releasePackageRoot()
        let htmlFile = root
            .appendingPathComponent("website/index.html")
        let infoPlistFile = root
            .appendingPathComponent("Config/MeowPlanner-Info.plist")
        let appIconFile = root
            .appendingPathComponent("Resources/AppIcon/AppIcon.png")
        let websiteIconFile = root
            .appendingPathComponent("website/assets/meowplanner-icon.png")

        let html = try String(contentsOf: htmlFile, encoding: .utf8)
        let infoData = try Data(contentsOf: infoPlistFile)
        let infoPlist = try #require(PropertyListSerialization.propertyList(from: infoData, format: nil) as? [String: Any])
        let version = try #require(infoPlist["CFBundleShortVersionString"] as? String)
        let appIconData = try Data(contentsOf: appIconFile)
        let websiteIconData = try Data(contentsOf: websiteIconFile)
        let cacheBustedIconPath = "/assets/meowplanner-icon.png?v=\(version)"
        let iconsMatch = websiteIconData == appIconData

        #expect(iconsMatch)
        #expect(html.contains("href=\"\(cacheBustedIconPath)\""))
        #expect(html.contains("src=\".\(cacheBustedIconPath)\""))
        #expect(!html.contains("/assets/meowplanner-icon.png\""))
        #expect(!html.contains("./assets/meowplanner-icon.png\""))
    }

    #if os(macOS)
    @Test("app icon assets keep transparent clipped corners")
    func appIconAssetsKeepTransparentClippedCorners() throws {
        let root = try releasePackageRoot()
        let iconFiles = [
            root.appendingPathComponent("Resources/AppIcon/AppIcon.png"),
            root.appendingPathComponent("Resources/AppIcon/AppIcon.appiconset/AppIcon-1024.png"),
            root.appendingPathComponent("Resources/AppIcon/AppIcon.iconset/icon_512x512@2x.png"),
            root.appendingPathComponent("website/assets/meowplanner-icon.png")
        ]

        for iconFile in iconFiles {
            let imageInfo = try bitmapInfo(for: iconFile)

            #expect(imageInfo.width == imageInfo.height)
            #expect(imageInfo.cornerAlphaValues.allSatisfy { $0 <= 0.02 })
        }
    }
    #endif

    private func releasePackageRoot() throws -> URL {
        let testFile = URL(fileURLWithPath: #filePath)
        return testFile
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    #if os(macOS)
    private func bitmapInfo(for imageURL: URL) throws -> (width: Int, height: Int, cornerAlphaValues: [CGFloat]) {
        let data = try Data(contentsOf: imageURL)
        let imageRep = try #require(NSBitmapImageRep(data: data))
        let width = imageRep.pixelsWide
        let height = imageRep.pixelsHigh
        let corners = [
            NSPoint(x: 0, y: 0),
            NSPoint(x: max(0, width - 1), y: 0),
            NSPoint(x: 0, y: max(0, height - 1)),
            NSPoint(x: max(0, width - 1), y: max(0, height - 1))
        ]
        let alphas = corners.map { point in
            imageRep.colorAt(x: Int(point.x), y: Int(point.y))?.alphaComponent ?? 1
        }

        return (width, height, alphas)
    }
    #endif
}

import Foundation
import SwiftData
import Testing
@testable import MeowPlannerCore

@Suite("Widget planner snapshot")
struct WidgetPlannerSnapshotTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    @Test("snapshot stores visible planner data for widget timelines")
    func snapshotStoresVisiblePlannerDataForWidgetTimelines() throws {
        let event = PlannerEvent(
            title: "Study session",
            startDate: try date("2026-06-03 09:00"),
            endDate: try date("2026-06-03 10:00"),
            notes: "METCS",
            repeatRule: .weekly(interval: 1, weekdays: [4]),
            tagName: "学习",
            colorHex: "#71B7ED"
        )
        let todo = TodoItem(
            title: "Submit homework",
            dueDate: try date("2026-06-03 22:00"),
            createdAt: try date("2026-06-02 12:00")
        )
        let snapshot = WidgetPlannerSnapshot(
            events: [event],
            todos: [todo],
            habitCount: 2,
            weekStartPreference: .monday,
            showChineseCalendar: true,
            updatedAt: try date("2026-06-02 13:00")
        )

        let restoredEvent = try #require(snapshot.plannerEvents.first)
        let restoredTodo = try #require(snapshot.todoItems.first)

        #expect(snapshot.habitCount == 2)
        #expect(snapshot.weekStartPreference == .monday)
        #expect(snapshot.showChineseCalendar)
        #expect(restoredEvent.title == "Study session")
        #expect(restoredEvent.repeatRule == .weekly(interval: 1, weekdays: [4]))
        #expect(restoredEvent.tagName == "学习")
        #expect(restoredEvent.colorHex == "#71B7ED")
        let expectedDueDate = try date("2026-06-03 22:00")
        #expect(restoredTodo.title == "Submit homework")
        #expect(restoredTodo.dueDate == expectedDueDate)
    }

    @Test("snapshot stores completed schedule display preferences")
    func snapshotStoresCompletedScheduleDisplayPreferences() throws {
        let snapshot = WidgetPlannerSnapshot(
            events: [],
            todos: [],
            habitCount: 0,
            weekStartPreference: .monday,
            showChineseCalendar: true,
            showCompletedSchedules: false,
            completedSchedulesUseStrikethrough: false,
            updatedAt: try date("2026-06-02 13:00")
        )

        let data = try JSONEncoder().encode(snapshot)
        let restored = try JSONDecoder().decode(WidgetPlannerSnapshot.self, from: data)

        #expect(restored.showCompletedSchedules == false)
        #expect(restored.completedSchedulesUseStrikethrough == false)
    }

    @Test("widget date offsets use shared defaults and migrate legacy standard defaults")
    func widgetDateOffsetsUseSharedDefaultsAndMigrateLegacyStandardDefaults() throws {
        let sharedDefaults = try #require(UserDefaults(suiteName: WidgetConstants.appGroupName))
        let standardDefaults = UserDefaults.standard
        let weekKey = WidgetConstants.widgetWeekOffsetKey
        let monthKey = WidgetConstants.widgetMonthOffsetKey
        let originalSharedWeekOffset = sharedDefaults.object(forKey: weekKey)
        let originalSharedMonthOffset = sharedDefaults.object(forKey: monthKey)
        let originalStandardWeekOffset = standardDefaults.object(forKey: weekKey)
        let originalStandardMonthOffset = standardDefaults.object(forKey: monthKey)
        defer {
            restoreUserDefaultsValue(originalSharedWeekOffset, forKey: weekKey, defaults: sharedDefaults)
            restoreUserDefaultsValue(originalSharedMonthOffset, forKey: monthKey, defaults: sharedDefaults)
            restoreUserDefaultsValue(originalStandardWeekOffset, forKey: weekKey, defaults: standardDefaults)
            restoreUserDefaultsValue(originalStandardMonthOffset, forKey: monthKey, defaults: standardDefaults)
        }

        sharedDefaults.removeObject(forKey: weekKey)
        sharedDefaults.removeObject(forKey: monthKey)
        standardDefaults.removeObject(forKey: weekKey)
        standardDefaults.removeObject(forKey: monthKey)
        sharedDefaults.synchronize()
        standardDefaults.synchronize()

        sharedDefaults.set(4, forKey: weekKey)
        sharedDefaults.set(-2, forKey: monthKey)

        #expect(WidgetWeekSelectionStore.currentWeekOffset(platform: .iOS) == 4)
        #expect(WidgetMonthSelectionStore.currentMonthOffset(platform: .iOS) == -2)

        WidgetWeekSelectionStore.adjustWeekOffset(by: 1, platform: .iOS)
        WidgetMonthSelectionStore.adjustMonthOffset(by: -1, platform: .iOS)

        #expect(sharedDefaults.integer(forKey: weekKey) == 5)
        #expect(sharedDefaults.integer(forKey: monthKey) == -3)

        WidgetWeekSelectionStore.resetWeekOffset(platform: .iOS)
        WidgetMonthSelectionStore.resetMonthOffset(platform: .iOS)

        #expect(sharedDefaults.integer(forKey: weekKey) == 0)
        #expect(sharedDefaults.integer(forKey: monthKey) == 0)
        #expect(WidgetWeekSelectionStore.currentWeekOffset(platform: .iOS) == 0)
        #expect(WidgetMonthSelectionStore.currentMonthOffset(platform: .iOS) == 0)

        sharedDefaults.removeObject(forKey: weekKey)
        sharedDefaults.removeObject(forKey: monthKey)
        standardDefaults.set(-3, forKey: weekKey)
        standardDefaults.set(2, forKey: monthKey)
        sharedDefaults.synchronize()
        standardDefaults.synchronize()

        #expect(WidgetWeekSelectionStore.currentWeekOffset(platform: .iOS) == -3)
        #expect(WidgetMonthSelectionStore.currentMonthOffset(platform: .iOS) == 2)
        #expect(sharedDefaults.integer(forKey: weekKey) == -3)
        #expect(sharedDefaults.integer(forKey: monthKey) == 2)
    }

    @Test("widget background preference stores style and custom image data")
    func widgetBackgroundPreferenceStoresStyleAndCustomImageData() throws {
        let suiteName = "MeowPlannerWidgetBackgroundTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetBackground-\(UUID().uuidString).image")
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: fileURL)
        }

        #expect(WidgetPlannerPreferenceStore.widgetBackgroundStyle(defaults: defaults) == .defaultArtwork)

        WidgetPlannerPreferenceStore.setWidgetBackgroundStyle(.customPhoto, defaults: defaults)

        #expect(WidgetPlannerPreferenceStore.widgetBackgroundStyle(defaults: defaults) == .customPhoto)

        let data = Data([0x4d, 0x65, 0x6f, 0x77])
        try WidgetPlannerPreferenceStore.saveCustomBackgroundImageData(data, fileURL: fileURL)

        #expect(try Data(contentsOf: fileURL) == data)

        WidgetPlannerPreferenceStore.clearCustomBackgroundImage(fileURL: fileURL)

        #expect(!FileManager.default.fileExists(atPath: fileURL.path))
    }

    @Test("custom background private mirror repairs shared widget image data")
    func customBackgroundPrivateMirrorRepairsSharedWidgetImageData() throws {
        let suiteName = "MeowPlannerWidgetCustomPrivateMirrorTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetCustomPrivateMirror-\(UUID().uuidString)")
        let privateMirrorFileURL = temporaryDirectory
            .appendingPathComponent("AppPrivate")
            .appendingPathComponent(WidgetPlannerPreferenceStore.customBackgroundImageFilename)
        let widgetReadableFileURL = temporaryDirectory
            .appendingPathComponent("WidgetReadable")
            .appendingPathComponent(WidgetPlannerPreferenceStore.customBackgroundImageFilename)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        let data = Data([0x43, 0x75, 0x73, 0x74, 0x6f, 0x6d])
        try FileManager.default.createDirectory(
            at: privateMirrorFileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: privateMirrorFileURL, options: .atomic)

        #expect(
            WidgetPlannerPreferenceStore.customBackgroundImageData(
                platform: .iOS,
                defaults: defaults,
                fileURLs: [widgetReadableFileURL]
            ) == nil
        )

        #expect(
            WidgetPlannerPreferenceStore.repairCustomBackgroundImageMirrors(
                defaults: defaults,
                fileURLs: [privateMirrorFileURL, widgetReadableFileURL]
            )
        )
        #expect(defaults.data(forKey: WidgetPlannerPreferenceStore.customBackgroundImageDataKey) == data)
        #expect(
            WidgetPlannerPreferenceStore.customBackgroundImageData(
                platform: .iOS,
                defaults: defaults,
                fileURLs: [widgetReadableFileURL]
            ) == data
        )
    }

    @Test("custom background data read repairs missing widget mirror from shared defaults")
    func customBackgroundDataReadRepairsMissingWidgetMirrorFromSharedDefaults() throws {
        let suiteName = "MeowPlannerWidgetCustomSharedMirrorTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetCustomSharedMirror-\(UUID().uuidString)")
        let widgetReadableFileURL = temporaryDirectory
            .appendingPathComponent("WidgetReadable")
            .appendingPathComponent(WidgetPlannerPreferenceStore.customBackgroundImageFilename)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        let data = Data([0x53, 0x68, 0x61, 0x72, 0x65, 0x64])
        defaults.set(data, forKey: WidgetPlannerPreferenceStore.customBackgroundImageDataKey)
        defaults.synchronize()

        #expect(!FileManager.default.fileExists(atPath: widgetReadableFileURL.path))
        #expect(
            WidgetPlannerPreferenceStore.customBackgroundImageData(
                platform: .iOS,
                defaults: defaults,
                fileURLs: [widgetReadableFileURL]
            ) == data
        )
        #expect(try Data(contentsOf: widgetReadableFileURL) == data)
    }

    @Test("custom background save stores shared widget image data")
    func customBackgroundSaveStoresSharedWidgetImageData() throws {
        let suiteName = "MeowPlannerWidgetCustomSharedSaveTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetCustomSharedSave-\(UUID().uuidString)")
        let primaryFileURL = temporaryDirectory
            .appendingPathComponent(WidgetPlannerPreferenceStore.customBackgroundImageFilename)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        let data = Data([0x53, 0x61, 0x76, 0x65])
        try WidgetPlannerPreferenceStore.saveCustomBackgroundImageData(
            data,
            platform: .iOS,
            defaults: defaults,
            fileURLs: [primaryFileURL]
        )

        #expect(try Data(contentsOf: primaryFileURL) == data)
        #expect(defaults.data(forKey: WidgetPlannerPreferenceStore.customBackgroundImageDataKey) == data)
        #expect(WidgetPlannerPreferenceStore.validateCustomBackgroundImageData(platform: .iOS, defaults: defaults))
    }

    @Test("iOS custom background validation repairs shared data from file fallback")
    func iOSCustomBackgroundValidationRepairsSharedDataFromFileFallback() throws {
        let suiteName = "MeowPlannerWidgetCustomFileValidationTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetCustomFileValidation-\(UUID().uuidString)")
        let fileURL = temporaryDirectory
            .appendingPathComponent(WidgetPlannerPreferenceStore.customBackgroundImageFilename)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        let data = Data([0x46, 0x69, 0x6c, 0x65])
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)

        #expect(WidgetPlannerPreferenceStore.validateCustomBackgroundImageData(
            platform: .iOS,
            defaults: defaults,
            fileURLs: [fileURL]
        ))
        #expect(defaults.data(forKey: WidgetPlannerPreferenceStore.customBackgroundImageDataKey) == data)
    }

    @Test("widget text color preference stores normalized hex and can reset")
    func widgetTextColorPreferenceStoresNormalizedHexAndCanReset() throws {
        let suiteName = "MeowPlannerWidgetTextColorTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        #expect(WidgetPlannerPreferenceStore.widgetTextColorHex(platform: .iOS, defaults: defaults) == nil)
        #expect(WidgetPlannerPreferenceStore.widgetTextColorHexKey(for: .iOS) != WidgetPlannerPreferenceStore.widgetTextColorHexKey(for: .macOS))

        WidgetPlannerPreferenceStore.setWidgetTextColorHex("  ffeedd ", platform: .iOS, defaults: defaults)

        #expect(WidgetPlannerPreferenceStore.widgetTextColorHex(platform: .iOS, defaults: defaults) == "#FFEEDD")
        #expect(defaults.string(forKey: WidgetPlannerPreferenceStore.widgetTextColorHexKey(for: .iOS)) == "#FFEEDD")
        #expect(WidgetPlannerPreferenceStore.widgetTextColorHex(platform: .macOS, defaults: defaults) == nil)

        WidgetPlannerPreferenceStore.setWidgetTextColorHex("not-a-color", platform: .iOS, defaults: defaults)

        #expect(WidgetPlannerPreferenceStore.widgetTextColorHex(platform: .iOS, defaults: defaults) == nil)

        WidgetPlannerPreferenceStore.setWidgetTextColorHex("#123ABC", platform: .iOS, defaults: defaults)
        WidgetPlannerPreferenceStore.clearWidgetTextColorHex(platform: .iOS, defaults: defaults)

        #expect(WidgetPlannerPreferenceStore.widgetTextColorHex(platform: .iOS, defaults: defaults) == nil)
    }

    @Test("custom background save tolerates unwritable mirror paths")
    func customBackgroundSaveToleratesUnwritableMirrorPaths() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetCustomMirrorFailure-\(UUID().uuidString)")
        let primaryFileURL = temporaryDirectory
            .appendingPathComponent(WidgetPlannerPreferenceStore.customBackgroundImageFilename)
        let blockedMirrorDirectory = temporaryDirectory
            .appendingPathComponent("blocked-mirror")
        let blockedMirrorFileURL = blockedMirrorDirectory
            .appendingPathComponent(WidgetPlannerPreferenceStore.customBackgroundImageFilename)
        defer {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        try FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )
        try Data([0x62, 0x6c, 0x6f, 0x63, 0x6b]).write(to: blockedMirrorDirectory)

        let data = Data([0x4d, 0x65, 0x6f, 0x77])
        try WidgetPlannerPreferenceStore.saveCustomBackgroundImageData(
            data,
            fileURLs: [primaryFileURL, blockedMirrorFileURL]
        )

        #expect(try Data(contentsOf: primaryFileURL) == data)
        #expect(!FileManager.default.fileExists(atPath: blockedMirrorFileURL.path))
    }

    @Test("custom background save requires writable primary path")
    func customBackgroundSaveRequiresWritablePrimaryPath() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetCustomPrimaryFailure-\(UUID().uuidString)")
        let blockedPrimaryDirectory = temporaryDirectory
            .appendingPathComponent("blocked-primary")
        let blockedPrimaryFileURL = blockedPrimaryDirectory
            .appendingPathComponent(WidgetPlannerPreferenceStore.customBackgroundImageFilename)
        let writableMirrorFileURL = temporaryDirectory
            .appendingPathComponent("widget-custom-background-mirror.image")
        defer {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        try FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )
        try Data([0x62, 0x6c, 0x6f, 0x63, 0x6b]).write(to: blockedPrimaryDirectory)

        var didThrow = false
        do {
            try WidgetPlannerPreferenceStore.saveCustomBackgroundImageData(
                Data([0x4d, 0x65, 0x6f, 0x77]),
                fileURLs: [blockedPrimaryFileURL, writableMirrorFileURL]
            )
        } catch {
            didThrow = true
        }

        #expect(didThrow)
        #expect(!FileManager.default.fileExists(atPath: writableMirrorFileURL.path))
    }

    @Test("custom background image candidates include widget sandbox mirror")
    func customBackgroundImageCandidatesIncludeWidgetSandboxMirror() throws {
        let appGroupContainerURL = URL(fileURLWithPath: "/Shared/AppGroup")
        let sandboxHome = URL(fileURLWithPath: "/Users/xyue/Library/Containers/com.yuelingqiu.MeowPlanner.MeowPlannerWidget/Data")
        let accountHome = URL(fileURLWithPath: "/Users/xyue")
        let appGroupImageURL = appGroupContainerURL
            .appendingPathComponent(WidgetPlannerPreferenceStore.customBackgroundImageFilename)
        let widgetSandboxMirrorImageURL = URL(
            fileURLWithPath: "/Users/xyue/Library/Containers/com.yuelingqiu.MeowPlanner.MeowPlannerWidget/Data/Library/Group Containers/group.com.yuelingqiu.MeowPlanner/widget-custom-background.image"
        )
        let accountGroupImageURL = URL(
            fileURLWithPath: "/Users/xyue/Library/Group Containers/group.com.yuelingqiu.MeowPlanner/widget-custom-background.image"
        )

        let urls = WidgetPlannerPreferenceStore.customBackgroundImageURLs(
            platform: .iOS,
            appGroupContainerURL: appGroupContainerURL,
            homeDirectory: sandboxHome,
            accountHomeDirectory: accountHome
        )

        #expect(urls.contains(appGroupImageURL))
        #expect(urls.contains(widgetSandboxMirrorImageURL))
        #expect(urls.contains(accountGroupImageURL))
    }

    @Test("iOS app background file candidates stay in shared app group paths")
    func iOSAppBackgroundFileCandidatesStayInSharedAppGroupPaths() throws {
        let appGroupContainerURL = URL(fileURLWithPath: "/Shared/AppGroup")
        let appSandboxHome = URL(fileURLWithPath: "/private/var/mobile/Containers/Data/Application/AppUUID")
        let privateGroupDirectory = appSandboxHome
            .appendingPathComponent("Library")
            .appendingPathComponent("Group Containers")
            .appendingPathComponent(WidgetPlannerPreferenceStore.suiteName)
        let appGroupSupportDirectory = appGroupContainerURL
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent("MeowPlannerWidget")

        let styleURLs = WidgetPlannerPreferenceStore.widgetBackgroundStyleFileURLs(
            platform: .iOS,
            appGroupContainerURL: appGroupContainerURL,
            homeDirectory: appSandboxHome,
            accountHomeDirectory: nil
        )
        let customImageURLs = WidgetPlannerPreferenceStore.customBackgroundImageURLs(
            platform: .iOS,
            appGroupContainerURL: appGroupContainerURL,
            homeDirectory: appSandboxHome,
            accountHomeDirectory: nil
        )
        let wallpaperImageURLs = WidgetPlannerPreferenceStore.wallpaperBackgroundImageURLs(
            platform: .iOS,
            appGroupContainerURL: appGroupContainerURL,
            homeDirectory: appSandboxHome,
            accountHomeDirectory: nil
        )

        #expect(styleURLs.contains(appGroupContainerURL.appendingPathComponent(WidgetPlannerPreferenceStore.widgetBackgroundStyleFilename)))
        #expect(styleURLs.contains(appGroupSupportDirectory.appendingPathComponent(WidgetPlannerPreferenceStore.widgetBackgroundStyleFilename)))
        #expect(customImageURLs.contains(appGroupContainerURL.appendingPathComponent(WidgetPlannerPreferenceStore.customBackgroundImageFilename)))
        #expect(customImageURLs.contains(appGroupSupportDirectory.appendingPathComponent(WidgetPlannerPreferenceStore.customBackgroundImageFilename)))
        #expect(wallpaperImageURLs.contains(appGroupContainerURL.appendingPathComponent(WidgetPlannerPreferenceStore.wallpaperBackgroundImageFilename)))
        #expect(wallpaperImageURLs.contains(appGroupSupportDirectory.appendingPathComponent(WidgetPlannerPreferenceStore.wallpaperBackgroundImageFilename)))
        #expect(!styleURLs.contains(privateGroupDirectory.appendingPathComponent(WidgetPlannerPreferenceStore.widgetBackgroundStyleFilename)))
        #expect(!customImageURLs.contains(privateGroupDirectory.appendingPathComponent(WidgetPlannerPreferenceStore.customBackgroundImageFilename)))
        #expect(!wallpaperImageURLs.contains(privateGroupDirectory.appendingPathComponent(WidgetPlannerPreferenceStore.wallpaperBackgroundImageFilename)))
    }

    @Test("iOS wallpaper widget background stores image and adjustment separately from macOS")
    func iosWallpaperWidgetBackgroundStoresImageAndAdjustmentSeparatelyFromMacOS() throws {
        let suiteName = "MeowPlannerWidgetWallpaperBackgroundTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetWallpaperBackground-\(UUID().uuidString).image")
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: fileURL)
        }

        #expect(WidgetBackgroundStyle.wallpaperPhoto.title(language: .chinese) == "壁纸透明")
        #expect(WidgetBackgroundStyle.wallpaperPhoto.title(language: .english) == "Wallpaper")
        #expect(WidgetWallpaperBackgroundPlacement.middle.title(language: .chinese) == "中间")
        #expect(WidgetWallpaperBackgroundPlacement.middle.title(language: .english) == "Middle")

        WidgetPlannerPreferenceStore.setWidgetBackgroundStyle(.wallpaperPhoto, platform: .iOS, defaults: defaults)
        WidgetPlannerPreferenceStore.setWidgetBackgroundStyle(.wallpaperPhoto, platform: .macOS, defaults: defaults)

        #expect(WidgetPlannerPreferenceStore.widgetBackgroundStyle(platform: .iOS, defaults: defaults) == .wallpaperPhoto)
        #expect(WidgetPlannerPreferenceStore.widgetBackgroundStyle(platform: .macOS, defaults: defaults) == .defaultArtwork)

        let adjustment = WidgetWallpaperBackgroundAdjustment(
            placement: .bottom,
            horizontalOffset: 32,
            verticalOffset: -18,
            scale: 1.24
        )
        WidgetPlannerPreferenceStore.setWidgetWallpaperBackgroundAdjustment(adjustment, defaults: defaults)

        #expect(WidgetPlannerPreferenceStore.widgetWallpaperBackgroundAdjustment(defaults: defaults) == adjustment)

        let outOfRangeAdjustment = WidgetWallpaperBackgroundAdjustment(horizontalOffset: 500, verticalOffset: -500, scale: 4)
        WidgetPlannerPreferenceStore.setWidgetWallpaperBackgroundAdjustment(outOfRangeAdjustment, defaults: defaults)

        #expect(
            WidgetPlannerPreferenceStore.widgetWallpaperBackgroundAdjustment(defaults: defaults)
            == WidgetWallpaperBackgroundAdjustment(placement: .middle, horizontalOffset: 160, verticalOffset: -160, scale: 2)
        )

        WidgetPlannerPreferenceStore.resetWidgetWallpaperBackgroundAdjustment(defaults: defaults)

        #expect(WidgetPlannerPreferenceStore.widgetWallpaperBackgroundAdjustment(defaults: defaults) == .defaultValue)

        let screenMetrics = WidgetWallpaperBackgroundScreenMetrics(width: 402, height: 874, scale: 3)
        WidgetPlannerPreferenceStore.setWidgetWallpaperBackgroundScreenMetrics(screenMetrics, defaults: defaults)

        #expect(WidgetPlannerPreferenceStore.widgetWallpaperBackgroundScreenMetrics(defaults: defaults) == screenMetrics)
        #expect(WidgetPlannerPreferenceStore.currentWidgetWallpaperBackgroundRenderVersion > 0)
        #expect(WidgetPlannerPreferenceStore.widgetWallpaperBackgroundRenderRefreshRequired(platform: .iOS, defaults: defaults))
        #expect(!WidgetPlannerPreferenceStore.widgetWallpaperBackgroundRenderRefreshRequired(platform: .macOS, defaults: defaults))

        WidgetPlannerPreferenceStore.markWidgetWallpaperBackgroundRenderVersionCurrent(platform: .macOS, defaults: defaults)

        #expect(WidgetPlannerPreferenceStore.widgetWallpaperBackgroundRenderRefreshRequired(platform: .iOS, defaults: defaults))

        WidgetPlannerPreferenceStore.markWidgetWallpaperBackgroundRenderVersionCurrent(platform: .iOS, defaults: defaults)

        #expect(
            defaults.integer(forKey: WidgetPlannerPreferenceStore.widgetWallpaperBackgroundRenderVersionKey)
            == WidgetPlannerPreferenceStore.currentWidgetWallpaperBackgroundRenderVersion
        )
        #expect(!WidgetPlannerPreferenceStore.widgetWallpaperBackgroundRenderRefreshRequired(platform: .iOS, defaults: defaults))

        defaults.set(
            WidgetPlannerPreferenceStore.currentWidgetWallpaperBackgroundRenderVersion - 1,
            forKey: WidgetPlannerPreferenceStore.widgetWallpaperBackgroundRenderVersionKey
        )

        #expect(WidgetPlannerPreferenceStore.widgetWallpaperBackgroundRenderRefreshRequired(platform: .iOS, defaults: defaults))

        let mediumWidgetSize = WidgetWallpaperBackgroundWidgetSize(width: 329, height: 160)
        #expect(
            WidgetWallpaperBackgroundLayout.mediumWidgetOrigin(
                screenMetrics: screenMetrics,
                widgetSize: mediumWidgetSize,
                adjustment: WidgetWallpaperBackgroundAdjustment(placement: .top)
            )
            == WidgetWallpaperBackgroundOrigin(x: 36.5, y: 92)
        )
        #expect(
            WidgetWallpaperBackgroundLayout.mediumWidgetOrigin(
                screenMetrics: screenMetrics,
                widgetSize: mediumWidgetSize,
                adjustment: WidgetWallpaperBackgroundAdjustment(placement: .middle)
            )
            == WidgetWallpaperBackgroundOrigin(x: 36.5, y: 302.5)
        )
        #expect(
            WidgetWallpaperBackgroundLayout.mediumWidgetOrigin(
                screenMetrics: screenMetrics,
                widgetSize: mediumWidgetSize,
                adjustment: WidgetWallpaperBackgroundAdjustment(placement: .bottom, horizontalOffset: 12, verticalOffset: -8)
            )
            == WidgetWallpaperBackgroundOrigin(x: 48.5, y: 505)
        )

        let data = Data([0x57, 0x61, 0x6c, 0x6c])
        let mirrorFileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetWallpaperBackgroundMirror-\(UUID().uuidString).image")
        defer {
            try? FileManager.default.removeItem(at: mirrorFileURL)
        }

        try WidgetPlannerPreferenceStore.saveWallpaperBackgroundImageData(data, fileURLs: [fileURL, mirrorFileURL])

        #expect(try Data(contentsOf: fileURL) == data)
        #expect(try Data(contentsOf: mirrorFileURL) == data)

        WidgetPlannerPreferenceStore.clearWallpaperBackgroundImage(fileURLs: [fileURL, mirrorFileURL])

        #expect(!FileManager.default.fileExists(atPath: fileURL.path))
        #expect(!FileManager.default.fileExists(atPath: mirrorFileURL.path))

        try data.write(to: fileURL, options: .atomic)

        #expect(WidgetPlannerPreferenceStore.repairWallpaperBackgroundImageMirrors(fileURLs: [fileURL, mirrorFileURL]))

        #expect(try Data(contentsOf: fileURL) == data)
        #expect(try Data(contentsOf: mirrorFileURL) == data)
        #expect(!WidgetPlannerPreferenceStore.repairWallpaperBackgroundImageMirrors(fileURLs: [fileURL, mirrorFileURL]))
    }

    @Test("wallpaper background private mirror repairs shared widget image data")
    func wallpaperBackgroundPrivateMirrorRepairsSharedWidgetImageData() throws {
        let suiteName = "MeowPlannerWidgetWallpaperPrivateMirrorTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetWallpaperPrivateMirror-\(UUID().uuidString)")
        let privateMirrorFileURL = temporaryDirectory
            .appendingPathComponent("AppPrivate")
            .appendingPathComponent(WidgetPlannerPreferenceStore.wallpaperBackgroundImageFilename)
        let widgetReadableFileURL = temporaryDirectory
            .appendingPathComponent("WidgetReadable")
            .appendingPathComponent(WidgetPlannerPreferenceStore.wallpaperBackgroundImageFilename)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        let data = Data([0x57, 0x61, 0x6c, 0x6c, 0x70, 0x61, 0x70, 0x65, 0x72])
        try FileManager.default.createDirectory(
            at: privateMirrorFileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: privateMirrorFileURL, options: .atomic)

        #expect(
            WidgetPlannerPreferenceStore.wallpaperBackgroundImageData(
                platform: .iOS,
                defaults: defaults,
                fileURLs: [widgetReadableFileURL]
            ) == nil
        )

        #expect(
            WidgetPlannerPreferenceStore.repairWallpaperBackgroundImageMirrors(
                defaults: defaults,
                fileURLs: [privateMirrorFileURL, widgetReadableFileURL]
            )
        )
        #expect(defaults.data(forKey: WidgetPlannerPreferenceStore.wallpaperBackgroundImageDataKey) == data)
        #expect(
            WidgetPlannerPreferenceStore.wallpaperBackgroundImageData(
                platform: .iOS,
                defaults: defaults,
                fileURLs: [widgetReadableFileURL]
            ) == data
        )
    }

    @Test("wallpaper background data read repairs missing widget mirror from shared defaults")
    func wallpaperBackgroundDataReadRepairsMissingWidgetMirrorFromSharedDefaults() throws {
        let suiteName = "MeowPlannerWidgetWallpaperSharedMirrorTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetWallpaperSharedMirror-\(UUID().uuidString)")
        let widgetReadableFileURL = temporaryDirectory
            .appendingPathComponent("WidgetReadable")
            .appendingPathComponent(WidgetPlannerPreferenceStore.wallpaperBackgroundImageFilename)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        let data = Data([0x57, 0x61, 0x6c, 0x6c, 0x53, 0x68, 0x61, 0x72, 0x65, 0x64])
        defaults.set(data, forKey: WidgetPlannerPreferenceStore.wallpaperBackgroundImageDataKey)
        defaults.synchronize()

        #expect(!FileManager.default.fileExists(atPath: widgetReadableFileURL.path))
        #expect(
            WidgetPlannerPreferenceStore.wallpaperBackgroundImageData(
                platform: .iOS,
                defaults: defaults,
                fileURLs: [widgetReadableFileURL]
            ) == data
        )
        #expect(try Data(contentsOf: widgetReadableFileURL) == data)
    }

    @Test("wallpaper background save stores shared widget image data")
    func wallpaperBackgroundSaveStoresSharedWidgetImageData() throws {
        let suiteName = "MeowPlannerWidgetWallpaperSharedSaveTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetWallpaperSharedSave-\(UUID().uuidString)")
        let primaryFileURL = temporaryDirectory
            .appendingPathComponent(WidgetPlannerPreferenceStore.wallpaperBackgroundImageFilename)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        let data = Data([0x53, 0x61, 0x76, 0x65, 0x57, 0x61, 0x6c, 0x6c])
        try WidgetPlannerPreferenceStore.saveWallpaperBackgroundImageData(
            data,
            platform: .iOS,
            defaults: defaults,
            fileURLs: [primaryFileURL]
        )

        #expect(try Data(contentsOf: primaryFileURL) == data)
        #expect(defaults.data(forKey: WidgetPlannerPreferenceStore.wallpaperBackgroundImageDataKey) == data)
        #expect(WidgetPlannerPreferenceStore.validateWallpaperBackgroundImageData(platform: .iOS, defaults: defaults))
    }

    @Test("iOS wallpaper background validation repairs shared data from file fallback")
    func iOSWallpaperBackgroundValidationRepairsSharedDataFromFileFallback() throws {
        let suiteName = "MeowPlannerWidgetWallpaperFileValidationTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetWallpaperFileValidation-\(UUID().uuidString)")
        let fileURL = temporaryDirectory
            .appendingPathComponent(WidgetPlannerPreferenceStore.wallpaperBackgroundImageFilename)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        let data = Data([0x57, 0x61, 0x6c, 0x6c])
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)

        #expect(WidgetPlannerPreferenceStore.validateWallpaperBackgroundImageData(
            platform: .iOS,
            defaults: defaults,
            fileURLs: [fileURL]
        ))
        #expect(defaults.data(forKey: WidgetPlannerPreferenceStore.wallpaperBackgroundImageDataKey) == data)
    }

    @Test("widget background style falls back when selected image is unavailable")
    func widgetBackgroundStyleFallsBackWhenSelectedImageIsUnavailable() {
        #expect(
            WidgetBackgroundStyle.wallpaperPhoto.fallbackIfImageUnavailable(
                hasCustomPhotoImage: false,
                hasWallpaperPhotoImage: false
            ) == .defaultArtwork
        )
        #expect(
            WidgetBackgroundStyle.customPhoto.fallbackIfImageUnavailable(
                hasCustomPhotoImage: false,
                hasWallpaperPhotoImage: true
            ) == .defaultArtwork
        )
        #expect(
            WidgetBackgroundStyle.wallpaperPhoto.fallbackIfImageUnavailable(
                hasCustomPhotoImage: false,
                hasWallpaperPhotoImage: true
            ) == .wallpaperPhoto
        )
        #expect(
            WidgetBackgroundStyle.defaultArtwork.fallbackIfImageUnavailable(
                hasCustomPhotoImage: false,
                hasWallpaperPhotoImage: false
            ) == .defaultArtwork
        )
    }

    @Test("iOS widget background style defaults are authoritative over stale mirror files")
    func iOSWidgetBackgroundStyleDefaultsAreAuthoritativeOverStaleMirrorFiles() throws {
        let suiteName = "MeowPlannerWidgetStyleSharedDefaultsTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetStyleSharedDefaults-\(UUID().uuidString)")
        let staleMirrorURL = temporaryDirectory
            .appendingPathComponent(WidgetPlannerPreferenceStore.widgetBackgroundStyleFilename)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        try WidgetBackgroundStyle.customPhoto.rawValue.write(to: staleMirrorURL, atomically: true, encoding: .utf8)
        defaults.set(
            WidgetBackgroundStyle.defaultArtwork.rawValue,
            forKey: WidgetPreferencePlatform.iOS.widgetBackgroundStyleKey
        )

        let restored = WidgetPlannerPreferenceStore.widgetBackgroundStyle(
            platform: .iOS,
            defaults: defaults,
            styleFileURLs: [staleMirrorURL]
        )

        #expect(restored == .defaultArtwork)
        #expect(try String(contentsOf: staleMirrorURL, encoding: .utf8) == WidgetBackgroundStyle.defaultArtwork.rawValue)
    }

    @Test("widget background refresh signature includes shared image data")
    func widgetBackgroundRefreshSignatureIncludesSharedImageData() throws {
        let suiteName = "MeowPlannerWidgetSharedImageSignatureTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        WidgetPlannerPreferenceStore.setWidgetBackgroundStyle(.customPhoto, platform: .iOS, defaults: defaults)
        let missingImageSignature = WidgetPlannerPreferenceStore.widgetBackgroundRefreshSignature(
            platform: .iOS,
            defaults: defaults
        )

        defaults.set(Data([0x43, 0x61, 0x74]), forKey: WidgetPlannerPreferenceStore.customBackgroundImageDataKey)
        let customImageSignature = WidgetPlannerPreferenceStore.widgetBackgroundRefreshSignature(
            platform: .iOS,
            defaults: defaults
        )

        #expect(customImageSignature != missingImageSignature)
        #expect(customImageSignature.contains("custom:shared:sha256:"))

        defaults.set(Data([0x44, 0x6f, 0x67]), forKey: WidgetPlannerPreferenceStore.customBackgroundImageDataKey)
        let sameLengthCustomImageSignature = WidgetPlannerPreferenceStore.widgetBackgroundRefreshSignature(
            platform: .iOS,
            defaults: defaults
        )

        #expect(sameLengthCustomImageSignature != customImageSignature)
        #expect(sameLengthCustomImageSignature.contains("custom:shared:sha256:"))

        defaults.set(7, forKey: WidgetPlannerPreferenceStore.widgetBackgroundRevisionKey)
        let revisedCustomImageSignature = WidgetPlannerPreferenceStore.widgetBackgroundRefreshSignature(
            platform: .iOS,
            defaults: defaults
        )

        #expect(revisedCustomImageSignature != sameLengthCustomImageSignature)
        #expect(revisedCustomImageSignature.contains("revision:7"))

        WidgetPlannerPreferenceStore.bumpWidgetBackgroundRevision(platform: .iOS, defaults: defaults)
        let bumpedRevisionSignature = WidgetPlannerPreferenceStore.widgetBackgroundRefreshSignature(
            platform: .iOS,
            defaults: defaults
        )

        #expect(bumpedRevisionSignature != revisedCustomImageSignature)
        #expect(bumpedRevisionSignature.contains("revision:8"))

        defaults.set(WidgetBackgroundStyle.wallpaperPhoto.rawValue, forKey: WidgetPreferencePlatform.iOS.widgetBackgroundStyleKey)
        defaults.set(Data([0x57, 0x61, 0x6c, 0x6c]), forKey: WidgetPlannerPreferenceStore.wallpaperBackgroundImageDataKey)
        let wallpaperImageSignature = WidgetPlannerPreferenceStore.widgetBackgroundRefreshSignature(
            platform: .iOS,
            defaults: defaults
        )

        #expect(wallpaperImageSignature.contains("wallpaper:shared:sha256:"))

        defaults.set(Data([0x4d, 0x65, 0x6f, 0x77]), forKey: WidgetPlannerPreferenceStore.wallpaperBackgroundImageDataKey)
        let sameLengthWallpaperImageSignature = WidgetPlannerPreferenceStore.widgetBackgroundRefreshSignature(
            platform: .iOS,
            defaults: defaults
        )

        #expect(sameLengthWallpaperImageSignature != wallpaperImageSignature)
    }

    @Test("widget background refresh request gives photo timelines a unique invalidation key")
    func widgetBackgroundRefreshRequestGivesPhotoTimelinesUniqueInvalidationKey() throws {
        let suiteName = "MeowPlannerWidgetRefreshRequestTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        WidgetPlannerPreferenceStore.setWidgetBackgroundStyle(.customPhoto, platform: .iOS, defaults: defaults)
        defaults.set(Data([0x4d, 0x65, 0x6f, 0x77]), forKey: WidgetPlannerPreferenceStore.customBackgroundImageDataKey)

        let initialSignature = WidgetPlannerPreferenceStore.widgetBackgroundRefreshSignature(
            platform: .iOS,
            defaults: defaults
        )

        WidgetPlannerPreferenceStore.requestWidgetBackgroundRefresh(
            platform: .iOS,
            defaults: defaults,
            now: try date("2026-07-02 23:08"),
            requestID: "photo-save"
        )
        let requestedSignature = WidgetPlannerPreferenceStore.widgetBackgroundRefreshSignature(
            platform: .iOS,
            defaults: defaults
        )

        #expect(requestedSignature != initialSignature)
        #expect(requestedSignature.contains("revision:1"))
        #expect(requestedSignature.contains("request:photo-save"))
        #expect(WidgetPlannerPreferenceStore.widgetBackgroundRefreshRequestID(platform: .iOS, defaults: defaults) == "photo-save")

        WidgetPlannerPreferenceStore.requestWidgetBackgroundRefresh(
            platform: .iOS,
            defaults: defaults,
            now: try date("2026-07-02 23:09"),
            requestID: "photo-edit"
        )
        let editedSignature = WidgetPlannerPreferenceStore.widgetBackgroundRefreshSignature(
            platform: .iOS,
            defaults: defaults
        )

        #expect(editedSignature != requestedSignature)
        #expect(editedSignature.contains("revision:2"))
        #expect(editedSignature.contains("request:photo-edit"))
    }

    @Test("wallpaper background save tolerates unwritable mirror paths")
    func wallpaperBackgroundSaveToleratesUnwritableMirrorPaths() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetWallpaperMirrorFailure-\(UUID().uuidString)")
        let primaryFileURL = temporaryDirectory
            .appendingPathComponent("widget-wallpaper-background.image")
        let blockedMirrorDirectory = temporaryDirectory
            .appendingPathComponent("blocked-mirror")
        let blockedMirrorFileURL = blockedMirrorDirectory
            .appendingPathComponent("widget-wallpaper-background.image")
        defer {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        try FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )
        try Data([0x62, 0x6c, 0x6f, 0x63, 0x6b]).write(to: blockedMirrorDirectory)

        let data = Data([0x4d, 0x65, 0x6f, 0x77])
        try WidgetPlannerPreferenceStore.saveWallpaperBackgroundImageData(
            data,
            fileURLs: [primaryFileURL, blockedMirrorFileURL]
        )

        #expect(try Data(contentsOf: primaryFileURL) == data)
        #expect(!FileManager.default.fileExists(atPath: blockedMirrorFileURL.path))
    }

    @Test("wallpaper background save requires writable primary path")
    func wallpaperBackgroundSaveRequiresWritablePrimaryPath() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetWallpaperPrimaryFailure-\(UUID().uuidString)")
        let blockedPrimaryDirectory = temporaryDirectory
            .appendingPathComponent("blocked-primary")
        let blockedPrimaryFileURL = blockedPrimaryDirectory
            .appendingPathComponent("widget-wallpaper-background.image")
        let writableMirrorFileURL = temporaryDirectory
            .appendingPathComponent("widget-wallpaper-background-mirror.image")
        defer {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        try FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )
        try Data([0x62, 0x6c, 0x6f, 0x63, 0x6b]).write(to: blockedPrimaryDirectory)

        var didThrow = false
        do {
            try WidgetPlannerPreferenceStore.saveWallpaperBackgroundImageData(
                Data([0x4d, 0x65, 0x6f, 0x77]),
                fileURLs: [blockedPrimaryFileURL, writableMirrorFileURL]
            )
        } catch {
            didThrow = true
        }

        #expect(didThrow)
        #expect(!FileManager.default.fileExists(atPath: writableMirrorFileURL.path))
    }

    @Test("wallpaper background image candidates include widget sandbox mirror")
    func wallpaperBackgroundImageCandidatesIncludeWidgetSandboxMirror() throws {
        let appGroupContainerURL = URL(fileURLWithPath: "/Shared/AppGroup")
        let sandboxHome = URL(fileURLWithPath: "/Users/xyue/Library/Containers/com.yuelingqiu.MeowPlanner.MeowPlannerWidget/Data")
        let accountHome = URL(fileURLWithPath: "/Users/xyue")
        let appGroupImageURL = appGroupContainerURL
            .appendingPathComponent(WidgetPlannerPreferenceStore.wallpaperBackgroundImageFilename)
        let widgetSandboxMirrorImageURL = URL(
            fileURLWithPath: "/Users/xyue/Library/Containers/com.yuelingqiu.MeowPlanner.MeowPlannerWidget/Data/Library/Group Containers/group.com.yuelingqiu.MeowPlanner/widget-wallpaper-background.image"
        )
        let accountGroupImageURL = URL(
            fileURLWithPath: "/Users/xyue/Library/Group Containers/group.com.yuelingqiu.MeowPlanner/widget-wallpaper-background.image"
        )
        let simulatorAppHome = URL(
            fileURLWithPath: "/Users/xyue/Library/Developer/CoreSimulator/Devices/SimulatorID/data/Containers/Data/Application/AppUUID"
        )
        let simulatorRootGroupImageURL = URL(
            fileURLWithPath: "/Users/xyue/Library/Developer/CoreSimulator/Devices/SimulatorID/data/Library/Group Containers/group.com.yuelingqiu.MeowPlanner/widget-wallpaper-background.image"
        )

        let urls = WidgetPlannerPreferenceStore.wallpaperBackgroundImageURLs(
            platform: .iOS,
            appGroupContainerURL: appGroupContainerURL,
            homeDirectory: sandboxHome,
            accountHomeDirectory: accountHome
        )

        #expect(urls.contains(appGroupImageURL))
        #expect(urls.contains(widgetSandboxMirrorImageURL))
        #expect(urls.contains(accountGroupImageURL))

        let simulatorURLs = WidgetPlannerPreferenceStore.wallpaperBackgroundImageURLs(
            platform: .iOS,
            appGroupContainerURL: appGroupContainerURL,
            homeDirectory: simulatorAppHome,
            accountHomeDirectory: simulatorAppHome
        )

        #expect(simulatorURLs.contains(simulatorRootGroupImageURL))
        #expect(
            WidgetPlannerPreferenceStore.widgetBackgroundStyleFileURLs(
                platform: .iOS,
                appGroupContainerURL: appGroupContainerURL,
                homeDirectory: simulatorAppHome,
                accountHomeDirectory: simulatorAppHome
            )
            .contains(
                simulatorRootGroupImageURL.deletingLastPathComponent()
                    .appendingPathComponent(WidgetPlannerPreferenceStore.widgetBackgroundStyleFilename)
            )
        )
        #expect(
            WidgetPlannerPreferenceStore.wallpaperBackgroundImageURLs(
                platform: .macOS,
                appGroupContainerURL: appGroupContainerURL,
                homeDirectory: sandboxHome,
                accountHomeDirectory: accountHome
            )
            .isEmpty
        )
    }

    @Test("iOS legacy transparent widget background falls back to default artwork")
    func iOSLegacyTransparentWidgetBackgroundFallsBackToDefaultArtwork() throws {
        let suiteName = "MeowPlannerLegacyTransparentWidgetStyleTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let styleFileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetStyle-\(UUID().uuidString).txt")
        let staleStyleMirrorURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetStaleStyleMirror-\(UUID().uuidString).txt")
        let legacyTransparentRawValue = "transparent"
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: styleFileURL)
            try? FileManager.default.removeItem(at: staleStyleMirrorURL)
        }

        defaults.set(legacyTransparentRawValue, forKey: WidgetPreferencePlatform.iOS.widgetBackgroundStyleKey)

        #expect(
            WidgetPlannerPreferenceStore.widgetBackgroundStyle(
                platform: .iOS,
                defaults: defaults,
                styleFileURLs: [styleFileURL, staleStyleMirrorURL]
            ) == .defaultArtwork
        )
        #expect(defaults.string(forKey: WidgetPreferencePlatform.iOS.widgetBackgroundStyleKey) == WidgetBackgroundStyle.defaultArtwork.rawValue)
        #expect(try String(contentsOf: styleFileURL, encoding: .utf8) == WidgetBackgroundStyle.defaultArtwork.rawValue)
        #expect(try String(contentsOf: staleStyleMirrorURL, encoding: .utf8) == WidgetBackgroundStyle.defaultArtwork.rawValue)

        defaults.removeObject(forKey: WidgetPreferencePlatform.iOS.widgetBackgroundStyleKey)
        try legacyTransparentRawValue.write(to: styleFileURL, atomically: true, encoding: .utf8)
        try WidgetBackgroundStyle.defaultArtwork.rawValue.write(to: staleStyleMirrorURL, atomically: true, encoding: .utf8)

        #expect(
            WidgetPlannerPreferenceStore.synchronizeWidgetBackgroundStyleMirrors(
                platform: .iOS,
                defaults: defaults,
                styleFileURLs: [styleFileURL, staleStyleMirrorURL]
            )
        )
        #expect(defaults.string(forKey: WidgetPreferencePlatform.iOS.widgetBackgroundStyleKey) == WidgetBackgroundStyle.defaultArtwork.rawValue)
        #expect(try String(contentsOf: styleFileURL, encoding: .utf8) == WidgetBackgroundStyle.defaultArtwork.rawValue)
        #expect(try String(contentsOf: staleStyleMirrorURL, encoding: .utf8) == WidgetBackgroundStyle.defaultArtwork.rawValue)
    }

    @Test("widget appearance preference overrides system appearance when requested")
    func widgetAppearancePreferenceOverridesSystemAppearanceWhenRequested() throws {
        let suiteName = "MeowPlannerWidgetAppearanceTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        #expect(WidgetPlannerPreferenceStore.widgetAppearancePreference(defaults: defaults) == .system)
        #expect(WidgetPlannerPreferenceStore.isDarkWidgetAppearance(systemIsDark: true, defaults: defaults))
        #expect(!WidgetPlannerPreferenceStore.isDarkWidgetAppearance(systemIsDark: false, defaults: defaults))

        WidgetPlannerPreferenceStore.setWidgetAppearancePreference(.dark, defaults: defaults)

        #expect(WidgetPlannerPreferenceStore.widgetAppearancePreference(defaults: defaults) == .dark)
        #expect(WidgetPlannerPreferenceStore.isDarkWidgetAppearance(systemIsDark: false, defaults: defaults))

        WidgetPlannerPreferenceStore.setWidgetAppearancePreference(.light, defaults: defaults)

        #expect(WidgetPlannerPreferenceStore.widgetAppearancePreference(defaults: defaults) == .light)
        #expect(!WidgetPlannerPreferenceStore.isDarkWidgetAppearance(systemIsDark: true, defaults: defaults))
    }

    @Test("image backed widget backgrounds ignore system appearance")
    func imageBackedWidgetBackgroundsIgnoreSystemAppearance() throws {
        let suiteName = "MeowPlannerWidgetImageBackgroundAppearanceTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        #expect(WidgetPlannerPreferenceStore.isDarkWidgetAppearance(
            systemIsDark: true,
            backgroundStyle: .defaultArtwork,
            platform: .iOS,
            defaults: defaults
        ))
        #expect(!WidgetPlannerPreferenceStore.isDarkWidgetAppearance(
            systemIsDark: true,
            backgroundStyle: .customPhoto,
            platform: .iOS,
            defaults: defaults
        ))
        #expect(!WidgetPlannerPreferenceStore.isDarkWidgetAppearance(
            systemIsDark: true,
            backgroundStyle: .wallpaperPhoto,
            platform: .iOS,
            defaults: defaults
        ))

        WidgetPlannerPreferenceStore.setWidgetAppearancePreference(.dark, platform: .iOS, defaults: defaults)

        #expect(WidgetPlannerPreferenceStore.isDarkWidgetAppearance(
            systemIsDark: false,
            backgroundStyle: .defaultArtwork,
            platform: .iOS,
            defaults: defaults
        ))
        #expect(!WidgetPlannerPreferenceStore.isDarkWidgetAppearance(
            systemIsDark: false,
            backgroundStyle: .customPhoto,
            platform: .iOS,
            defaults: defaults
        ))
        #expect(!WidgetPlannerPreferenceStore.isDarkWidgetAppearance(
            systemIsDark: false,
            backgroundStyle: .wallpaperPhoto,
            platform: .iOS,
            defaults: defaults
        ))
    }

    @Test("widget background refresh signature tracks appearance only for default artwork")
    func widgetBackgroundRefreshSignatureTracksAppearanceOnlyForDefaultArtwork() throws {
        let suiteName = "MeowPlannerWidgetBackgroundAppearanceSignatureTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        WidgetPlannerPreferenceStore.setWidgetBackgroundStyle(.defaultArtwork, platform: .iOS, defaults: defaults)
        WidgetPlannerPreferenceStore.setWidgetAppearancePreference(.light, platform: .iOS, defaults: defaults)
        let lightDefaultSignature = WidgetPlannerPreferenceStore.widgetBackgroundRefreshSignature(
            platform: .iOS,
            defaults: defaults
        )

        WidgetPlannerPreferenceStore.setWidgetAppearancePreference(.dark, platform: .iOS, defaults: defaults)
        let darkDefaultSignature = WidgetPlannerPreferenceStore.widgetBackgroundRefreshSignature(
            platform: .iOS,
            defaults: defaults
        )

        #expect(darkDefaultSignature != lightDefaultSignature)
        #expect(lightDefaultSignature.contains("appearance:light"))
        #expect(darkDefaultSignature.contains("appearance:dark"))

        defaults.set(Data([0x4d, 0x65, 0x6f, 0x77]), forKey: WidgetPlannerPreferenceStore.customBackgroundImageDataKey)
        WidgetPlannerPreferenceStore.setWidgetBackgroundStyle(.customPhoto, platform: .iOS, defaults: defaults)
        let customPhotoDarkSignature = WidgetPlannerPreferenceStore.widgetBackgroundRefreshSignature(
            platform: .iOS,
            defaults: defaults
        )

        WidgetPlannerPreferenceStore.setWidgetAppearancePreference(.light, platform: .iOS, defaults: defaults)
        let customPhotoLightSignature = WidgetPlannerPreferenceStore.widgetBackgroundRefreshSignature(
            platform: .iOS,
            defaults: defaults
        )

        #expect(customPhotoLightSignature == customPhotoDarkSignature)
        #expect(customPhotoLightSignature.contains("style:customPhoto"))
        #expect(customPhotoLightSignature.contains("appearance:image"))
        #expect(customPhotoLightSignature.contains("custom:shared:sha256:"))
    }

    @Test("widget visual preferences stay separate between macOS and iOS")
    func widgetVisualPreferencesStaySeparateBetweenMacOSAndIOS() throws {
        let suiteName = "MeowPlannerWidgetPlatformPreferenceTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        defaults.set(WidgetBackgroundStyle.defaultArtwork.rawValue, forKey: WidgetPlannerPreferenceStore.widgetBackgroundStyleKey)
        defaults.set(AppAppearancePreference.dark.rawValue, forKey: WidgetPlannerPreferenceStore.widgetAppearancePreferenceKey)

        #expect(WidgetPlannerPreferenceStore.widgetBackgroundStyle(platform: .iOS, defaults: defaults) == .defaultArtwork)
        #expect(WidgetPlannerPreferenceStore.widgetAppearancePreference(platform: .iOS, defaults: defaults) == .dark)
        #expect(WidgetPlannerPreferenceStore.widgetBackgroundStyle(platform: .macOS, defaults: defaults) == .defaultArtwork)
        #expect(WidgetPlannerPreferenceStore.widgetAppearancePreference(platform: .macOS, defaults: defaults) == .system)

        WidgetPlannerPreferenceStore.setWidgetBackgroundStyle(.customPhoto, platform: .iOS, defaults: defaults)
        WidgetPlannerPreferenceStore.setWidgetAppearancePreference(.light, platform: .iOS, defaults: defaults)

        #expect(WidgetPlannerPreferenceStore.widgetBackgroundStyle(platform: .iOS, defaults: defaults) == .customPhoto)
        #expect(WidgetPlannerPreferenceStore.widgetAppearancePreference(platform: .iOS, defaults: defaults) == .light)
        #expect(WidgetPlannerPreferenceStore.widgetBackgroundStyle(platform: .macOS, defaults: defaults) == .defaultArtwork)
        #expect(WidgetPlannerPreferenceStore.widgetAppearancePreference(platform: .macOS, defaults: defaults) == .system)

        WidgetPlannerPreferenceStore.setWidgetBackgroundStyle(.defaultArtwork, platform: .macOS, defaults: defaults)
        WidgetPlannerPreferenceStore.setWidgetAppearancePreference(.dark, platform: .macOS, defaults: defaults)

        #expect(WidgetPlannerPreferenceStore.widgetBackgroundStyle(platform: .iOS, defaults: defaults) == .customPhoto)
        #expect(WidgetPlannerPreferenceStore.widgetAppearancePreference(platform: .iOS, defaults: defaults) == .light)
        #expect(WidgetPlannerPreferenceStore.widgetBackgroundStyle(platform: .macOS, defaults: defaults) == .defaultArtwork)
        #expect(WidgetPlannerPreferenceStore.widgetAppearancePreference(platform: .macOS, defaults: defaults) == .dark)
    }

    @Test("widget background preference falls back to mirrored style file")
    func widgetBackgroundPreferenceFallsBackToMirroredStyleFile() throws {
        let suiteName = "MeowPlannerWidgetBackgroundFallbackTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let styleFileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetBackgroundStyle-\(UUID().uuidString).txt")
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: styleFileURL)
        }

        #expect(WidgetPlannerPreferenceStore.widgetBackgroundStyle(defaults: defaults, styleFileURLs: [styleFileURL]) == .defaultArtwork)

        try "defaultArtwork".write(to: styleFileURL, atomically: true, encoding: .utf8)

        #expect(WidgetPlannerPreferenceStore.widgetBackgroundStyle(defaults: defaults, styleFileURLs: [styleFileURL]) == .defaultArtwork)

        WidgetPlannerPreferenceStore.setWidgetBackgroundStyle(.customPhoto, defaults: defaults, styleFileURLs: [styleFileURL])

        #expect(WidgetPlannerPreferenceStore.widgetBackgroundStyle(defaults: defaults, styleFileURLs: [styleFileURL]) == .customPhoto)
        #expect(try String(contentsOf: styleFileURL, encoding: .utf8) == "customPhoto")

        try? FileManager.default.removeItem(at: styleFileURL)
        defaults.set(WidgetBackgroundStyle.defaultArtwork.rawValue, forKey: WidgetPreferencePlatform.macOS.widgetBackgroundStyleKey)

        #expect(WidgetPlannerPreferenceStore.widgetBackgroundStyle(defaults: defaults, styleFileURLs: [styleFileURL]) == .defaultArtwork)
        #expect(try String(contentsOf: styleFileURL, encoding: .utf8) == "defaultArtwork")
    }

    @Test("iOS widget background style keeps explicit shared defaults over stale mirror files")
    func iOSWidgetBackgroundStyleKeepsExplicitSharedDefaultsOverStaleMirrorFiles() throws {
        let suiteName = "MeowPlannerWidgetStaleDefaultsBackgroundTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let styleFileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetStaleDefaultsStyle-\(UUID().uuidString).txt")
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: styleFileURL)
        }

        defaults.set(WidgetBackgroundStyle.defaultArtwork.rawValue, forKey: WidgetPreferencePlatform.iOS.widgetBackgroundStyleKey)
        try WidgetBackgroundStyle.wallpaperPhoto.rawValue.write(to: styleFileURL, atomically: true, encoding: .utf8)

        #expect(
            WidgetPlannerPreferenceStore.widgetBackgroundStyle(
                platform: .iOS,
                defaults: defaults,
                styleFileURLs: [styleFileURL]
            ) == .defaultArtwork
        )
        #expect(defaults.string(forKey: WidgetPreferencePlatform.iOS.widgetBackgroundStyleKey) == WidgetBackgroundStyle.defaultArtwork.rawValue)
        #expect(try String(contentsOf: styleFileURL, encoding: .utf8) == WidgetBackgroundStyle.defaultArtwork.rawValue)
    }

    @Test("iOS wallpaper fallback metrics and render version cover iPhone 16")
    func iOSWallpaperFallbackMetricsAndRenderVersionCoverIPhone16() throws {
        let suiteName = "MeowPlannerWidgetIPhone16WallpaperTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let iPhone16Metrics = WidgetWallpaperBackgroundScreenMetrics(width: 393, height: 852, scale: 3)

        #expect(WidgetWallpaperBackgroundScreenMetrics.defaultValue == iPhone16Metrics)

        WidgetPlannerPreferenceStore.setWidgetBackgroundStyle(.wallpaperPhoto, platform: .iOS, defaults: defaults)
        WidgetPlannerPreferenceStore.setWidgetWallpaperBackgroundScreenMetrics(iPhone16Metrics, defaults: defaults)
        let signature = WidgetPlannerPreferenceStore.widgetBackgroundRefreshSignature(
            platform: .iOS,
            defaults: defaults
        )

        #expect(signature.contains("style:wallpaperPhoto"))
        #expect(signature.contains("screen:393.0x852.0@3.0"))
        #expect(WidgetPlannerPreferenceStore.currentWidgetWallpaperBackgroundRenderVersion == 6)

        defaults.set(5, forKey: WidgetPlannerPreferenceStore.widgetWallpaperBackgroundRenderVersionKey)
        #expect(WidgetPlannerPreferenceStore.widgetWallpaperBackgroundRenderRefreshRequired(platform: .iOS, defaults: defaults))
    }

    @Test("macOS widget background does not use transparent style")
    func macOSWidgetBackgroundDoesNotUseTransparentStyle() throws {
        let suiteName = "MeowPlannerWidgetMacOSSolidBackgroundTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let styleFileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerMacOSWidgetBackgroundStyle-\(UUID().uuidString).txt")
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: styleFileURL)
        }

        #expect(WidgetPreferencePlatform.macOS.defaultWidgetBackgroundStyle == .defaultArtwork)
        #expect(WidgetPlannerPreferenceStore.widgetBackgroundStyle(platform: .macOS, defaults: defaults) == .defaultArtwork)

        defaults.set("transparent", forKey: WidgetPreferencePlatform.macOS.widgetBackgroundStyleKey)

        #expect(WidgetPlannerPreferenceStore.widgetBackgroundStyle(platform: .macOS, defaults: defaults) == .defaultArtwork)

        defaults.removeObject(forKey: WidgetPreferencePlatform.macOS.widgetBackgroundStyleKey)
        try "transparent".write(to: styleFileURL, atomically: true, encoding: .utf8)

        #expect(
            WidgetPlannerPreferenceStore.widgetBackgroundStyle(
                platform: .macOS,
                defaults: defaults,
                styleFileURLs: [styleFileURL]
            ) == .defaultArtwork
        )

        WidgetPlannerPreferenceStore.setWidgetBackgroundStyle(.wallpaperPhoto, platform: .iOS, defaults: defaults)

        #expect(WidgetPlannerPreferenceStore.widgetBackgroundStyle(platform: .iOS, defaults: defaults) == .wallpaperPhoto)
        #expect(WidgetPlannerPreferenceStore.widgetBackgroundStyle(platform: .macOS, defaults: defaults) == .defaultArtwork)
    }

    @Test("snapshot decodes older payloads with completed schedule display defaults")
    func snapshotDecodesOlderPayloadsWithCompletedScheduleDisplayDefaults() throws {
        let legacyPayload = """
        {
          "events": [],
          "todos": [],
          "habitCount": 0,
          "weekStartPreference": 1,
          "showChineseCalendar": true,
          "updatedAt": 0
        }
        """.data(using: .utf8)!

        let restored = try JSONDecoder().decode(WidgetPlannerSnapshot.self, from: legacyPayload)

        #expect(restored.showCompletedSchedules)
        #expect(restored.completedSchedulesUseStrikethrough)
    }

    @Test("weekly schedule planner uses next seven days and filters completed schedules")
    func weeklySchedulePlannerUsesNextSevenDaysAndFiltersCompletedSchedules() throws {
        let visibleEvent = PlannerEvent(
            title: "Studio review",
            startDate: try date("2026-06-16 09:00"),
            endDate: try date("2026-06-16 10:00")
        )
        let completedEvent = PlannerEvent(
            title: "Completed meeting",
            startDate: try date("2026-06-17 11:00"),
            isCompleted: true,
            completedAt: try date("2026-06-17 12:00")
        )
        let outsideEvent = PlannerEvent(
            title: "Outside range",
            startDate: try date("2026-06-23 09:00")
        )

        let days = WidgetWeeklySchedulePlanner.days(
            anchorDate: try date("2026-06-16 08:00"),
            displayRule: WidgetScheduleDisplayRule.nextSevenDays,
            events: [visibleEvent, completedEvent, outsideEvent].map(WidgetPlannerSnapshot.Event.init(event:)),
            weekStartPreference: WeekStartPreference.monday,
            showCompletedSchedules: false,
            calendar: calendar
        )
        let expectedStart = try date("2026-06-16 00:00")

        #expect(days.map { calendar.startOfDay(for: $0.date) } == (0..<7).map {
            calendar.date(byAdding: .day, value: $0, to: expectedStart)!
        })
        #expect(days.flatMap(\.events).map(\.title) == ["Studio review"])
    }

    @Test("weekly schedule planner uses configured week start for natural week")
    func weeklySchedulePlannerUsesConfiguredWeekStartForNaturalWeek() throws {
        let sundayEvent = PlannerEvent(
            title: "Sunday planning",
            startDate: try date("2026-06-14 10:00")
        )
        let mondayEvent = PlannerEvent(
            title: "Monday class",
            startDate: try date("2026-06-15 10:00")
        )

        let days = WidgetWeeklySchedulePlanner.days(
            anchorDate: try date("2026-06-18 12:00"),
            displayRule: WidgetScheduleDisplayRule.calendarWeek,
            events: [sundayEvent, mondayEvent].map(WidgetPlannerSnapshot.Event.init(event:)),
            weekStartPreference: WeekStartPreference.monday,
            showCompletedSchedules: true,
            calendar: calendar
        )
        let expectedWeekStart = try date("2026-06-15 00:00")
        let expectedWeekEnd = try date("2026-06-21 00:00")

        #expect(calendar.startOfDay(for: days[0].date) == expectedWeekStart)
        #expect(calendar.startOfDay(for: days[6].date) == expectedWeekEnd)
        #expect(days.flatMap(\.events).map(\.title) == ["Monday class"])
    }

    @Test("weekly schedule planner applies week offset to both display rules")
    func weeklySchedulePlannerAppliesWeekOffsetToBothDisplayRules() throws {
        let nextWeekEvent = PlannerEvent(
            title: "Next week review",
            startDate: try date("2026-06-23 09:00")
        )
        let previousNaturalWeekEvent = PlannerEvent(
            title: "Previous week planning",
            startDate: try date("2026-06-09 10:00")
        )

        let shiftedNextSevenDays = WidgetWeeklySchedulePlanner.days(
            anchorDate: try date("2026-06-16 08:00"),
            displayRule: WidgetScheduleDisplayRule.nextSevenDays,
            events: [nextWeekEvent].map(WidgetPlannerSnapshot.Event.init(event:)),
            weekStartPreference: WeekStartPreference.monday,
            showCompletedSchedules: true,
            weekOffset: 1,
            calendar: calendar
        )
        let shiftedNaturalWeek = WidgetWeeklySchedulePlanner.days(
            anchorDate: try date("2026-06-18 12:00"),
            displayRule: WidgetScheduleDisplayRule.calendarWeek,
            events: [previousNaturalWeekEvent].map(WidgetPlannerSnapshot.Event.init(event:)),
            weekStartPreference: WeekStartPreference.monday,
            showCompletedSchedules: true,
            weekOffset: -1,
            calendar: calendar
        )
        let expectedNextSevenDaysStart = try date("2026-06-23 00:00")
        let expectedNaturalWeekStart = try date("2026-06-08 00:00")

        #expect(calendar.startOfDay(for: shiftedNextSevenDays[0].date) == expectedNextSevenDaysStart)
        #expect(shiftedNextSevenDays.flatMap(\.events).map(\.title) == ["Next week review"])
        #expect(calendar.startOfDay(for: shiftedNaturalWeek[0].date) == expectedNaturalWeekStart)
        #expect(shiftedNaturalWeek.flatMap(\.events).map(\.title) == ["Previous week planning"])
    }

    @Test("snapshot store round trips through user defaults")
    func snapshotStoreRoundTripsThroughUserDefaults() throws {
        let suiteName = "MeowPlannerWidgetSnapshotTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        let snapshot = WidgetPlannerSnapshot(
            events: [PlannerEvent(title: "Dentist", startDate: try date("2026-06-04 14:00"))],
            todos: [TodoItem(title: "Pack bag", dueDate: try date("2026-06-04 20:00"))],
            habitCount: 1,
            weekStartPreference: .sunday,
            showChineseCalendar: false,
            updatedAt: try date("2026-06-02 13:00")
        )

        WidgetPlannerSnapshotStore.save(snapshot, defaults: defaults)
        let restored = try #require(WidgetPlannerSnapshotStore.load(defaults: defaults))

        #expect(restored.plannerEvents.first?.title == "Dentist")
        #expect(restored.todoItems.first?.title == "Pack bag")
        #expect(restored.habitCount == 1)
        #expect(restored.weekStartPreference == .sunday)
        #expect(restored.showChineseCalendar == false)
    }

    @Test("snapshot store treats shared defaults as authority over widget mirror files")
    func snapshotStoreTreatsSharedDefaultsAsAuthorityOverWidgetMirrorFiles() throws {
        let suiteName = "MeowPlannerWidgetSnapshotFileTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetSnapshot-\(UUID().uuidString).json")
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: fileURL)
        }
        let defaultsSnapshot = WidgetPlannerSnapshot(
            events: [PlannerEvent(title: "Old defaults event", startDate: try date("2026-06-02 10:00"))],
            todos: [],
            habitCount: 0,
            weekStartPreference: .sunday,
            showChineseCalendar: true,
            updatedAt: try date("2026-06-02 13:00")
        )
        let fileSnapshot = WidgetPlannerSnapshot(
            events: [PlannerEvent(title: "Fresh file event", startDate: try date("2026-06-03 20:00"))],
            todos: [TodoItem(title: "Fresh file todo", dueDate: try date("2026-06-03 21:00"))],
            habitCount: 2,
            weekStartPreference: .monday,
            showChineseCalendar: false,
            updatedAt: try date("2026-06-03 13:00")
        )

        WidgetPlannerSnapshotStore.save(defaultsSnapshot, defaults: defaults)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try JSONEncoder().encode(fileSnapshot).write(to: fileURL, options: .atomic)
        let restored = try #require(WidgetPlannerSnapshotStore.load(
            defaults: defaults,
            fileURLs: [fileURL],
            sharedDefaultsAuthority: true
        ))

        #expect(restored.plannerEvents.first?.title == "Old defaults event")
        #expect(restored.todoItems.isEmpty)
        #expect(restored.habitCount == 0)
        #expect(restored.weekStartPreference == .sunday)
        #expect(restored.showChineseCalendar)
    }

    @Test("snapshot load repairs shared defaults from authoritative file fallback")
    func snapshotLoadRepairsSharedDefaultsFromAuthoritativeFileFallback() throws {
        let suiteName = "MeowPlannerWidgetSnapshotFileRepairTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetSnapshotFileRepair-\(UUID().uuidString).json")
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: fileURL)
        }
        let fileSnapshot = WidgetPlannerSnapshot(
            events: [PlannerEvent(title: "Recovered file event", startDate: try date("2026-06-03 20:00"))],
            todos: [TodoItem(title: "Recovered file todo", dueDate: try date("2026-06-03 21:00"))],
            habitCount: 2,
            weekStartPreference: .monday,
            showChineseCalendar: false,
            updatedAt: try date("2026-06-03 13:00")
        )

        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try JSONEncoder().encode(fileSnapshot).write(to: fileURL, options: .atomic)

        let restored = try #require(WidgetPlannerSnapshotStore.load(
            defaults: defaults,
            fileURLs: [fileURL],
            sharedDefaultsAuthority: true
        ))
        let repairedData = try #require(defaults.data(forKey: WidgetPlannerSnapshotStore.snapshotKey))
        let repairedSnapshot = try JSONDecoder().decode(WidgetPlannerSnapshot.self, from: repairedData)

        #expect(restored.plannerEvents.first?.title == "Recovered file event")
        #expect(repairedSnapshot.plannerEvents.first?.title == "Recovered file event")
        #expect(repairedSnapshot.todoItems.first?.title == "Recovered file todo")
    }

    @Test("snapshot store can keep newest file behavior when shared defaults are not authoritative")
    func snapshotStoreCanKeepNewestFileBehaviorWhenSharedDefaultsAreNotAuthoritative() throws {
        let suiteName = "MeowPlannerWidgetSnapshotFileFreshnessTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetSnapshotFreshFile-\(UUID().uuidString).json")
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: fileURL)
        }
        let defaultsSnapshot = WidgetPlannerSnapshot(
            events: [PlannerEvent(title: "Old defaults event", startDate: try date("2026-06-02 10:00"))],
            todos: [],
            habitCount: 0,
            weekStartPreference: .sunday,
            showChineseCalendar: true,
            updatedAt: try date("2026-06-02 13:00")
        )
        let fileSnapshot = WidgetPlannerSnapshot(
            events: [PlannerEvent(title: "Fresh file event", startDate: try date("2026-06-03 20:00"))],
            todos: [TodoItem(title: "Fresh file todo", dueDate: try date("2026-06-03 21:00"))],
            habitCount: 2,
            weekStartPreference: .monday,
            showChineseCalendar: false,
            updatedAt: try date("2026-06-03 13:00")
        )

        WidgetPlannerSnapshotStore.save(defaultsSnapshot, defaults: defaults)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try JSONEncoder().encode(fileSnapshot).write(to: fileURL, options: .atomic)
        let restored = try #require(WidgetPlannerSnapshotStore.load(
            defaults: defaults,
            fileURLs: [fileURL],
            sharedDefaultsAuthority: false
        ))

        #expect(restored.plannerEvents.first?.title == "Fresh file event")
        #expect(restored.todoItems.first?.title == "Fresh file todo")
        #expect(restored.habitCount == 2)
        #expect(restored.weekStartPreference == .monday)
        #expect(!restored.showChineseCalendar)
    }

    @Test("snapshot store can be cleared on sign out")
    func snapshotStoreCanBeClearedOnSignOut() throws {
        let suiteName = "MeowPlannerWidgetSnapshotClearTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetSnapshotClear-\(UUID().uuidString).json")
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: fileURL)
        }
        let snapshot = WidgetPlannerSnapshot(
            events: [PlannerEvent(title: "Private account event", startDate: try date("2026-06-05 09:00"))],
            todos: [TodoItem(title: "Private account todo", dueDate: try date("2026-06-05 10:00"))],
            habitCount: 1,
            weekStartPreference: .monday,
            showChineseCalendar: true,
            updatedAt: try date("2026-06-05 08:00")
        )

        WidgetPlannerSnapshotStore.save(snapshot, defaults: defaults, fileURL: fileURL)
        #expect(WidgetPlannerSnapshotStore.load(defaults: defaults, fileURL: fileURL) != nil)

        WidgetPlannerSnapshotStore.clear(defaults: defaults, fileURLs: [fileURL])

        #expect(WidgetPlannerSnapshotStore.load(defaults: defaults, fileURL: fileURL) == nil)
        #expect(!FileManager.default.fileExists(atPath: fileURL.path))
    }

    @Test("snapshot store searches multiple app group file candidates")
    func snapshotStoreSearchesMultipleAppGroupFileCandidates() throws {
        let suiteName = "MeowPlannerWidgetSnapshotCandidateTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let missingFileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("missing-\(UUID().uuidString).json")
        let fallbackFileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("fallback-\(UUID().uuidString).json")
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: fallbackFileURL)
        }
        let snapshot = WidgetPlannerSnapshot(
            events: [PlannerEvent(title: "Candidate file event", startDate: try date("2026-06-03 20:00"))],
            todos: [],
            habitCount: 0,
            weekStartPreference: .sunday,
            showChineseCalendar: true,
            updatedAt: try date("2026-06-03 13:00")
        )

        WidgetPlannerSnapshotStore.save(snapshot, defaults: defaults, fileURL: fallbackFileURL)
        let restored = try #require(
            WidgetPlannerSnapshotStore.load(defaults: defaults, fileURLs: [missingFileURL, fallbackFileURL])
        )

        #expect(restored.plannerEvents.first?.title == "Candidate file event")
    }

    @Test("snapshot refresh mirrors newest snapshot into every widget file candidate")
    func snapshotRefreshMirrorsNewestSnapshotIntoEveryWidgetFileCandidate() throws {
        let suiteName = "MeowPlannerWidgetSnapshotRefreshTests-\(UUID().uuidString)"
        let standardSuiteName = "MeowPlannerWidgetSnapshotStandardRefreshTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let standardDefaults = try #require(UserDefaults(suiteName: standardSuiteName))
        let temporaryRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetSnapshotRefresh-\(UUID().uuidString)")
        let staleMirrorURL = temporaryRoot
            .appendingPathComponent("WidgetSandbox")
            .appendingPathComponent(WidgetPlannerSnapshotStore.snapshotFilename)
        let freshSharedURL = temporaryRoot
            .appendingPathComponent("SharedAppGroup")
            .appendingPathComponent(WidgetPlannerSnapshotStore.snapshotFilename)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            standardDefaults.removePersistentDomain(forName: standardSuiteName)
            try? FileManager.default.removeItem(at: temporaryRoot)
        }
        let staleSnapshot = WidgetPlannerSnapshot(
            events: [PlannerEvent(title: "Old mirrored event", startDate: try date("2026-06-03 09:00"))],
            todos: [],
            habitCount: 0,
            weekStartPreference: .sunday,
            showChineseCalendar: true,
            updatedAt: try date("2026-06-03 13:00")
        )
        let freshSnapshot = WidgetPlannerSnapshot(
            events: [PlannerEvent(title: "Fresh mirrored event", startDate: try date("2026-06-14 09:00"))],
            todos: [],
            habitCount: 0,
            weekStartPreference: .monday,
            showChineseCalendar: true,
            updatedAt: try date("2026-06-14 13:00")
        )

        WidgetPlannerSnapshotStore.save(staleSnapshot, defaults: defaults, fileURL: staleMirrorURL)
        WidgetPlannerSnapshotStore.save(freshSnapshot, defaults: defaults, fileURL: freshSharedURL)

        let refreshed = try #require(WidgetPlannerSnapshotStore.refreshSharedSnapshotForWidgetExtension(
            defaults: defaults,
            standardDefaults: standardDefaults,
            fileURLs: [staleMirrorURL, freshSharedURL]
        ))
        let mirrored = try #require(WidgetPlannerSnapshotStore.load(defaults: defaults, fileURL: staleMirrorURL))
        let standardSnapshot = try #require(WidgetPlannerSnapshotStore.load(defaults: standardDefaults))

        #expect(refreshed.plannerEvents.first?.title == "Fresh mirrored event")
        #expect(mirrored.plannerEvents.first?.title == "Fresh mirrored event")
        #expect(standardSnapshot.plannerEvents.first?.title == "Fresh mirrored event")
    }

    @Test("snapshot refresh mirrors shared defaults over stale widget sandbox files")
    func snapshotRefreshMirrorsSharedDefaultsOverStaleWidgetSandboxFiles() throws {
        let suiteName = "MeowPlannerWidgetSnapshotSharedDefaultsRefreshTests-\(UUID().uuidString)"
        let standardSuiteName = "MeowPlannerWidgetSnapshotSharedDefaultsStandardTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let standardDefaults = try #require(UserDefaults(suiteName: standardSuiteName))
        let temporaryRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetSnapshotSharedDefaultsRefresh-\(UUID().uuidString)")
        let staleWidgetSandboxURL = temporaryRoot
            .appendingPathComponent("WidgetSandbox")
            .appendingPathComponent(WidgetPlannerSnapshotStore.snapshotFilename)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            standardDefaults.removePersistentDomain(forName: standardSuiteName)
            try? FileManager.default.removeItem(at: temporaryRoot)
        }
        let sharedSnapshot = WidgetPlannerSnapshot(
            events: [PlannerEvent(title: "Fresh shared defaults event", startDate: try date("2026-06-14 09:00"))],
            todos: [],
            habitCount: 0,
            weekStartPreference: .monday,
            showChineseCalendar: true,
            updatedAt: try date("2026-06-14 13:00")
        )
        let staleWidgetSandboxSnapshot = WidgetPlannerSnapshot(
            events: [PlannerEvent(title: "Stale widget sandbox event", startDate: try date("2026-06-15 09:00"))],
            todos: [],
            habitCount: 0,
            weekStartPreference: .sunday,
            showChineseCalendar: false,
            updatedAt: try date("2026-06-15 13:00")
        )

        WidgetPlannerSnapshotStore.save(sharedSnapshot, defaults: defaults)
        try FileManager.default.createDirectory(
            at: staleWidgetSandboxURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try JSONEncoder().encode(staleWidgetSandboxSnapshot).write(to: staleWidgetSandboxURL, options: .atomic)

        let refreshed = try #require(WidgetPlannerSnapshotStore.refreshSharedSnapshotForWidgetExtension(
            defaults: defaults,
            standardDefaults: standardDefaults,
            fileURLs: [staleWidgetSandboxURL],
            sharedDefaultsAuthority: true
        ))
        let mirrored = try #require(WidgetPlannerSnapshotStore.load(defaults: defaults, fileURL: staleWidgetSandboxURL))
        let standardSnapshot = try #require(WidgetPlannerSnapshotStore.load(defaults: standardDefaults))

        #expect(refreshed.plannerEvents.first?.title == "Fresh shared defaults event")
        #expect(mirrored.plannerEvents.first?.title == "Fresh shared defaults event")
        #expect(standardSnapshot.plannerEvents.first?.title == "Fresh shared defaults event")
    }

    @Test("snapshot loading chooses newest snapshot when widget sandbox mirror is stale")
    func snapshotLoadingChoosesNewestSnapshotWhenWidgetSandboxMirrorIsStale() throws {
        let suiteName = "MeowPlannerWidgetSnapshotStaleSandboxTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let temporaryRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetSnapshotStaleSandbox-\(UUID().uuidString)")
        let accountHome = temporaryRoot.appendingPathComponent("AccountHome")
        let widgetSandboxHome = accountHome
            .appendingPathComponent("Library")
            .appendingPathComponent("Containers")
            .appendingPathComponent("com.yuelingqiu.MeowPlanner.MeowPlannerWidget")
            .appendingPathComponent("Data")
        let sharedSnapshotURL = accountHome
            .appendingPathComponent("Library")
            .appendingPathComponent("Group Containers")
            .appendingPathComponent(WidgetPlannerPreferenceStore.suiteName)
            .appendingPathComponent(WidgetPlannerSnapshotStore.snapshotFilename)
        let staleWidgetSandboxSnapshotURL = widgetSandboxHome
            .appendingPathComponent("Library")
            .appendingPathComponent("Group Containers")
            .appendingPathComponent(WidgetPlannerPreferenceStore.suiteName)
            .appendingPathComponent(WidgetPlannerSnapshotStore.snapshotFilename)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: temporaryRoot)
        }
        let staleSnapshot = WidgetPlannerSnapshot(
            events: [PlannerEvent(title: "Stale widget sandbox event", startDate: try date("2026-06-03 09:00"))],
            todos: [],
            habitCount: 0,
            weekStartPreference: .sunday,
            showChineseCalendar: true,
            updatedAt: try date("2026-06-03 13:00")
        )
        let freshSnapshot = WidgetPlannerSnapshot(
            events: [PlannerEvent(title: "Fresh shared app group event", startDate: try date("2026-06-13 09:00"))],
            todos: [],
            habitCount: 0,
            weekStartPreference: .monday,
            showChineseCalendar: true,
            updatedAt: try date("2026-06-13 13:00")
        )

        WidgetPlannerSnapshotStore.save(staleSnapshot, defaults: defaults, fileURL: staleWidgetSandboxSnapshotURL)
        WidgetPlannerSnapshotStore.save(freshSnapshot, defaults: defaults, fileURL: sharedSnapshotURL)

        let urls = WidgetPlannerSnapshotStore.snapshotFileURLs(
            appGroupContainerURL: nil,
            homeDirectory: widgetSandboxHome,
            accountHomeDirectory: accountHome
        )
        let restored = try #require(WidgetPlannerSnapshotStore.load(defaults: defaults, fileURLs: urls))

        #expect(restored.plannerEvents.first?.title == "Fresh shared app group event")
        #expect(urls.contains(staleWidgetSandboxSnapshotURL))
    }

    @Test("snapshot loading chooses newest snapshot when widget sandbox container is stale")
    func snapshotLoadingChoosesNewestSnapshotWhenWidgetSandboxContainerIsStale() throws {
        let suiteName = "MeowPlannerWidgetSnapshotSandboxContainerURLTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let temporaryRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetSnapshotSandboxContainerURL-\(UUID().uuidString)")
        let accountHome = temporaryRoot.appendingPathComponent("AccountHome")
        let widgetSandboxHome = accountHome
            .appendingPathComponent("Library")
            .appendingPathComponent("Containers")
            .appendingPathComponent("com.yuelingqiu.MeowPlanner.MeowPlannerWidget")
            .appendingPathComponent("Data")
        let widgetSandboxContainerURL = widgetSandboxHome
            .appendingPathComponent("Library")
            .appendingPathComponent("Group Containers")
            .appendingPathComponent(WidgetPlannerPreferenceStore.suiteName)
        let staleWidgetSandboxSnapshotURL = widgetSandboxContainerURL
            .appendingPathComponent(WidgetPlannerSnapshotStore.snapshotFilename)
        let sharedSnapshotURL = accountHome
            .appendingPathComponent("Library")
            .appendingPathComponent("Group Containers")
            .appendingPathComponent(WidgetPlannerPreferenceStore.suiteName)
            .appendingPathComponent(WidgetPlannerSnapshotStore.snapshotFilename)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: temporaryRoot)
        }
        let staleSnapshot = WidgetPlannerSnapshot(
            events: [PlannerEvent(title: "Sandbox container stale event", startDate: try date("2026-06-03 09:00"))],
            todos: [],
            habitCount: 0,
            weekStartPreference: .sunday,
            showChineseCalendar: true,
            updatedAt: try date("2026-06-03 13:00")
        )
        let freshSnapshot = WidgetPlannerSnapshot(
            events: [PlannerEvent(title: "Fresh account app group event", startDate: try date("2026-06-14 09:00"))],
            todos: [],
            habitCount: 0,
            weekStartPreference: .monday,
            showChineseCalendar: true,
            updatedAt: try date("2026-06-14 13:00")
        )

        WidgetPlannerSnapshotStore.save(staleSnapshot, defaults: defaults, fileURL: staleWidgetSandboxSnapshotURL)
        WidgetPlannerSnapshotStore.save(freshSnapshot, defaults: defaults, fileURL: sharedSnapshotURL)

        let urls = WidgetPlannerSnapshotStore.snapshotFileURLs(
            appGroupContainerURL: widgetSandboxContainerURL,
            homeDirectory: widgetSandboxHome,
            accountHomeDirectory: accountHome
        )
        let restored = try #require(WidgetPlannerSnapshotStore.load(defaults: defaults, fileURLs: urls))

        #expect(restored.plannerEvents.first?.title == "Fresh account app group event")
        #expect(urls.contains(sharedSnapshotURL))
        #expect(urls.contains(staleWidgetSandboxSnapshotURL))
    }

    @Test("snapshot file candidates include shared app group and widget sandbox mirror")
    func snapshotFileCandidatesIncludeSharedAppGroupAndWidgetSandboxMirror() throws {
        let sandboxHome = URL(fileURLWithPath: "/Users/xyue/Library/Containers/com.yuelingqiu.MeowPlanner.MeowPlannerWidget/Data")
        let accountHome = URL(fileURLWithPath: "/Users/xyue")
        let widgetSandboxSnapshotURL = URL(fileURLWithPath: "/Users/xyue/Library/Containers/com.yuelingqiu.MeowPlanner.MeowPlannerWidget/Data/Library/Group Containers/group.com.yuelingqiu.MeowPlanner/widget-planner-snapshot.json")
        let accountGroupSnapshotURL = URL(fileURLWithPath: "/Users/xyue/Library/Group Containers/group.com.yuelingqiu.MeowPlanner/widget-planner-snapshot.json")

        let urls = WidgetPlannerSnapshotStore.snapshotFileURLs(
            appGroupContainerURL: nil,
            homeDirectory: sandboxHome,
            accountHomeDirectory: accountHome
        )

        #expect(urls.contains(accountGroupSnapshotURL))
        #expect(urls.contains(widgetSandboxSnapshotURL))
    }

    @Test("snapshot file candidates include widget sandbox mirror when app home differs")
    func snapshotFileCandidatesIncludeWidgetSandboxMirrorWhenAppHomeDiffers() throws {
        let appHome = URL(fileURLWithPath: "/Users/xyue/Library/Containers/com.yuelingqiu.MeowPlanner/Data")
        let accountHome = URL(fileURLWithPath: "/Users/xyue")
        let widgetSandboxSnapshotURL = URL(fileURLWithPath: "/Users/xyue/Library/Containers/com.yuelingqiu.MeowPlanner.MeowPlannerWidget/Data/Library/Group Containers/group.com.yuelingqiu.MeowPlanner/widget-planner-snapshot.json")

        let urls = WidgetPlannerSnapshotStore.snapshotFileURLs(
            appGroupContainerURL: nil,
            homeDirectory: appHome,
            accountHomeDirectory: accountHome
        )

        #expect(urls.contains(widgetSandboxSnapshotURL))
    }

    @Test("iOS app snapshot file candidates stay in shared app group paths")
    func iOSAppSnapshotFileCandidatesStayInSharedAppGroupPaths() throws {
        let appGroupContainerURL = URL(fileURLWithPath: "/Shared/AppGroup")
        let appSandboxHome = URL(fileURLWithPath: "/private/var/mobile/Containers/Data/Application/AppUUID")
        let privateSnapshotURL = appSandboxHome
            .appendingPathComponent("Library")
            .appendingPathComponent("Group Containers")
            .appendingPathComponent(WidgetPlannerPreferenceStore.suiteName)
            .appendingPathComponent(WidgetPlannerSnapshotStore.snapshotFilename)
        let appGroupSnapshotURL = appGroupContainerURL
            .appendingPathComponent(WidgetPlannerSnapshotStore.snapshotFilename)
        let appGroupSupportSnapshotURL = appGroupContainerURL
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent("MeowPlannerWidget")
            .appendingPathComponent(WidgetPlannerSnapshotStore.snapshotFilename)

        let urls = WidgetPlannerSnapshotStore.snapshotFileURLs(
            appGroupContainerURL: appGroupContainerURL,
            homeDirectory: appSandboxHome,
            accountHomeDirectory: nil
        )

        #expect(urls.contains(appGroupSnapshotURL))
        #expect(urls.contains(appGroupSupportSnapshotURL))
        #expect(!urls.contains(privateSnapshotURL))
    }

    @Test("snapshot builder reads newly saved schedules from model context")
    func snapshotBuilderReadsNewlySavedSchedulesFromModelContext() throws {
        let container = try ModelContainerFactory.make(inMemory: true, cloudKitEnabled: false)
        let context = ModelContext(container)
        let event = PlannerEvent(title: "Fresh widget class", startDate: try date("2026-06-03 12:00"))

        context.insert(event)
        try context.save()

        let snapshot = try WidgetPlannerSnapshotBuilder.makeSnapshot(using: context)

        #expect(snapshot.plannerEvents.map(\.title).contains("Fresh widget class"))
    }

    @Test("snapshot builder reads completed schedule display preferences")
    func snapshotBuilderReadsCompletedScheduleDisplayPreferences() throws {
        let container = try ModelContainerFactory.make(inMemory: true, cloudKitEnabled: false)
        let context = ModelContext(container)
        let preference = PlannerPreference(
            showCompletedSchedules: false,
            completedSchedulesUseStrikethrough: false
        )

        context.insert(preference)
        try context.save()

        let snapshot = try WidgetPlannerSnapshotBuilder.makeSnapshot(using: context)

        #expect(snapshot.showCompletedSchedules == false)
        #expect(snapshot.completedSchedulesUseStrikethrough == false)
    }

    private func restoreUserDefaultsValue(_ value: Any?, forKey key: String, defaults: UserDefaults) {
        if let value {
            defaults.set(value, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
        defaults.synchronize()
    }

    private func date(_ value: String) throws -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return try #require(formatter.date(from: value))
    }

}

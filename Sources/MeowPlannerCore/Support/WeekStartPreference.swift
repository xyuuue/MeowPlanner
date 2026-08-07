import CryptoKit
import Foundation
import SwiftData

#if canImport(Darwin)
import Darwin
#endif

public enum WeekStartPreference: Int, CaseIterable, Codable, Identifiable, Sendable {
    case sunday = 1
    case monday = 2

    public var id: Int { rawValue }

    public var calendarFirstWeekday: Int { rawValue }

    public var titleEnglish: String {
        switch self {
        case .sunday: "Sunday"
        case .monday: "Monday"
        }
    }

    public var titleChinese: String {
        switch self {
        case .sunday: "周日"
        case .monday: "周一"
        }
    }

    public func title(language: AppLanguage) -> String {
        switch language {
        case .english: titleEnglish
        case .chinese: titleChinese
        }
    }

    public var configuredCalendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = calendarFirstWeekday
        return calendar
    }

    public func orderedVeryShortWeekdaySymbols(calendar: Calendar) -> [String] {
        orderedSymbols(calendar.veryShortWeekdaySymbols)
    }

    public func orderedShortWeekdaySymbols(calendar: Calendar) -> [String] {
        orderedSymbols(calendar.shortWeekdaySymbols)
    }

    private func orderedSymbols(_ symbols: [String]) -> [String] {
        guard symbols.count == 7 else {
            return symbols
        }

        let startIndex = max(0, min(6, calendarFirstWeekday - 1))
        return Array(symbols[startIndex...]) + Array(symbols[..<startIndex])
    }
}

public enum WidgetBackgroundStyle: String, CaseIterable, Identifiable, Codable, Sendable {
    case defaultArtwork
    case customPhoto
    case wallpaperPhoto

    public var id: String { rawValue }

    public func title(language: AppLanguage) -> String {
        switch self {
        case .defaultArtwork:
            switch language {
            case .english: "Default"
            case .chinese: "默认背景"
            }
        case .customPhoto:
            switch language {
            case .english: "Photo"
            case .chinese: "相册图片"
            }
        case .wallpaperPhoto:
            switch language {
            case .english: "Wallpaper"
            case .chinese: "壁纸透明"
            }
        }
    }

    public var isSeeThroughWidgetBackground: Bool {
        switch self {
        case .wallpaperPhoto:
            true
        case .defaultArtwork, .customPhoto:
            false
        }
    }

    public func fallbackIfImageUnavailable(
        hasCustomPhotoImage: Bool,
        hasWallpaperPhotoImage: Bool
    ) -> WidgetBackgroundStyle {
        switch self {
        case .customPhoto where !hasCustomPhotoImage:
            .defaultArtwork
        case .wallpaperPhoto where !hasWallpaperPhotoImage:
            .defaultArtwork
        default:
            self
        }
    }
}

public struct WidgetWallpaperBackgroundAdjustment: Codable, Equatable, Sendable {
    public static let defaultValue = WidgetWallpaperBackgroundAdjustment()
    public static let minimumOffset = -160.0
    public static let maximumOffset = 160.0
    public static let minimumScale = 0.8
    public static let maximumScale = 2.0

    public var placement: WidgetWallpaperBackgroundPlacement
    public var horizontalOffset: Double
    public var verticalOffset: Double
    public var scale: Double

    public init(
        placement: WidgetWallpaperBackgroundPlacement = .middle,
        horizontalOffset: Double = 0,
        verticalOffset: Double = 0,
        scale: Double = 1
    ) {
        self.placement = placement
        self.horizontalOffset = Self.clamped(horizontalOffset, minimum: Self.minimumOffset, maximum: Self.maximumOffset)
        self.verticalOffset = Self.clamped(verticalOffset, minimum: Self.minimumOffset, maximum: Self.maximumOffset)
        self.scale = Self.clamped(scale, minimum: Self.minimumScale, maximum: Self.maximumScale)
    }

    private static func clamped(_ value: Double, minimum: Double, maximum: Double) -> Double {
        min(max(value, minimum), maximum)
    }
}

public enum WidgetWallpaperBackgroundPlacement: String, CaseIterable, Identifiable, Codable, Sendable {
    case top
    case middle
    case bottom

    public var id: String { rawValue }

    public func title(language: AppLanguage) -> String {
        switch self {
        case .top:
            switch language {
            case .english: "Top"
            case .chinese: "上方"
            }
        case .middle:
            switch language {
            case .english: "Middle"
            case .chinese: "中间"
            }
        case .bottom:
            switch language {
            case .english: "Bottom"
            case .chinese: "下方"
            }
        }
    }

}

public struct WidgetWallpaperBackgroundScreenMetrics: Codable, Equatable, Sendable {
    public static let defaultValue = WidgetWallpaperBackgroundScreenMetrics(width: 393, height: 852, scale: 3)

    public var width: Double
    public var height: Double
    public var scale: Double

    public init(width: Double, height: Double, scale: Double) {
        self.width = max(1, width)
        self.height = max(1, height)
        self.scale = max(1, scale)
    }
}

public struct WidgetWallpaperBackgroundWidgetSize: Equatable, Sendable {
    public var width: Double
    public var height: Double

    public init(width: Double, height: Double) {
        self.width = max(1, width)
        self.height = max(1, height)
    }
}

public struct WidgetWallpaperBackgroundOrigin: Equatable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

public enum WidgetBackgroundImageStorageError: Error, Equatable, Sendable {
    case missingSharedContainer
}

public enum WidgetWallpaperBackgroundLayout {
    public static func mediumWidgetOrigin(
        screenMetrics: WidgetWallpaperBackgroundScreenMetrics,
        widgetSize: WidgetWallpaperBackgroundWidgetSize,
        adjustment: WidgetWallpaperBackgroundAdjustment
    ) -> WidgetWallpaperBackgroundOrigin {
        let maximumX = max(0, screenMetrics.width - widgetSize.width)
        let maximumY = max(0, screenMetrics.height - widgetSize.height)
        let baseX = maximumX / 2
        let baseY = mediumWidgetBaseY(
            screenHeight: screenMetrics.height,
            widgetHeight: widgetSize.height,
            placement: adjustment.placement
        )
        let adjustedX = baseX + adjustment.horizontalOffset
        let adjustedY = baseY + adjustment.verticalOffset

        return WidgetWallpaperBackgroundOrigin(
            x: clamped(adjustedX, minimum: 0, maximum: maximumX),
            y: clamped(adjustedY, minimum: 0, maximum: maximumY)
        )
    }

    private static func mediumWidgetBaseY(
        screenHeight: Double,
        widgetHeight: Double,
        placement: WidgetWallpaperBackgroundPlacement
    ) -> Double {
        let topSlotY = (screenHeight * 0.105).rounded()
        let dockAndSearchReservedHeight = max(170, (screenHeight * 0.23).rounded())
        let bottomSlotY = max(topSlotY, screenHeight - widgetHeight - dockAndSearchReservedHeight)

        switch placement {
        case .top:
            return topSlotY
        case .middle:
            return (topSlotY + bottomSlotY) / 2
        case .bottom:
            return bottomSlotY
        }
    }

    private static func clamped(_ value: Double, minimum: Double, maximum: Double) -> Double {
        min(max(value, minimum), maximum)
    }
}

public typealias WidgetCustomPhotoBackgroundAdjustment = WidgetWallpaperBackgroundAdjustment
public typealias WidgetCustomPhotoBackgroundPlacement = WidgetWallpaperBackgroundPlacement
public typealias WidgetCustomPhotoBackgroundScreenMetrics = WidgetWallpaperBackgroundScreenMetrics
public typealias WidgetCustomPhotoBackgroundWidgetSize = WidgetWallpaperBackgroundWidgetSize
public typealias WidgetCustomPhotoBackgroundOrigin = WidgetWallpaperBackgroundOrigin

public enum WidgetCustomPhotoBackgroundLayout {
    public static func widgetOrigin(
        screenMetrics: WidgetCustomPhotoBackgroundScreenMetrics,
        widgetSize: WidgetCustomPhotoBackgroundWidgetSize,
        adjustment: WidgetCustomPhotoBackgroundAdjustment
    ) -> WidgetCustomPhotoBackgroundOrigin {
        WidgetWallpaperBackgroundLayout.mediumWidgetOrigin(
            screenMetrics: screenMetrics,
            widgetSize: widgetSize,
            adjustment: adjustment
        )
    }
}

public enum WidgetPreferencePlatform: String, CaseIterable, Identifiable, Sendable {
    case macOS
    case iOS

    public var id: String { rawValue }

    public static var current: WidgetPreferencePlatform {
        #if os(iOS)
        .iOS
        #else
        .macOS
        #endif
    }

    public var widgetAppearancePreferenceKey: String {
        switch self {
        case .macOS: "widgetAppearancePreference.macOS"
        case .iOS: "widgetAppearancePreference"
        }
    }

    public var widgetBackgroundStyleKey: String {
        switch self {
        case .macOS: "widgetBackgroundStyle.macOS"
        case .iOS: "widgetBackgroundStyle"
        }
    }

    public var widgetTextColorHexKey: String {
        switch self {
        case .macOS: "widgetTextColorHex.macOS"
        case .iOS: "widgetTextColorHex"
        }
    }

    public var widgetBackgroundStyleFilename: String {
        switch self {
        case .macOS: "widget-background-style.macOS.txt"
        case .iOS: "widget-background-style.txt"
        }
    }

    public var customBackgroundImageFilename: String {
        switch self {
        case .macOS: "widget-custom-background.macOS.image"
        case .iOS: "widget-custom-background.image"
        }
    }

    public var defaultWidgetBackgroundStyle: WidgetBackgroundStyle {
        switch self {
        case .macOS: .defaultArtwork
        case .iOS: .defaultArtwork
        }
    }

    func normalizedWidgetBackgroundStyle(_ style: WidgetBackgroundStyle) -> WidgetBackgroundStyle {
        switch (self, style) {
        case (.macOS, .wallpaperPhoto):
            .defaultArtwork
        default:
            style
        }
    }
}

public enum WidgetPlannerPreferenceStore {
    public static let suiteName = "group.com.yuelingqiu.MeowPlanner"
    public static let weekStartPreferenceKey = "weekStartPreference"
    public static let showChineseCalendarKey = "showChineseCalendar"
    public static let widgetAppearancePreferenceKey = "widgetAppearancePreference"
    public static let widgetBackgroundStyleKey = "widgetBackgroundStyle"
    public static let widgetTextColorHexKey = "widgetTextColorHex"
    public static let defaultWidgetTextColorHex = "#3D261A"
    public static let widgetBackgroundStyleFilename = "widget-background-style.txt"
    public static let customBackgroundImageFilename = "widget-custom-background.image"
    public static let wallpaperBackgroundImageFilename = "widget-wallpaper-background.image"
    public static let customBackgroundImageDataKey = "widgetCustomBackgroundImageData"
    public static let wallpaperBackgroundImageDataKey = "widgetWallpaperBackgroundImageData"
    public static let widgetWallpaperHorizontalOffsetKey = "widgetWallpaperHorizontalOffset"
    public static let widgetWallpaperVerticalOffsetKey = "widgetWallpaperVerticalOffset"
    public static let widgetWallpaperScaleKey = "widgetWallpaperScale"
    public static let widgetWallpaperPlacementKey = "widgetWallpaperPlacement"
    public static let widgetWallpaperScreenWidthKey = "widgetWallpaperScreenWidth"
    public static let widgetWallpaperScreenHeightKey = "widgetWallpaperScreenHeight"
    public static let widgetWallpaperScreenScaleKey = "widgetWallpaperScreenScale"
    public static let widgetWallpaperBackgroundRenderVersionKey = "widgetWallpaperBackgroundRenderVersion"
    public static let widgetBackgroundRefreshTokenKey = "widgetBackgroundRefreshToken"
    public static let widgetBackgroundRefreshRequestIDKey = "widgetBackgroundRefreshRequestID"
    public static let widgetWallpaperBackgroundRefreshTokenKey = "widgetWallpaperBackgroundRefreshToken"
    public static let widgetBackgroundRevisionKey = "widgetBackgroundRevision"
    public static let currentWidgetWallpaperBackgroundRenderVersion = 6
    private static let widgetExtensionContainerIdentifier = "com.yuelingqiu.MeowPlanner.MeowPlannerWidget"
    private static let appGroupSupportDirectoryName = "MeowPlannerWidget"
    private static let legacyTransparentWidgetBackgroundStyleRawValue = "transparent"

    public static var weekStartPreference: WeekStartPreference {
        get {
            let rawValue = defaults.integer(forKey: weekStartPreferenceKey)
            return WeekStartPreference(rawValue: rawValue) ?? .sunday
        }
        set {
            defaults.set(newValue.rawValue, forKey: weekStartPreferenceKey)
        }
    }

    public static var showChineseCalendar: Bool {
        get {
            defaults.object(forKey: showChineseCalendarKey) as? Bool ?? true
        }
        set {
            defaults.set(newValue, forKey: showChineseCalendarKey)
        }
    }

    public static var widgetBackgroundStyle: WidgetBackgroundStyle {
        get {
            widgetBackgroundStyle(platform: .current)
        }
        set {
            setWidgetBackgroundStyle(newValue, platform: .current)
        }
    }

    public static var widgetAppearancePreference: AppAppearancePreference {
        get {
            widgetAppearancePreference(platform: .current)
        }
        set {
            setWidgetAppearancePreference(newValue, platform: .current)
        }
    }

    public static var customBackgroundImageURL: URL? {
        customBackgroundImageURL(platform: .current)
    }

    public static var customBackgroundImageURLs: [URL] {
        customBackgroundImageURLs(platform: .current)
    }

    public static var wallpaperBackgroundImageURL: URL? {
        wallpaperBackgroundImageURL(platform: .current)
    }

    public static var widgetWallpaperBackgroundAdjustment: WidgetWallpaperBackgroundAdjustment {
        get {
            widgetWallpaperBackgroundAdjustment(platform: .current)
        }
        set {
            setWidgetWallpaperBackgroundAdjustment(newValue, platform: .current)
        }
    }

    public static var widgetCustomPhotoBackgroundAdjustment: WidgetCustomPhotoBackgroundAdjustment {
        get {
            widgetCustomPhotoBackgroundAdjustment(platform: .current)
        }
        set {
            setWidgetCustomPhotoBackgroundAdjustment(newValue, platform: .current)
        }
    }

    public static var widgetWallpaperBackgroundScreenMetrics: WidgetWallpaperBackgroundScreenMetrics {
        get {
            widgetWallpaperBackgroundScreenMetrics(platform: .current)
        }
        set {
            setWidgetWallpaperBackgroundScreenMetrics(newValue, platform: .current)
        }
    }

    public static var widgetCustomPhotoBackgroundScreenMetrics: WidgetCustomPhotoBackgroundScreenMetrics {
        get {
            widgetCustomPhotoBackgroundScreenMetrics(platform: .current)
        }
        set {
            setWidgetCustomPhotoBackgroundScreenMetrics(newValue, platform: .current)
        }
    }

    public static func widgetAppearancePreferenceKey(for platform: WidgetPreferencePlatform) -> String {
        platform.widgetAppearancePreferenceKey
    }

    public static func widgetBackgroundStyleKey(for platform: WidgetPreferencePlatform) -> String {
        platform.widgetBackgroundStyleKey
    }

    public static func widgetTextColorHexKey(for platform: WidgetPreferencePlatform) -> String {
        platform.widgetTextColorHexKey
    }

    public static func widgetBackgroundStyleFilename(for platform: WidgetPreferencePlatform) -> String {
        platform.widgetBackgroundStyleFilename
    }

    public static func customBackgroundImageFilename(for platform: WidgetPreferencePlatform) -> String {
        platform.customBackgroundImageFilename
    }

    static func customBackgroundImageDataKey(for platform: WidgetPreferencePlatform) -> String {
        switch platform {
        case .macOS:
            "\(customBackgroundImageDataKey).macOS"
        case .iOS:
            customBackgroundImageDataKey
        }
    }

    static func wallpaperBackgroundImageDataKey(for platform: WidgetPreferencePlatform) -> String {
        switch platform {
        case .macOS:
            "\(wallpaperBackgroundImageDataKey).macOS"
        case .iOS:
            wallpaperBackgroundImageDataKey
        }
    }

    public static func widgetAppearancePreference(platform: WidgetPreferencePlatform) -> AppAppearancePreference {
        widgetAppearancePreference(platform: platform, defaults: defaults)
    }

    public static func widgetAppearancePreference(defaults: UserDefaults) -> AppAppearancePreference {
        widgetAppearancePreference(platform: .current, defaults: defaults)
    }

    public static func widgetAppearancePreference(
        platform: WidgetPreferencePlatform,
        defaults: UserDefaults
    ) -> AppAppearancePreference {
        let key = widgetAppearancePreferenceKey(for: platform)
        guard let rawValue = defaults.string(forKey: key) else {
            return .system
        }

        return AppAppearancePreference(storedValue: rawValue)
    }

    public static func setWidgetAppearancePreference(
        _ preference: AppAppearancePreference,
        platform: WidgetPreferencePlatform
    ) {
        setWidgetAppearancePreference(preference, platform: platform, defaults: defaults)
    }

    public static func setWidgetAppearancePreference(_ preference: AppAppearancePreference, defaults: UserDefaults) {
        setWidgetAppearancePreference(preference, platform: .current, defaults: defaults)
    }

    public static func setWidgetAppearancePreference(
        _ preference: AppAppearancePreference,
        platform: WidgetPreferencePlatform,
        defaults: UserDefaults
    ) {
        defaults.set(preference.rawValue, forKey: widgetAppearancePreferenceKey(for: platform))
        defaults.synchronize()
    }

    public static func isDarkWidgetAppearance(systemIsDark: Bool) -> Bool {
        isDarkWidgetAppearance(systemIsDark: systemIsDark, platform: .current)
    }

    public static func isDarkWidgetAppearance(
        systemIsDark: Bool,
        backgroundStyle: WidgetBackgroundStyle
    ) -> Bool {
        isDarkWidgetAppearance(systemIsDark: systemIsDark, backgroundStyle: backgroundStyle, platform: .current)
    }

    public static func isDarkWidgetAppearance(systemIsDark: Bool, defaults: UserDefaults) -> Bool {
        isDarkWidgetAppearance(systemIsDark: systemIsDark, platform: .current, defaults: defaults)
    }

    public static func isDarkWidgetAppearance(
        systemIsDark: Bool,
        backgroundStyle: WidgetBackgroundStyle,
        platform: WidgetPreferencePlatform
    ) -> Bool {
        isDarkWidgetAppearance(
            systemIsDark: systemIsDark,
            backgroundStyle: backgroundStyle,
            platform: platform,
            defaults: defaults
        )
    }

    public static func isDarkWidgetAppearance(
        systemIsDark: Bool,
        platform: WidgetPreferencePlatform
    ) -> Bool {
        isDarkWidgetAppearance(systemIsDark: systemIsDark, platform: platform, defaults: defaults)
    }

    public static func isDarkWidgetAppearance(
        systemIsDark: Bool,
        platform: WidgetPreferencePlatform,
        defaults: UserDefaults
    ) -> Bool {
        switch widgetAppearancePreference(platform: platform, defaults: defaults) {
        case .system:
            systemIsDark
        case .light:
            false
        case .dark:
            true
        }
    }

    public static func isDarkWidgetAppearance(
        systemIsDark: Bool,
        backgroundStyle: WidgetBackgroundStyle,
        platform: WidgetPreferencePlatform,
        defaults: UserDefaults
    ) -> Bool {
        guard backgroundStyle == .defaultArtwork else {
            return false
        }

        return isDarkWidgetAppearance(systemIsDark: systemIsDark, platform: platform, defaults: defaults)
    }

    public static var widgetTextColorHex: String? {
        get {
            widgetTextColorHex(platform: .current)
        }
        set {
            setWidgetTextColorHex(newValue, platform: .current)
        }
    }

    public static func widgetTextColorHex(platform: WidgetPreferencePlatform) -> String? {
        widgetTextColorHex(platform: platform, defaults: defaults)
    }

    public static func widgetTextColorHex(defaults: UserDefaults) -> String? {
        widgetTextColorHex(platform: .current, defaults: defaults)
    }

    public static func widgetTextColorHex(platform: WidgetPreferencePlatform, defaults: UserDefaults) -> String? {
        let key = widgetTextColorHexKey(for: platform)
        guard let rawValue = defaults.string(forKey: key) else {
            return nil
        }

        guard let normalizedHex = normalizedWidgetTextColorHex(rawValue) else {
            defaults.removeObject(forKey: key)
            defaults.synchronize()
            return nil
        }

        if normalizedHex != rawValue {
            defaults.set(normalizedHex, forKey: key)
            defaults.synchronize()
        }

        return normalizedHex
    }

    public static func setWidgetTextColorHex(_ hex: String?, platform: WidgetPreferencePlatform) {
        setWidgetTextColorHex(hex, platform: platform, defaults: defaults)
    }

    public static func setWidgetTextColorHex(_ hex: String?, defaults: UserDefaults) {
        setWidgetTextColorHex(hex, platform: .current, defaults: defaults)
    }

    public static func setWidgetTextColorHex(
        _ hex: String?,
        platform: WidgetPreferencePlatform,
        defaults: UserDefaults
    ) {
        let key = widgetTextColorHexKey(for: platform)
        guard let normalizedHex = normalizedWidgetTextColorHex(hex) else {
            defaults.removeObject(forKey: key)
            defaults.synchronize()
            return
        }

        defaults.set(normalizedHex, forKey: key)
        defaults.synchronize()
    }

    public static func clearWidgetTextColorHex(platform: WidgetPreferencePlatform) {
        clearWidgetTextColorHex(platform: platform, defaults: defaults)
    }

    public static func clearWidgetTextColorHex(defaults: UserDefaults) {
        clearWidgetTextColorHex(platform: .current, defaults: defaults)
    }

    public static func clearWidgetTextColorHex(platform: WidgetPreferencePlatform, defaults: UserDefaults) {
        defaults.removeObject(forKey: widgetTextColorHexKey(for: platform))
        defaults.synchronize()
    }

    private static func normalizedWidgetTextColorHex(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let trimmed = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#"))
            .uppercased()

        guard trimmed.count == 6,
              UInt64(trimmed, radix: 16) != nil else {
            return nil
        }

        return "#\(trimmed)"
    }

    public static func widgetBackgroundStyle(platform: WidgetPreferencePlatform) -> WidgetBackgroundStyle {
        widgetBackgroundStyle(
            platform: platform,
            defaults: defaults,
            styleFileURLs: widgetBackgroundStyleFileURLs(platform: platform)
        )
    }

    public static func widgetBackgroundStyle(defaults: UserDefaults) -> WidgetBackgroundStyle {
        widgetBackgroundStyle(platform: .current, defaults: defaults)
    }

    public static func widgetBackgroundStyle(defaults: UserDefaults, styleFileURLs: [URL]) -> WidgetBackgroundStyle {
        widgetBackgroundStyle(platform: .current, defaults: defaults, styleFileURLs: styleFileURLs)
    }

    public static func widgetBackgroundStyle(
        platform: WidgetPreferencePlatform,
        defaults: UserDefaults
    ) -> WidgetBackgroundStyle {
        widgetBackgroundStyle(platform: platform, defaults: defaults, styleFileURLs: [])
    }

    public static func widgetBackgroundStyle(
        platform: WidgetPreferencePlatform,
        defaults: UserDefaults,
        styleFileURLs: [URL]
    ) -> WidgetBackgroundStyle {
        let key = widgetBackgroundStyleKey(for: platform)
        let mirroredResolution = widgetBackgroundStyle(styleFileURLs: styleFileURLs, platform: platform)
        if let rawValue = defaults.string(forKey: key),
           let resolution = resolvedWidgetBackgroundStyle(rawValue: rawValue, platform: platform) {
            if resolution.didNormalize || rawValue.trimmingCharacters(in: .whitespacesAndNewlines) != resolution.style.rawValue {
                defaults.set(resolution.style.rawValue, forKey: key)
                defaults.synchronize()
            }
            saveWidgetBackgroundStyle(resolution.style, styleFileURLs: styleFileURLs)
            return resolution.style
        }

        if let resolution = mirroredResolution {
            defaults.set(resolution.style.rawValue, forKey: key)
            defaults.synchronize()
            saveWidgetBackgroundStyle(resolution.style, styleFileURLs: styleFileURLs)
            return resolution.style
        }

        return platform.defaultWidgetBackgroundStyle
    }

    public static func setWidgetBackgroundStyle(_ style: WidgetBackgroundStyle, platform: WidgetPreferencePlatform) {
        setWidgetBackgroundStyle(
            style,
            platform: platform,
            defaults: defaults,
            styleFileURLs: widgetBackgroundStyleFileURLs(platform: platform)
        )
    }

    public static func setWidgetBackgroundStyle(_ style: WidgetBackgroundStyle, defaults: UserDefaults) {
        setWidgetBackgroundStyle(style, platform: .current, defaults: defaults)
    }

    public static func setWidgetBackgroundStyle(_ style: WidgetBackgroundStyle, defaults: UserDefaults, styleFileURLs: [URL]) {
        setWidgetBackgroundStyle(style, platform: .current, defaults: defaults, styleFileURLs: styleFileURLs)
    }

    public static func setWidgetBackgroundStyle(
        _ style: WidgetBackgroundStyle,
        platform: WidgetPreferencePlatform,
        defaults: UserDefaults
    ) {
        setWidgetBackgroundStyle(style, platform: platform, defaults: defaults, styleFileURLs: [])
    }

    public static func setWidgetBackgroundStyle(
        _ style: WidgetBackgroundStyle,
        platform: WidgetPreferencePlatform,
        defaults: UserDefaults,
        styleFileURLs: [URL]
    ) {
        let normalizedStyle = platform.normalizedWidgetBackgroundStyle(style)
        defaults.set(normalizedStyle.rawValue, forKey: widgetBackgroundStyleKey(for: platform))
        defaults.synchronize()
        saveWidgetBackgroundStyle(normalizedStyle, styleFileURLs: styleFileURLs)
    }

    @discardableResult
    public static func synchronizeWidgetBackgroundStyleMirrors(
        platform: WidgetPreferencePlatform
    ) -> Bool {
        synchronizeWidgetBackgroundStyleMirrors(
            platform: platform,
            defaults: defaults,
            styleFileURLs: widgetBackgroundStyleFileURLs(platform: platform)
        )
    }

    @discardableResult
    public static func synchronizeWidgetBackgroundStyleMirrors(
        platform: WidgetPreferencePlatform,
        defaults: UserDefaults,
        styleFileURLs: [URL]
    ) -> Bool {
        let key = widgetBackgroundStyleKey(for: platform)
        if let rawValue = defaults.string(forKey: key),
           let resolution = resolvedWidgetBackgroundStyle(rawValue: rawValue, platform: platform) {
            var didSynchronize = false
            if resolution.didNormalize {
                defaults.set(resolution.style.rawValue, forKey: key)
                defaults.synchronize()
                didSynchronize = true
            }

            return saveWidgetBackgroundStyle(resolution.style, styleFileURLs: styleFileURLs) || didSynchronize
        }

        guard let resolution = widgetBackgroundStyle(styleFileURLs: styleFileURLs, platform: platform) else {
            return false
        }

        defaults.set(resolution.style.rawValue, forKey: key)
        defaults.synchronize()
        saveWidgetBackgroundStyle(resolution.style, styleFileURLs: styleFileURLs)
        return true
    }

    private static func widgetBackgroundStyle(
        styleFileURLs: [URL],
        platform: WidgetPreferencePlatform
    ) -> WidgetBackgroundStyleResolution? {
        for fileURL in styleFileURLs {
            guard let rawValue = try? String(contentsOf: fileURL, encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines),
                let resolution = resolvedWidgetBackgroundStyle(rawValue: rawValue, platform: platform)
            else {
                continue
            }

            return resolution
        }

        return nil
    }

    private static func resolvedWidgetBackgroundStyle(
        rawValue: String,
        platform: WidgetPreferencePlatform
    ) -> WidgetBackgroundStyleResolution? {
        let trimmedRawValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedRawValue == legacyTransparentWidgetBackgroundStyleRawValue {
            return WidgetBackgroundStyleResolution(
                style: .defaultArtwork,
                didNormalize: true
            )
        }

        guard let style = WidgetBackgroundStyle(rawValue: trimmedRawValue) else {
            return nil
        }

        let normalizedStyle = platform.normalizedWidgetBackgroundStyle(style)
        return WidgetBackgroundStyleResolution(
            style: normalizedStyle,
            didNormalize: normalizedStyle != style
        )
    }

    private struct WidgetBackgroundStyleResolution {
        var style: WidgetBackgroundStyle
        var didNormalize: Bool
    }

    @discardableResult
    private static func saveWidgetBackgroundStyle(_ style: WidgetBackgroundStyle, styleFileURLs: [URL]) -> Bool {
        var didWriteStyle = false
        for fileURL in styleFileURLs {
            if let currentRawValue = try? String(contentsOf: fileURL, encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines),
               currentRawValue == style.rawValue {
                continue
            }

            do {
                try FileManager.default.createDirectory(
                    at: fileURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try style.rawValue.write(to: fileURL, atomically: true, encoding: .utf8)
                didWriteStyle = true
            } catch {
                continue
            }
        }

        return didWriteStyle
    }

    private static func widgetBackgroundStyleFileURLs(platform: WidgetPreferencePlatform) -> [URL] {
        widgetBackgroundStyleFileURLs(
            platform: platform,
            appGroupContainerURL: FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: suiteName),
            homeDirectory: currentHomeDirectory,
            accountHomeDirectory: accountHomeDirectory
        )
    }

    static func widgetBackgroundStyleFileURLs(
        platform: WidgetPreferencePlatform,
        appGroupContainerURL: URL?,
        homeDirectory: URL,
        accountHomeDirectory: URL?
    ) -> [URL] {
        var urls: [URL] = []
        let filename = widgetBackgroundStyleFilename(for: platform)
        let homeStyleURL = homeDirectory
            .appendingPathComponent("Library")
            .appendingPathComponent("Group Containers")
            .appendingPathComponent(suiteName)
            .appendingPathComponent(filename)
        let isWidgetSandboxHome = homeDirectory.path.contains(
            "/Library/Containers/\(widgetExtensionContainerIdentifier)/Data"
        )

        if isWidgetSandboxHome {
            urls.append(homeStyleURL)
        }

        if let appGroupContainerURL {
            urls.append(appGroupContainerURL.appendingPathComponent(filename))
            urls.append(appGroupSupportFileURL(appGroupContainerURL: appGroupContainerURL, filename: filename))
        }

        if let accountHomeDirectory,
           shouldAppendAccountHomeGroupContainerMirror(accountHomeDirectory) {
            let accountGroupStyleURL = accountHomeDirectory
                .appendingPathComponent("Library")
                .appendingPathComponent("Group Containers")
                .appendingPathComponent(suiteName)
                .appendingPathComponent(filename)
            let widgetSandboxMirrorStyleURL = accountHomeDirectory
                .appendingPathComponent("Library")
                .appendingPathComponent("Containers")
                .appendingPathComponent(widgetExtensionContainerIdentifier)
                .appendingPathComponent("Data")
                .appendingPathComponent("Library")
                .appendingPathComponent("Group Containers")
                .appendingPathComponent(suiteName)
                .appendingPathComponent(filename)

            urls.append(accountGroupStyleURL)
            urls.append(widgetSandboxMirrorStyleURL)
        }

        if let simulatorDataRootGroupStyleURL = simulatorDataRootGroupContainerFileURL(
            from: homeDirectory,
            filename: filename
        ) {
            urls.append(simulatorDataRootGroupStyleURL)
        }

        if let accountHomeDirectory,
           let simulatorDataRootGroupStyleURL = simulatorDataRootGroupContainerFileURL(
            from: accountHomeDirectory,
            filename: filename
           ) {
            urls.append(simulatorDataRootGroupStyleURL)
        }

        if shouldAppendHomeGroupContainerMirror(
            platform: platform,
            homeDirectory: homeDirectory,
            isWidgetSandboxHome: isWidgetSandboxHome
        ) {
            urls.append(homeStyleURL)
        }

        if accountHomeDirectory == nil, let userHome = NSHomeDirectoryForUser(NSUserName()) {
            urls.append(
                URL(fileURLWithPath: userHome)
                    .appendingPathComponent("Library")
                    .appendingPathComponent("Group Containers")
                    .appendingPathComponent(suiteName)
                    .appendingPathComponent(filename)
            )
        }

        return urls.reduce(into: []) { uniqueURLs, url in
            guard !uniqueURLs.contains(url) else {
                return
            }
            uniqueURLs.append(url)
        }
    }

    private static var currentHomeDirectory: URL {
        #if os(macOS)
        return FileManager.default.homeDirectoryForCurrentUser
        #else
        if let applicationSupportDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first {
            return applicationSupportDirectory
                .deletingLastPathComponent()
                .deletingLastPathComponent()
        }

        return URL(fileURLWithPath: NSHomeDirectory())
        #endif
    }

    private static var accountHomeDirectory: URL? {
        #if canImport(Darwin)
        guard
            let passwd = getpwuid(getuid()),
            let homePath = passwd.pointee.pw_dir
        else {
            return nil
        }
        return URL(fileURLWithPath: String(cString: homePath))
        #else
        return nil
        #endif
    }

    private static func simulatorDataRootGroupContainerFileURL(from sandboxHomeDirectory: URL, filename: String) -> URL? {
        let components = sandboxHomeDirectory.standardizedFileURL.pathComponents
        guard components.contains("CoreSimulator") else {
            return nil
        }

        guard let containersIndex = components.lastIndex(of: "Containers"), containersIndex > 0 else {
            return nil
        }

        let dataRootPath = NSString.path(withComponents: Array(components[..<containersIndex]))
        guard !dataRootPath.isEmpty else {
            return nil
        }

        return URL(fileURLWithPath: dataRootPath)
            .appendingPathComponent("Library")
            .appendingPathComponent("Group Containers")
            .appendingPathComponent(suiteName)
            .appendingPathComponent(filename)
    }

    public static func customBackgroundImageURL(fileManager: FileManager = .default) -> URL? {
        customBackgroundImageURL(platform: .current, fileManager: fileManager)
    }

    public static func customBackgroundImageData(platform: WidgetPreferencePlatform) -> Data? {
        customBackgroundImageData(
            platform: platform,
            defaults: defaults,
            fileURLs: customBackgroundImageURLs(platform: platform)
        )
    }

    static func customBackgroundImageData(
        platform: WidgetPreferencePlatform,
        defaults: UserDefaults,
        fileURLs: [URL]
    ) -> Data? {
        backgroundImageData(
            defaults: defaults,
            dataKey: customBackgroundImageDataKey(for: platform),
            fileURLs: fileURLs
        )
    }

    public static func customBackgroundImageURLs(
        platform: WidgetPreferencePlatform,
        fileManager: FileManager = .default
    ) -> [URL] {
        #if canImport(Darwin)
        return customBackgroundImageURLs(
            platform: platform,
            appGroupContainerURL: fileManager.containerURL(forSecurityApplicationGroupIdentifier: suiteName),
            homeDirectory: currentHomeDirectory,
            accountHomeDirectory: accountHomeDirectory
        )
        #else
        return []
        #endif
    }

    public static func customBackgroundImageURL(
        platform: WidgetPreferencePlatform,
        fileManager: FileManager = .default
    ) -> URL? {
        customBackgroundImageURLs(platform: platform, fileManager: fileManager).first
    }

    static func customBackgroundImageURLs(
        platform: WidgetPreferencePlatform,
        appGroupContainerURL: URL?,
        homeDirectory: URL,
        accountHomeDirectory: URL?
    ) -> [URL] {
        let filename = customBackgroundImageFilename(for: platform)

        guard platform == .iOS else {
            return appGroupContainerURL.map { [$0.appendingPathComponent(filename)] } ?? []
        }

        return iOSBackgroundImageURLs(
            filename: filename,
            appGroupContainerURL: appGroupContainerURL,
            homeDirectory: homeDirectory,
            accountHomeDirectory: accountHomeDirectory
        )
    }

    public static func saveCustomBackgroundImageData(_ data: Data) throws {
        try saveCustomBackgroundImageData(data, platform: .current)
    }

    public static func saveCustomBackgroundImageData(
        _ data: Data,
        platform: WidgetPreferencePlatform
    ) throws {
        #if canImport(Darwin)
        guard let primaryFileURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: suiteName)?
            .appendingPathComponent(customBackgroundImageFilename(for: platform))
        else {
            if platform == .iOS {
                throw WidgetBackgroundImageStorageError.missingSharedContainer
            }
            return
        }

        let mirrorFileURLs = customBackgroundImageURLs(platform: platform)
            .filter { $0 != primaryFileURL }
        try saveCustomBackgroundImageData(
            data,
            platform: platform,
            defaults: defaults,
            fileURLs: [primaryFileURL] + mirrorFileURLs
        )
        #endif
    }

    static func saveCustomBackgroundImageData(
        _ data: Data,
        platform: WidgetPreferencePlatform,
        defaults: UserDefaults,
        fileURLs: [URL]
    ) throws {
        try saveBackgroundImageData(
            data,
            defaults: defaults,
            dataKey: customBackgroundImageDataKey(for: platform),
            fileURLs: fileURLs
        )
    }

    public static func saveCustomBackgroundImageData(_ data: Data, fileURL: URL) throws {
        try saveCustomBackgroundImageData(data, fileURLs: [fileURL])
    }

    public static func saveCustomBackgroundImageData(_ data: Data, fileURLs: [URL]) throws {
        try saveBackgroundImageData(data, fileURLs: fileURLs)
    }

    public static func clearCustomBackgroundImage() {
        clearCustomBackgroundImage(platform: .current)
    }

    public static func clearCustomBackgroundImage(platform: WidgetPreferencePlatform) {
        let fileURLs = customBackgroundImageURLs(platform: platform)
        defaults.removeObject(forKey: customBackgroundImageDataKey(for: platform))
        defaults.synchronize()
        guard !fileURLs.isEmpty else {
            return
        }

        clearCustomBackgroundImage(fileURLs: fileURLs)
    }

    public static func clearCustomBackgroundImage(fileURL: URL) {
        clearCustomBackgroundImage(fileURLs: [fileURL])
    }

    public static func clearCustomBackgroundImage(fileURLs: [URL]) {
        for fileURL in fileURLs {
            removeBackgroundImage(fileURL: fileURL)
        }
    }

    public static func validateCustomBackgroundImageData(platform: WidgetPreferencePlatform) -> Bool {
        validateCustomBackgroundImageData(platform: platform, defaults: defaults)
    }

    static func validateCustomBackgroundImageData(platform: WidgetPreferencePlatform, defaults: UserDefaults) -> Bool {
        validateCustomBackgroundImageData(
            platform: platform,
            defaults: defaults,
            fileURLs: customBackgroundImageURLs(platform: platform)
        )
    }

    static func validateCustomBackgroundImageData(
        platform: WidgetPreferencePlatform,
        defaults: UserDefaults,
        fileURLs: [URL]
    ) -> Bool {
        if platform == .iOS {
            return validateSharedOrMirroredBackgroundImageData(
                defaults: defaults,
                dataKey: customBackgroundImageDataKey(for: platform),
                fileURLs: fileURLs
            )
        }

        return validateBackgroundImageData(fileURLs: fileURLs)
    }

    @discardableResult
    public static func repairCustomBackgroundImageMirrors(platform: WidgetPreferencePlatform) -> Bool {
        repairCustomBackgroundImageMirrors(
            platform: platform,
            defaults: defaults,
            fileURLs: customBackgroundImageURLs(platform: platform)
        )
    }

    @discardableResult
    static func repairCustomBackgroundImageMirrors(defaults: UserDefaults, fileURLs: [URL]) -> Bool {
        repairCustomBackgroundImageMirrors(platform: .iOS, defaults: defaults, fileURLs: fileURLs)
    }

    @discardableResult
    static func repairCustomBackgroundImageMirrors(
        platform: WidgetPreferencePlatform,
        defaults: UserDefaults,
        fileURLs: [URL]
    ) -> Bool {
        repairBackgroundImageMirrors(
            defaults: defaults,
            dataKey: customBackgroundImageDataKey(for: platform),
            fileURLs: fileURLs
        )
    }

    @discardableResult
    public static func repairCustomBackgroundImageMirrors(fileURLs: [URL]) -> Bool {
        repairBackgroundImageMirrors(fileURLs: fileURLs)
    }

    public static func wallpaperBackgroundImageURL(fileManager: FileManager = .default) -> URL? {
        wallpaperBackgroundImageURL(platform: .current, fileManager: fileManager)
    }

    public static func wallpaperBackgroundImageData(platform: WidgetPreferencePlatform) -> Data? {
        wallpaperBackgroundImageData(
            platform: platform,
            defaults: defaults,
            fileURLs: wallpaperBackgroundImageURLs(platform: platform)
        )
    }

    static func wallpaperBackgroundImageData(
        platform: WidgetPreferencePlatform,
        defaults: UserDefaults,
        fileURLs: [URL]
    ) -> Data? {
        backgroundImageData(
            defaults: defaults,
            dataKey: wallpaperBackgroundImageDataKey(for: platform),
            fileURLs: fileURLs
        )
    }

    public static var wallpaperBackgroundImageURLs: [URL] {
        wallpaperBackgroundImageURLs(platform: .current)
    }

    public static func wallpaperBackgroundImageURL(
        platform: WidgetPreferencePlatform,
        fileManager: FileManager = .default
    ) -> URL? {
        wallpaperBackgroundImageURLs(platform: platform, fileManager: fileManager).first
    }

    public static func wallpaperBackgroundImageURLs(
        platform: WidgetPreferencePlatform,
        fileManager: FileManager = .default
    ) -> [URL] {
        #if canImport(Darwin)
        return wallpaperBackgroundImageURLs(
            platform: platform,
            appGroupContainerURL: fileManager.containerURL(forSecurityApplicationGroupIdentifier: suiteName),
            homeDirectory: currentHomeDirectory,
            accountHomeDirectory: accountHomeDirectory
        )
        #else
        return []
        #endif
    }

    static func wallpaperBackgroundImageURLs(
        platform: WidgetPreferencePlatform,
        appGroupContainerURL: URL?,
        homeDirectory: URL,
        accountHomeDirectory: URL?
    ) -> [URL] {
        guard platform == .iOS else {
            return []
        }

        return iOSBackgroundImageURLs(
            filename: wallpaperBackgroundImageFilename,
            appGroupContainerURL: appGroupContainerURL,
            homeDirectory: homeDirectory,
            accountHomeDirectory: accountHomeDirectory
        )
    }

    public static func saveWallpaperBackgroundImageData(_ data: Data) throws {
        try saveWallpaperBackgroundImageData(data, platform: .current)
    }

    public static func saveWallpaperBackgroundImageData(
        _ data: Data,
        platform: WidgetPreferencePlatform
    ) throws {
        #if canImport(Darwin)
        guard platform == .iOS else {
            return
        }

        guard let primaryFileURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: suiteName)?
            .appendingPathComponent(wallpaperBackgroundImageFilename)
        else {
            throw WidgetBackgroundImageStorageError.missingSharedContainer
        }

        let mirrorFileURLs = wallpaperBackgroundImageURLs(platform: platform)
            .filter { $0 != primaryFileURL }
        try saveWallpaperBackgroundImageData(
            data,
            platform: platform,
            defaults: defaults,
            fileURLs: [primaryFileURL] + mirrorFileURLs
        )
        #endif
    }

    static func saveWallpaperBackgroundImageData(
        _ data: Data,
        platform: WidgetPreferencePlatform,
        defaults: UserDefaults,
        fileURLs: [URL]
    ) throws {
        try saveBackgroundImageData(
            data,
            defaults: defaults,
            dataKey: wallpaperBackgroundImageDataKey(for: platform),
            fileURLs: fileURLs
        )
    }

    public static func saveWallpaperBackgroundImageData(_ data: Data, fileURL: URL) throws {
        try saveWallpaperBackgroundImageData(data, fileURLs: [fileURL])
    }

    public static func saveWallpaperBackgroundImageData(_ data: Data, fileURLs: [URL]) throws {
        try saveBackgroundImageData(data, fileURLs: fileURLs)
    }

    private static func writeWallpaperBackgroundImageData(_ data: Data, fileURL: URL) throws {
        try writeBackgroundImageData(data, fileURL: fileURL)
    }

    public static func clearWallpaperBackgroundImage() {
        clearWallpaperBackgroundImage(platform: .current)
    }

    public static func clearWallpaperBackgroundImage(platform: WidgetPreferencePlatform) {
        let fileURLs = wallpaperBackgroundImageURLs(platform: platform)
        defaults.removeObject(forKey: wallpaperBackgroundImageDataKey(for: platform))
        defaults.synchronize()
        guard !fileURLs.isEmpty else {
            return
        }

        clearWallpaperBackgroundImage(fileURLs: fileURLs)
    }

    public static func clearWallpaperBackgroundImage(fileURL: URL) {
        clearWallpaperBackgroundImage(fileURLs: [fileURL])
    }

    public static func clearWallpaperBackgroundImage(fileURLs: [URL]) {
        for fileURL in fileURLs {
            removeWallpaperBackgroundImage(fileURL: fileURL)
        }
    }

    @discardableResult
    public static func repairWallpaperBackgroundImageMirrors(platform: WidgetPreferencePlatform) -> Bool {
        repairWallpaperBackgroundImageMirrors(
            platform: platform,
            defaults: defaults,
            fileURLs: wallpaperBackgroundImageURLs(platform: platform)
        )
    }

    @discardableResult
    static func repairWallpaperBackgroundImageMirrors(defaults: UserDefaults, fileURLs: [URL]) -> Bool {
        repairWallpaperBackgroundImageMirrors(platform: .iOS, defaults: defaults, fileURLs: fileURLs)
    }

    @discardableResult
    static func repairWallpaperBackgroundImageMirrors(
        platform: WidgetPreferencePlatform,
        defaults: UserDefaults,
        fileURLs: [URL]
    ) -> Bool {
        repairBackgroundImageMirrors(
            defaults: defaults,
            dataKey: wallpaperBackgroundImageDataKey(for: platform),
            fileURLs: fileURLs
        )
    }

    @discardableResult
    public static func repairWallpaperBackgroundImageMirrors(fileURLs: [URL]) -> Bool {
        repairBackgroundImageMirrors(fileURLs: fileURLs)
    }

    public static func validateWallpaperBackgroundImageData(platform: WidgetPreferencePlatform) -> Bool {
        validateWallpaperBackgroundImageData(platform: platform, defaults: defaults)
    }

    static func validateWallpaperBackgroundImageData(platform: WidgetPreferencePlatform, defaults: UserDefaults) -> Bool {
        validateWallpaperBackgroundImageData(
            platform: platform,
            defaults: defaults,
            fileURLs: wallpaperBackgroundImageURLs(platform: platform)
        )
    }

    static func validateWallpaperBackgroundImageData(
        platform: WidgetPreferencePlatform,
        defaults: UserDefaults,
        fileURLs: [URL]
    ) -> Bool {
        guard platform == .iOS else {
            return validateBackgroundImageData(fileURLs: fileURLs)
        }

        return validateSharedOrMirroredBackgroundImageData(
            defaults: defaults,
            dataKey: wallpaperBackgroundImageDataKey(for: platform),
            fileURLs: fileURLs
        )
    }

    private static func saveBackgroundImageData(_ data: Data, fileURLs: [URL]) throws {
        guard let primaryFileURL = fileURLs.first else {
            throw WidgetBackgroundImageStorageError.missingSharedContainer
        }

        try writeBackgroundImageData(data, fileURL: primaryFileURL)

        for mirrorFileURL in fileURLs.dropFirst() {
            try? writeBackgroundImageData(data, fileURL: mirrorFileURL)
        }
    }

    private static func saveBackgroundImageData(
        _ data: Data,
        defaults: UserDefaults,
        dataKey: String,
        fileURLs: [URL]
    ) throws {
        try saveBackgroundImageData(data, fileURLs: fileURLs)
        defaults.set(data, forKey: dataKey)
        defaults.synchronize()
    }

    private static func writeBackgroundImageData(_ data: Data, fileURL: URL) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: fileURL, options: .atomic)
    }

    private static func validateBackgroundImageData(fileURLs: [URL]) -> Bool {
        fileURLs.contains { fileURL in
            guard let data = try? Data(contentsOf: fileURL) else {
                return false
            }

            return !data.isEmpty
        }
    }

    private static func validateSharedOrMirroredBackgroundImageData(
        defaults: UserDefaults,
        dataKey: String,
        fileURLs: [URL]
    ) -> Bool {
        guard let data = backgroundImageData(
            defaults: defaults,
            dataKey: dataKey,
            fileURLs: fileURLs
        ) else {
            return false
        }

        if defaults.data(forKey: dataKey) != data {
            defaults.set(data, forKey: dataKey)
            defaults.synchronize()
        }

        return true
    }

    private static func backgroundImageData(
        defaults: UserDefaults,
        dataKey: String,
        fileURLs: [URL]
    ) -> Data? {
        if let data = sharedBackgroundImageData(defaults: defaults, dataKey: dataKey) {
            _ = repairBackgroundImageFileMirrors(sourceData: data, fileURLs: fileURLs)
            return data
        }

        return firstBackgroundImageData(fileURLs: fileURLs)
    }

    private static func firstBackgroundImageData(fileURLs: [URL]) -> Data? {
        fileURLs.lazy.compactMap { fileURL -> Data? in
            guard let data = try? Data(contentsOf: fileURL), !data.isEmpty else {
                return nil
            }
            return data
        }.first
    }

    private static func sharedBackgroundImageData(defaults: UserDefaults, dataKey: String) -> Data? {
        guard let data = defaults.data(forKey: dataKey), !data.isEmpty else {
            return nil
        }

        return data
    }

    private static func repairBackgroundImageMirrors(fileURLs: [URL]) -> Bool {
        guard let sourceData = firstBackgroundImageData(fileURLs: fileURLs) else {
            return false
        }

        return repairBackgroundImageFileMirrors(sourceData: sourceData, fileURLs: fileURLs)
    }

    private static func repairBackgroundImageFileMirrors(sourceData: Data, fileURLs: [URL]) -> Bool {
        var repairedMirror = false
        for fileURL in fileURLs {
            if (try? Data(contentsOf: fileURL)) == sourceData {
                continue
            }

            do {
                try writeBackgroundImageData(sourceData, fileURL: fileURL)
                repairedMirror = true
            } catch {
                continue
            }
        }

        return repairedMirror
    }

    private static func repairBackgroundImageMirrors(
        defaults: UserDefaults,
        dataKey: String,
        fileURLs: [URL]
    ) -> Bool {
        let sourceData: Data
        if let sharedData = sharedBackgroundImageData(defaults: defaults, dataKey: dataKey) {
            sourceData = sharedData
        } else if let fileData = firstBackgroundImageData(fileURLs: fileURLs) {
            sourceData = fileData
        } else {
            return false
        }

        var repairedMirror = false
        if defaults.data(forKey: dataKey) != sourceData {
            defaults.set(sourceData, forKey: dataKey)
            defaults.synchronize()
            repairedMirror = true
        }

        if repairBackgroundImageFileMirrors(sourceData: sourceData, fileURLs: fileURLs) {
            repairedMirror = true
        }

        return repairedMirror
    }

    private static func removeWallpaperBackgroundImage(fileURL: URL) {
        removeBackgroundImage(fileURL: fileURL)
    }

    private static func removeBackgroundImage(fileURL: URL) {
        try? FileManager.default.removeItem(at: fileURL)
    }

    private static func iOSBackgroundImageURLs(
        filename: String,
        appGroupContainerURL: URL?,
        homeDirectory: URL,
        accountHomeDirectory: URL?
    ) -> [URL] {
        var urls: [URL] = []
        let homeImageURL = homeDirectory
            .appendingPathComponent("Library")
            .appendingPathComponent("Group Containers")
            .appendingPathComponent(suiteName)
            .appendingPathComponent(filename)
        let isWidgetSandboxHome = homeDirectory.path.contains(
            "/Library/Containers/\(widgetExtensionContainerIdentifier)/Data"
        )

        if isWidgetSandboxHome {
            urls.append(homeImageURL)
        }

        if let appGroupContainerURL {
            urls.append(appGroupContainerURL.appendingPathComponent(filename))
            urls.append(appGroupSupportFileURL(appGroupContainerURL: appGroupContainerURL, filename: filename))
        }

        if let accountHomeDirectory,
           shouldAppendAccountHomeGroupContainerMirror(accountHomeDirectory) {
            let accountGroupImageURL = accountHomeDirectory
                .appendingPathComponent("Library")
                .appendingPathComponent("Group Containers")
                .appendingPathComponent(suiteName)
                .appendingPathComponent(filename)
            let widgetSandboxMirrorImageURL = accountHomeDirectory
                .appendingPathComponent("Library")
                .appendingPathComponent("Containers")
                .appendingPathComponent(widgetExtensionContainerIdentifier)
                .appendingPathComponent("Data")
                .appendingPathComponent("Library")
                .appendingPathComponent("Group Containers")
                .appendingPathComponent(suiteName)
                .appendingPathComponent(filename)

            urls.append(accountGroupImageURL)
            urls.append(widgetSandboxMirrorImageURL)
        }

        if let simulatorDataRootGroupImageURL = simulatorDataRootGroupContainerFileURL(
            from: homeDirectory,
            filename: filename
        ) {
            urls.append(simulatorDataRootGroupImageURL)
        }

        if let accountHomeDirectory,
           let simulatorDataRootGroupImageURL = simulatorDataRootGroupContainerFileURL(
            from: accountHomeDirectory,
            filename: filename
           ) {
            urls.append(simulatorDataRootGroupImageURL)
        }

        if shouldAppendHomeGroupContainerMirror(
            platform: .iOS,
            homeDirectory: homeDirectory,
            isWidgetSandboxHome: isWidgetSandboxHome
        ) {
            urls.append(homeImageURL)
        }

        return urls.reduce(into: []) { uniqueURLs, url in
            guard !uniqueURLs.contains(url) else {
                return
            }
            uniqueURLs.append(url)
        }
    }

    private static func appGroupSupportFileURL(appGroupContainerURL: URL, filename: String) -> URL {
        appGroupContainerURL
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent(appGroupSupportDirectoryName)
            .appendingPathComponent(filename)
    }

    private static func shouldAppendHomeGroupContainerMirror(
        platform: WidgetPreferencePlatform,
        homeDirectory: URL,
        isWidgetSandboxHome: Bool
    ) -> Bool {
        if isWidgetSandboxHome {
            return true
        }

        guard platform == .iOS else {
            return true
        }

        return !isIOSAppSandboxHomeDirectory(homeDirectory)
    }

    private static func shouldAppendAccountHomeGroupContainerMirror(_ accountHomeDirectory: URL) -> Bool {
        let path = accountHomeDirectory.standardizedFileURL.path
        return path != "/var/mobile" && path != "/private/var/mobile"
    }

    private static func isIOSAppSandboxHomeDirectory(_ homeDirectory: URL) -> Bool {
        let path = homeDirectory.standardizedFileURL.path
        if path.contains("/Containers/Data/Application/") {
            return true
        }

        return path.contains("/Library/Containers/")
            && path.hasSuffix("/Data")
            && !path.contains("/Library/Containers/\(widgetExtensionContainerIdentifier)/Data")
    }

    public static func widgetWallpaperBackgroundAdjustment(
        platform: WidgetPreferencePlatform
    ) -> WidgetWallpaperBackgroundAdjustment {
        widgetWallpaperBackgroundAdjustment(platform: platform, defaults: defaults)
    }

    public static func widgetWallpaperBackgroundAdjustment(
        platform: WidgetPreferencePlatform,
        defaults: UserDefaults
    ) -> WidgetWallpaperBackgroundAdjustment {
        guard platform == .iOS else {
            return .defaultValue
        }

        return widgetWallpaperBackgroundAdjustment(defaults: defaults)
    }

    public static func widgetWallpaperBackgroundAdjustment(defaults: UserDefaults) -> WidgetWallpaperBackgroundAdjustment {
        WidgetWallpaperBackgroundAdjustment(
            placement: WidgetWallpaperBackgroundPlacement(
                rawValue: defaults.string(forKey: widgetWallpaperPlacementKey) ?? ""
            ) ?? .middle,
            horizontalOffset: defaults.double(forKey: widgetWallpaperHorizontalOffsetKey),
            verticalOffset: defaults.double(forKey: widgetWallpaperVerticalOffsetKey),
            scale: {
                let storedScale = defaults.double(forKey: widgetWallpaperScaleKey)
                return storedScale == 0 ? WidgetWallpaperBackgroundAdjustment.defaultValue.scale : storedScale
            }()
        )
    }

    public static func setWidgetWallpaperBackgroundAdjustment(
        _ adjustment: WidgetWallpaperBackgroundAdjustment,
        platform: WidgetPreferencePlatform
    ) {
        guard platform == .iOS else {
            return
        }

        setWidgetWallpaperBackgroundAdjustment(adjustment, defaults: defaults)
    }

    public static func setWidgetWallpaperBackgroundAdjustment(
        _ adjustment: WidgetWallpaperBackgroundAdjustment,
        defaults: UserDefaults
    ) {
        defaults.set(adjustment.horizontalOffset, forKey: widgetWallpaperHorizontalOffsetKey)
        defaults.set(adjustment.verticalOffset, forKey: widgetWallpaperVerticalOffsetKey)
        defaults.set(adjustment.scale, forKey: widgetWallpaperScaleKey)
        defaults.set(adjustment.placement.rawValue, forKey: widgetWallpaperPlacementKey)
        defaults.synchronize()
    }

    public static func resetWidgetWallpaperBackgroundAdjustment(platform: WidgetPreferencePlatform) {
        guard platform == .iOS else {
            return
        }

        resetWidgetWallpaperBackgroundAdjustment(defaults: defaults)
    }

    public static func resetWidgetWallpaperBackgroundAdjustment(defaults: UserDefaults) {
        defaults.removeObject(forKey: widgetWallpaperHorizontalOffsetKey)
        defaults.removeObject(forKey: widgetWallpaperVerticalOffsetKey)
        defaults.removeObject(forKey: widgetWallpaperScaleKey)
        defaults.removeObject(forKey: widgetWallpaperPlacementKey)
        defaults.synchronize()
    }

    public static func widgetCustomPhotoBackgroundAdjustment(
        platform: WidgetPreferencePlatform
    ) -> WidgetCustomPhotoBackgroundAdjustment {
        widgetWallpaperBackgroundAdjustment(platform: platform)
    }

    public static func widgetCustomPhotoBackgroundAdjustment(
        platform: WidgetPreferencePlatform,
        defaults: UserDefaults
    ) -> WidgetCustomPhotoBackgroundAdjustment {
        widgetWallpaperBackgroundAdjustment(platform: platform, defaults: defaults)
    }

    public static func setWidgetCustomPhotoBackgroundAdjustment(
        _ adjustment: WidgetCustomPhotoBackgroundAdjustment,
        platform: WidgetPreferencePlatform
    ) {
        setWidgetWallpaperBackgroundAdjustment(adjustment, platform: platform)
    }

    public static func setWidgetCustomPhotoBackgroundAdjustment(
        _ adjustment: WidgetCustomPhotoBackgroundAdjustment,
        defaults: UserDefaults
    ) {
        setWidgetWallpaperBackgroundAdjustment(adjustment, defaults: defaults)
    }

    public static func resetWidgetCustomPhotoBackgroundAdjustment(platform: WidgetPreferencePlatform) {
        resetWidgetWallpaperBackgroundAdjustment(platform: platform)
    }

    public static func resetWidgetCustomPhotoBackgroundAdjustment(defaults: UserDefaults) {
        resetWidgetWallpaperBackgroundAdjustment(defaults: defaults)
    }

    public static func widgetWallpaperBackgroundScreenMetrics(
        platform: WidgetPreferencePlatform
    ) -> WidgetWallpaperBackgroundScreenMetrics {
        widgetWallpaperBackgroundScreenMetrics(platform: platform, defaults: defaults)
    }

    public static func widgetWallpaperBackgroundScreenMetrics(
        platform: WidgetPreferencePlatform,
        defaults: UserDefaults
    ) -> WidgetWallpaperBackgroundScreenMetrics {
        guard platform == .iOS else {
            return .defaultValue
        }

        return widgetWallpaperBackgroundScreenMetrics(defaults: defaults)
    }

    public static func widgetWallpaperBackgroundScreenMetrics(defaults: UserDefaults) -> WidgetWallpaperBackgroundScreenMetrics {
        let storedWidth = defaults.double(forKey: widgetWallpaperScreenWidthKey)
        let storedHeight = defaults.double(forKey: widgetWallpaperScreenHeightKey)
        let storedScale = defaults.double(forKey: widgetWallpaperScreenScaleKey)

        guard storedWidth > 0, storedHeight > 0 else {
            return .defaultValue
        }

        return WidgetWallpaperBackgroundScreenMetrics(
            width: storedWidth,
            height: storedHeight,
            scale: storedScale == 0 ? WidgetWallpaperBackgroundScreenMetrics.defaultValue.scale : storedScale
        )
    }

    public static func setWidgetWallpaperBackgroundScreenMetrics(
        _ metrics: WidgetWallpaperBackgroundScreenMetrics,
        platform: WidgetPreferencePlatform
    ) {
        guard platform == .iOS else {
            return
        }

        setWidgetWallpaperBackgroundScreenMetrics(metrics, defaults: defaults)
    }

    public static func setWidgetWallpaperBackgroundScreenMetrics(
        _ metrics: WidgetWallpaperBackgroundScreenMetrics,
        defaults: UserDefaults
    ) {
        defaults.set(metrics.width, forKey: widgetWallpaperScreenWidthKey)
        defaults.set(metrics.height, forKey: widgetWallpaperScreenHeightKey)
        defaults.set(metrics.scale, forKey: widgetWallpaperScreenScaleKey)
        defaults.synchronize()
    }

    public static func widgetCustomPhotoBackgroundScreenMetrics(
        platform: WidgetPreferencePlatform
    ) -> WidgetCustomPhotoBackgroundScreenMetrics {
        widgetWallpaperBackgroundScreenMetrics(platform: platform)
    }

    public static func widgetCustomPhotoBackgroundScreenMetrics(
        platform: WidgetPreferencePlatform,
        defaults: UserDefaults
    ) -> WidgetCustomPhotoBackgroundScreenMetrics {
        widgetWallpaperBackgroundScreenMetrics(platform: platform, defaults: defaults)
    }

    public static func setWidgetCustomPhotoBackgroundScreenMetrics(
        _ metrics: WidgetCustomPhotoBackgroundScreenMetrics,
        platform: WidgetPreferencePlatform
    ) {
        setWidgetWallpaperBackgroundScreenMetrics(metrics, platform: platform)
    }

    public static func setWidgetCustomPhotoBackgroundScreenMetrics(
        _ metrics: WidgetCustomPhotoBackgroundScreenMetrics,
        defaults: UserDefaults
    ) {
        setWidgetWallpaperBackgroundScreenMetrics(metrics, defaults: defaults)
    }

    public static func widgetWallpaperBackgroundRenderRefreshRequired(
        platform: WidgetPreferencePlatform
    ) -> Bool {
        widgetWallpaperBackgroundRenderRefreshRequired(platform: platform, defaults: defaults)
    }

    public static func widgetWallpaperBackgroundRenderRefreshRequired(
        platform: WidgetPreferencePlatform,
        defaults: UserDefaults
    ) -> Bool {
        guard platform == .iOS else {
            return false
        }

        return defaults.integer(forKey: widgetWallpaperBackgroundRenderVersionKey)
            < currentWidgetWallpaperBackgroundRenderVersion
    }

    public static func markWidgetWallpaperBackgroundRenderVersionCurrent(
        platform: WidgetPreferencePlatform
    ) {
        markWidgetWallpaperBackgroundRenderVersionCurrent(platform: platform, defaults: defaults)
    }

    public static func markWidgetWallpaperBackgroundRenderVersionCurrent(
        platform: WidgetPreferencePlatform,
        defaults: UserDefaults
    ) {
        guard platform == .iOS else {
            return
        }

        defaults.set(
            currentWidgetWallpaperBackgroundRenderVersion,
            forKey: widgetWallpaperBackgroundRenderVersionKey
        )
        defaults.synchronize()
    }

    public static func widgetBackgroundRefreshSignature(
        platform: WidgetPreferencePlatform
    ) -> String {
        widgetBackgroundRefreshSignature(platform: platform, defaults: defaults, fileManager: .default)
    }

    public static func widgetBackgroundRefreshSignature(
        platform: WidgetPreferencePlatform,
        defaults: UserDefaults,
        fileManager: FileManager = .default
    ) -> String {
        guard platform == .iOS else {
            return "\(platform.rawValue):widgetBackgroundStatic"
        }

        let style = widgetBackgroundStyle(
            platform: platform,
            defaults: defaults,
            styleFileURLs: widgetBackgroundStyleFileURLs(platform: platform)
        )
        let adjustment = widgetWallpaperBackgroundAdjustment(platform: platform, defaults: defaults)
        let screenMetrics = widgetWallpaperBackgroundScreenMetrics(platform: platform, defaults: defaults)
        let customImageSignature = backgroundImageSignature(
            defaults: defaults,
            dataKey: customBackgroundImageDataKey(for: platform),
            fileURLs: customBackgroundImageURLs(platform: platform, fileManager: fileManager),
            fileManager: fileManager
        )
        let wallpaperImageSignature = backgroundImageSignature(
            defaults: defaults,
            dataKey: wallpaperBackgroundImageDataKey(for: platform),
            fileURLs: wallpaperBackgroundImageURLs(platform: platform, fileManager: fileManager),
            fileManager: fileManager
        )

        return [
            "platform:\(platform.rawValue)",
            "style:\(style.rawValue)",
            "appearance:\(widgetBackgroundAppearanceRefreshComponent(style: style, platform: platform, defaults: defaults))",
            "revision:\(widgetBackgroundRevision(platform: platform, defaults: defaults))",
            "token:\(widgetBackgroundRefreshToken(platform: platform, defaults: defaults))",
            "request:\(widgetBackgroundRefreshRequestID(platform: platform, defaults: defaults))",
            "wallpaperToken:\(widgetWallpaperBackgroundRefreshToken(platform: platform, defaults: defaults))",
            "custom:\(customImageSignature)",
            "wallpaper:\(wallpaperImageSignature)",
            "placement:\(adjustment.placement.rawValue)",
            "x:\(adjustment.horizontalOffset)",
            "y:\(adjustment.verticalOffset)",
            "scale:\(adjustment.scale)",
            "screen:\(screenMetrics.width)x\(screenMetrics.height)@\(screenMetrics.scale)"
        ].joined(separator: "|")
    }

    private static func widgetBackgroundAppearanceRefreshComponent(
        style: WidgetBackgroundStyle,
        platform: WidgetPreferencePlatform,
        defaults: UserDefaults
    ) -> String {
        guard platform == .iOS else {
            return "static"
        }

        switch style {
        case .defaultArtwork:
            return widgetAppearancePreference(platform: platform, defaults: defaults).rawValue
        case .customPhoto, .wallpaperPhoto:
            return "image"
        }
    }

    private static func backgroundImageSignature(
        defaults: UserDefaults,
        dataKey: String,
        fileURLs: [URL],
        fileManager: FileManager = .default
    ) -> String {
        [
            backgroundImageSharedDataSignature(defaults: defaults, dataKey: dataKey),
            "files:\(backgroundImageMetadataSignature(fileURLs: fileURLs, fileManager: fileManager))"
        ].joined(separator: ";")
    }

    private static func backgroundImageSharedDataSignature(defaults: UserDefaults, dataKey: String) -> String {
        guard let data = sharedBackgroundImageData(defaults: defaults, dataKey: dataKey) else {
            return "shared:missing"
        }

        return "shared:sha256:\(sha256Hex(data)):bytes:\(data.count)"
    }

    private static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
    }

    private static func backgroundImageMetadataSignature(
        fileURLs: [URL],
        fileManager: FileManager = .default
    ) -> String {
        let metadata = fileURLs.compactMap { fileURL -> String? in
            guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path) else {
                return nil
            }

            let byteCount = (attributes[.size] as? NSNumber)?.int64Value ?? -1
            let modifiedAt = (attributes[.modificationDate] as? Date)?.timeIntervalSince1970 ?? 0
            return "\(fileURL.lastPathComponent):\(byteCount):\(modifiedAt)"
        }

        return metadata.isEmpty ? "missing" : metadata.joined(separator: ",")
    }

    public static func widgetBackgroundRefreshToken(
        platform: WidgetPreferencePlatform
    ) -> Double {
        widgetBackgroundRefreshToken(platform: platform, defaults: defaults)
    }

    public static func widgetBackgroundRefreshToken(
        platform: WidgetPreferencePlatform,
        defaults: UserDefaults
    ) -> Double {
        guard platform == .iOS else {
            return 0
        }

        return defaults.double(forKey: widgetBackgroundRefreshTokenKey)
    }

    public static func bumpWidgetBackgroundRefreshToken(
        platform: WidgetPreferencePlatform
    ) {
        bumpWidgetBackgroundRefreshToken(platform: platform, defaults: defaults)
    }

    public static func bumpWidgetBackgroundRefreshToken(
        platform: WidgetPreferencePlatform,
        defaults: UserDefaults,
        now: Date = Date()
    ) {
        guard platform == .iOS else {
            return
        }

        defaults.set(now.timeIntervalSince1970, forKey: widgetBackgroundRefreshTokenKey)
        defaults.synchronize()
    }

    public static func widgetBackgroundRefreshRequestID(
        platform: WidgetPreferencePlatform
    ) -> String {
        widgetBackgroundRefreshRequestID(platform: platform, defaults: defaults)
    }

    public static func widgetBackgroundRefreshRequestID(
        platform: WidgetPreferencePlatform,
        defaults: UserDefaults
    ) -> String {
        guard platform == .iOS else {
            return ""
        }

        return defaults.string(forKey: widgetBackgroundRefreshRequestIDKey) ?? ""
    }

    public static func requestWidgetBackgroundRefresh(
        platform: WidgetPreferencePlatform
    ) {
        requestWidgetBackgroundRefresh(platform: platform, defaults: defaults)
    }

    public static func requestWidgetBackgroundRefresh(
        platform: WidgetPreferencePlatform,
        defaults: UserDefaults,
        now: Date = Date(),
        requestID: String = UUID().uuidString
    ) {
        guard platform == .iOS else {
            return
        }

        defaults.set(
            defaults.integer(forKey: widgetBackgroundRevisionKey) + 1,
            forKey: widgetBackgroundRevisionKey
        )
        defaults.set(now.timeIntervalSince1970, forKey: widgetBackgroundRefreshTokenKey)
        defaults.set(requestID, forKey: widgetBackgroundRefreshRequestIDKey)
        defaults.synchronize()
    }

    public static func widgetBackgroundRevision(
        platform: WidgetPreferencePlatform
    ) -> Int {
        widgetBackgroundRevision(platform: platform, defaults: defaults)
    }

    public static func widgetBackgroundRevision(
        platform: WidgetPreferencePlatform,
        defaults: UserDefaults
    ) -> Int {
        guard platform == .iOS else {
            return 0
        }

        return defaults.integer(forKey: widgetBackgroundRevisionKey)
    }

    public static func bumpWidgetBackgroundRevision(
        platform: WidgetPreferencePlatform
    ) {
        bumpWidgetBackgroundRevision(platform: platform, defaults: defaults)
    }

    public static func bumpWidgetBackgroundRevision(
        platform: WidgetPreferencePlatform,
        defaults: UserDefaults
    ) {
        guard platform == .iOS else {
            return
        }

        defaults.set(
            defaults.integer(forKey: widgetBackgroundRevisionKey) + 1,
            forKey: widgetBackgroundRevisionKey
        )
        defaults.synchronize()
    }

    public static func widgetWallpaperBackgroundRefreshToken(
        platform: WidgetPreferencePlatform
    ) -> Double {
        widgetWallpaperBackgroundRefreshToken(platform: platform, defaults: defaults)
    }

    public static func widgetWallpaperBackgroundRefreshToken(
        platform: WidgetPreferencePlatform,
        defaults: UserDefaults
    ) -> Double {
        guard platform == .iOS else {
            return 0
        }

        return defaults.double(forKey: widgetWallpaperBackgroundRefreshTokenKey)
    }

    public static func bumpWidgetWallpaperBackgroundRefreshToken(
        platform: WidgetPreferencePlatform
    ) {
        bumpWidgetWallpaperBackgroundRefreshToken(platform: platform, defaults: defaults)
    }

    public static func bumpWidgetWallpaperBackgroundRefreshToken(
        platform: WidgetPreferencePlatform,
        defaults: UserDefaults,
        now: Date = Date()
    ) {
        guard platform == .iOS else {
            return
        }

        defaults.set(now.timeIntervalSince1970, forKey: widgetWallpaperBackgroundRefreshTokenKey)
        defaults.synchronize()
    }

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: WidgetPlannerPreferenceStore.suiteName) ?? .standard
    }
}

public struct WidgetPlannerSnapshot: Codable, Equatable, Sendable {
    public struct Event: Codable, Equatable, Sendable {
        public let id: UUID
        public let title: String
        public let startDate: Date
        public let endDate: Date?
        public let isAllDay: Bool
        public let notes: String
        public let isCompleted: Bool
        public let completedAt: Date?
        public let reminderOffsetMinutes: Int?
        public let repeatRule: RepeatRule
        public let tagName: String
        public let colorHex: String
        public let createdAt: Date
        public let updatedAt: Date

        public init(event: PlannerEvent) {
            id = event.id
            title = event.title
            startDate = event.startDate
            endDate = event.endDate
            isAllDay = event.isAllDay
            notes = event.notes
            isCompleted = event.isCompleted
            completedAt = event.completedAt
            reminderOffsetMinutes = event.reminderOffsetMinutes
            repeatRule = event.repeatRule
            tagName = event.tagName
            colorHex = event.colorHex
            createdAt = event.createdAt
            updatedAt = event.updatedAt
        }

        public var plannerEvent: PlannerEvent {
            PlannerEvent(
                id: id,
                title: title,
                startDate: startDate,
                endDate: endDate,
                isAllDay: isAllDay,
                notes: notes,
                isCompleted: isCompleted,
                completedAt: completedAt,
                reminderOffsetMinutes: reminderOffsetMinutes,
                repeatRule: repeatRule,
                tagName: tagName,
                colorHex: colorHex,
                createdAt: createdAt,
                updatedAt: updatedAt
            )
        }
    }

    public struct Todo: Codable, Equatable, Sendable {
        public let id: UUID
        public let title: String
        public let notes: String
        public let dueDate: Date?
        public let groupID: UUID?
        public let sortOrder: Int?
        public let isCompleted: Bool
        public let completedAt: Date?
        public let reminderDate: Date?
        public let createdAt: Date
        public let updatedAt: Date

        public init(todo: TodoItem) {
            id = todo.id
            title = todo.title
            notes = todo.notes
            dueDate = todo.dueDate
            groupID = todo.groupID
            sortOrder = todo.sortOrder
            isCompleted = todo.isCompleted
            completedAt = todo.completedAt
            reminderDate = todo.reminderDate
            createdAt = todo.createdAt
            updatedAt = todo.updatedAt
        }

        public var todoItem: TodoItem {
            TodoItem(
                id: id,
                title: title,
                notes: notes,
                dueDate: dueDate,
                groupID: groupID,
                sortOrder: sortOrder,
                isCompleted: isCompleted,
                completedAt: completedAt,
                reminderDate: reminderDate,
                createdAt: createdAt,
                updatedAt: updatedAt
            )
        }
    }

    public let events: [Event]
    public let todos: [Todo]
    public let habitCount: Int
    public let weekStartPreference: WeekStartPreference
    public let showChineseCalendar: Bool
    public let showCompletedSchedules: Bool
    public let completedSchedulesUseStrikethrough: Bool
    public let updatedAt: Date

    public init(
        events: [PlannerEvent],
        todos: [TodoItem],
        habitCount: Int,
        weekStartPreference: WeekStartPreference,
        showChineseCalendar: Bool,
        showCompletedSchedules: Bool = true,
        completedSchedulesUseStrikethrough: Bool = true,
        updatedAt: Date = Date()
    ) {
        self.events = events.map(Event.init)
        self.todos = todos.map(Todo.init)
        self.habitCount = habitCount
        self.weekStartPreference = weekStartPreference
        self.showChineseCalendar = showChineseCalendar
        self.showCompletedSchedules = showCompletedSchedules
        self.completedSchedulesUseStrikethrough = completedSchedulesUseStrikethrough
        self.updatedAt = updatedAt
    }

    public var plannerEvents: [PlannerEvent] {
        events.map(\.plannerEvent)
    }

    public var todoItems: [TodoItem] {
        todos.map(\.todoItem)
    }

    private enum CodingKeys: String, CodingKey {
        case events
        case todos
        case habitCount
        case weekStartPreference
        case showChineseCalendar
        case showCompletedSchedules
        case completedSchedulesUseStrikethrough
        case updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        events = try container.decode([Event].self, forKey: .events)
        todos = try container.decode([Todo].self, forKey: .todos)
        habitCount = try container.decode(Int.self, forKey: .habitCount)
        weekStartPreference = try container.decode(WeekStartPreference.self, forKey: .weekStartPreference)
        showChineseCalendar = try container.decodeIfPresent(Bool.self, forKey: .showChineseCalendar) ?? true
        showCompletedSchedules = try container.decodeIfPresent(Bool.self, forKey: .showCompletedSchedules) ?? true
        completedSchedulesUseStrikethrough = try container.decodeIfPresent(
            Bool.self,
            forKey: .completedSchedulesUseStrikethrough
        ) ?? true
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(events, forKey: .events)
        try container.encode(todos, forKey: .todos)
        try container.encode(habitCount, forKey: .habitCount)
        try container.encode(weekStartPreference, forKey: .weekStartPreference)
        try container.encode(showChineseCalendar, forKey: .showChineseCalendar)
        try container.encode(showCompletedSchedules, forKey: .showCompletedSchedules)
        try container.encode(completedSchedulesUseStrikethrough, forKey: .completedSchedulesUseStrikethrough)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

public struct WidgetWeeklyScheduleDay: Identifiable, Equatable, Sendable {
    public let date: Date
    public let events: [WidgetPlannerSnapshot.Event]

    public var id: Date { date }

    public init(date: Date, events: [WidgetPlannerSnapshot.Event]) {
        self.date = date
        self.events = events
    }
}

public enum WidgetWeeklySchedulePlanner {
    public static func days(
        anchorDate: Date,
        displayRule: WidgetScheduleDisplayRule,
        events: [WidgetPlannerSnapshot.Event],
        weekStartPreference: WeekStartPreference,
        showCompletedSchedules: Bool,
        weekOffset: Int = 0,
        calendar: Calendar = .current
    ) -> [WidgetWeeklyScheduleDay] {
        var workingCalendar = calendar
        workingCalendar.firstWeekday = weekStartPreference.calendarFirstWeekday
        let offsetAnchorDate = workingCalendar.date(
            byAdding: .day,
            value: weekOffset * 7,
            to: anchorDate
        ) ?? anchorDate

        let startDate: Date
        switch displayRule {
        case .nextSevenDays:
            startDate = workingCalendar.startOfDay(for: offsetAnchorDate)
        case .calendarWeek:
            startDate = workingCalendar.dateInterval(of: .weekOfYear, for: offsetAnchorDate)?.start
                ?? workingCalendar.startOfDay(for: offsetAnchorDate)
        }

        let visibleEvents = events
            .filter { showCompletedSchedules || !$0.isCompleted }
            .sorted(by: eventSort)

        return (0..<7).compactMap { offset in
            guard let date = workingCalendar.date(byAdding: .day, value: offset, to: startDate) else {
                return nil
            }

            let dayEvents = visibleEvents.filter { event in
                event.plannerEvent.occurs(on: date, calendar: workingCalendar)
            }

            return WidgetWeeklyScheduleDay(date: date, events: dayEvents)
        }
    }

    private static func eventSort(
        _ lhs: WidgetPlannerSnapshot.Event,
        _ rhs: WidgetPlannerSnapshot.Event
    ) -> Bool {
        if lhs.isCompleted != rhs.isCompleted {
            return !lhs.isCompleted
        }

        if lhs.isAllDay != rhs.isAllDay {
            return lhs.isAllDay
        }

        if lhs.startDate != rhs.startDate {
            return lhs.startDate < rhs.startDate
        }

        return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
    }
}

public enum WidgetPlannerSnapshotStore {
    public static let snapshotKey = "widgetPlannerSnapshot"
    public static let snapshotFilename = "widget-planner-snapshot.json"
    private static let widgetExtensionContainerIdentifier = "com.yuelingqiu.MeowPlanner.MeowPlannerWidget"
    private static let appGroupSupportDirectoryName = "MeowPlannerWidget"

    public static func load() -> WidgetPlannerSnapshot? {
        load(defaults: defaults, fileURLs: snapshotFileURLs)
    }

    public static func loadFromFiles() -> WidgetPlannerSnapshot? {
        load(defaults: defaults, fileURLs: snapshotFileURLs)
    }

    public static func load(defaults: UserDefaults) -> WidgetPlannerSnapshot? {
        load(defaults: defaults, fileURLs: [])
    }

    public static func load(defaults: UserDefaults, fileURL: URL?) -> WidgetPlannerSnapshot? {
        load(defaults: defaults, fileURLs: fileURL.map { [$0] } ?? [])
    }

    public static func load(defaults: UserDefaults, fileURLs: [URL]) -> WidgetPlannerSnapshot? {
        load(
            defaults: defaults,
            fileURLs: fileURLs,
            sharedDefaultsAuthority: sharedDefaultsAreAuthoritative
        )
    }

    static func load(
        defaults: UserDefaults,
        fileURLs: [URL],
        sharedDefaultsAuthority: Bool
    ) -> WidgetPlannerSnapshot? {
        let defaultsSnapshot = loadFromSharedDefaults(defaults: defaults)
        if sharedDefaultsAuthority, let defaultsSnapshot {
            return defaultsSnapshot
        }

        let fileSnapshot = fileURLs
            .compactMap { load(fileURL: $0) }
            .max { $0.updatedAt < $1.updatedAt }

        guard !sharedDefaultsAuthority else {
            if defaultsSnapshot == nil, let fileSnapshot {
                save(fileSnapshot, defaults: defaults, fileURLs: fileURLs)
            }
            return fileSnapshot
        }

        return [defaultsSnapshot, fileSnapshot]
            .compactMap { $0 }
            .max { $0.updatedAt < $1.updatedAt }
    }

    private static var sharedDefaultsAreAuthoritative: Bool {
        #if os(iOS)
        true
        #else
        false
        #endif
    }

    private static func loadFromSharedDefaults(defaults: UserDefaults = defaults) -> WidgetPlannerSnapshot? {
        guard let data = defaults.data(forKey: snapshotKey) else {
            return nil
        }

        return try? JSONDecoder().decode(WidgetPlannerSnapshot.self, from: data)
    }

    private static func load(fileURL: URL) -> WidgetPlannerSnapshot? {
        guard
           let data = try? Data(contentsOf: fileURL),
           let snapshot = try? JSONDecoder().decode(WidgetPlannerSnapshot.self, from: data)
        else {
            return nil
        }

        return snapshot
    }

    public static func save(_ snapshot: WidgetPlannerSnapshot) {
        save(snapshot, defaults: defaults, fileURLs: snapshotFileURLs)
    }

    @discardableResult
    public static func refreshSharedSnapshotForWidgetExtension() -> WidgetPlannerSnapshot? {
        refreshSharedSnapshotForWidgetExtension(
            defaults: defaults,
            standardDefaults: .standard,
            fileURLs: snapshotFileURLs
        )
    }

    @discardableResult
    static func refreshSharedSnapshotForWidgetExtension(
        defaults: UserDefaults,
        standardDefaults: UserDefaults,
        fileURLs: [URL],
        sharedDefaultsAuthority: Bool = sharedDefaultsAreAuthoritative
    ) -> WidgetPlannerSnapshot? {
        guard let snapshot = load(
            defaults: defaults,
            fileURLs: fileURLs,
            sharedDefaultsAuthority: sharedDefaultsAuthority
        ) else {
            return nil
        }

        save(snapshot, defaults: defaults, fileURLs: fileURLs)
        save(snapshot, defaults: standardDefaults, fileURLs: [])
        return snapshot
    }

    public static func save(
        _ snapshot: WidgetPlannerSnapshot,
        defaults: UserDefaults
    ) {
        save(snapshot, defaults: defaults, fileURL: nil)
    }

    public static func save(
        _ snapshot: WidgetPlannerSnapshot,
        defaults: UserDefaults,
        fileURL: URL?
    ) {
        save(snapshot, defaults: defaults, fileURLs: fileURL.map { [$0] } ?? [])
    }

    public static func save(
        _ snapshot: WidgetPlannerSnapshot,
        defaults: UserDefaults,
        fileURLs: [URL]
    ) {
        guard let data = try? JSONEncoder().encode(snapshot) else {
            return
        }

        for fileURL in fileURLs {
            try? FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try? FileManager.default.removeItem(at: fileURL)
            try? data.write(to: fileURL, options: .atomic)
        }

        defaults.set(data, forKey: snapshotKey)
        defaults.synchronize()
    }

    public static func clear() {
        clear(defaults: defaults, fileURLs: snapshotFileURLs)
    }

    public static func clear(defaults: UserDefaults, fileURL: URL?) {
        clear(defaults: defaults, fileURLs: fileURL.map { [$0] } ?? [])
    }

    public static func clear(defaults: UserDefaults, fileURLs: [URL]) {
        for fileURL in fileURLs {
            try? FileManager.default.removeItem(at: fileURL)
        }

        defaults.removeObject(forKey: snapshotKey)
        defaults.synchronize()
    }

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: WidgetPlannerPreferenceStore.suiteName) ?? .standard
    }

    private static var snapshotFileURLs: [URL] {
        snapshotFileURLs(
            appGroupContainerURL: FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: WidgetPlannerPreferenceStore.suiteName
            ),
            homeDirectory: currentHomeDirectory,
            accountHomeDirectory: accountHomeDirectory
        )
    }

    private static var currentHomeDirectory: URL {
        #if os(macOS)
        return FileManager.default.homeDirectoryForCurrentUser
        #else
        if let applicationSupportDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first {
            return applicationSupportDirectory
                .deletingLastPathComponent()
                .deletingLastPathComponent()
        }

        return URL(fileURLWithPath: NSHomeDirectory())
        #endif
    }

    static func snapshotFileURLs(
        appGroupContainerURL: URL?,
        homeDirectory: URL,
        accountHomeDirectory: URL?
    ) -> [URL] {
        var urls: [URL] = []

        let homeSnapshotURL = homeDirectory
            .appendingPathComponent("Library")
            .appendingPathComponent("Group Containers")
            .appendingPathComponent(WidgetPlannerPreferenceStore.suiteName)
            .appendingPathComponent(snapshotFilename)
        let isWidgetSandboxHome = homeDirectory.path.contains(
            "/Library/Containers/\(widgetExtensionContainerIdentifier)/Data"
        )

        if isWidgetSandboxHome {
            urls.append(homeSnapshotURL)
        }

        if let containerURL = appGroupContainerURL {
            urls.append(containerURL.appendingPathComponent(snapshotFilename))
            urls.append(appGroupSupportFileURL(appGroupContainerURL: containerURL))
        }

        if let accountHomeDirectory,
           shouldAppendAccountHomeGroupContainerMirror(accountHomeDirectory) {
            let accountGroupSnapshotURL = accountHomeDirectory
                .appendingPathComponent("Library")
                .appendingPathComponent("Group Containers")
                .appendingPathComponent(WidgetPlannerPreferenceStore.suiteName)
                .appendingPathComponent(snapshotFilename)
            let widgetSandboxMirrorSnapshotURL = accountHomeDirectory
                .appendingPathComponent("Library")
                .appendingPathComponent("Containers")
                .appendingPathComponent(widgetExtensionContainerIdentifier)
                .appendingPathComponent("Data")
                .appendingPathComponent("Library")
                .appendingPathComponent("Group Containers")
                .appendingPathComponent(WidgetPlannerPreferenceStore.suiteName)
                .appendingPathComponent(snapshotFilename)

            urls.append(accountGroupSnapshotURL)
            urls.append(widgetSandboxMirrorSnapshotURL)
        }

        if shouldAppendHomeGroupContainerMirror(
            homeDirectory: homeDirectory,
            isWidgetSandboxHome: isWidgetSandboxHome
        ) {
            urls.append(homeSnapshotURL)
        }

        if accountHomeDirectory == nil, let userHome = NSHomeDirectoryForUser(NSUserName()) {
            urls.append(
                URL(fileURLWithPath: userHome)
                    .appendingPathComponent("Library")
                    .appendingPathComponent("Group Containers")
                    .appendingPathComponent(WidgetPlannerPreferenceStore.suiteName)
                    .appendingPathComponent(snapshotFilename)
            )
        }

        return urls.reduce(into: []) { uniqueURLs, url in
            guard !uniqueURLs.contains(url) else {
                return
            }
            uniqueURLs.append(url)
        }
    }

    private static func appGroupSupportFileURL(appGroupContainerURL: URL) -> URL {
        appGroupContainerURL
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent(appGroupSupportDirectoryName)
            .appendingPathComponent(snapshotFilename)
    }

    private static func shouldAppendHomeGroupContainerMirror(
        homeDirectory: URL,
        isWidgetSandboxHome: Bool
    ) -> Bool {
        if isWidgetSandboxHome {
            return true
        }

        return !isIOSAppSandboxHomeDirectory(homeDirectory)
    }

    private static func shouldAppendAccountHomeGroupContainerMirror(_ accountHomeDirectory: URL) -> Bool {
        let path = accountHomeDirectory.standardizedFileURL.path
        return path != "/var/mobile" && path != "/private/var/mobile"
    }

    private static func isIOSAppSandboxHomeDirectory(_ homeDirectory: URL) -> Bool {
        let path = homeDirectory.standardizedFileURL.path
        if path.contains("/Containers/Data/Application/") {
            return true
        }

        return path.contains("/Library/Containers/com.yuelingqiu.MeowPlanner/Data")
    }

    private static var snapshotFileURL: URL? {
        snapshotFileURLs.first
    }

    private static var accountHomeDirectory: URL? {
        #if canImport(Darwin)
        guard
            let passwd = getpwuid(getuid()),
            let homePath = passwd.pointee.pw_dir
        else {
            return nil
        }
        return URL(fileURLWithPath: String(cString: homePath))
        #else
        return nil
        #endif
    }
}

public enum WidgetPlannerSnapshotBuilder {
    public static func makeSnapshot(using modelContext: ModelContext) throws -> WidgetPlannerSnapshot {
        if modelContext.hasChanges {
            try modelContext.save()
        }

        let events = try modelContext.fetch(
            FetchDescriptor<PlannerEvent>(sortBy: [SortDescriptor(\.startDate)])
        )
        let todos = try modelContext.fetch(
            FetchDescriptor<TodoItem>(sortBy: [SortDescriptor(\.createdAt)])
        )
        let habits = try modelContext.fetch(
            FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.createdAt)])
        )
        let preference = try modelContext.fetch(
            FetchDescriptor<PlannerPreference>()
        ).first ?? PlannerPreference.defaults

        return WidgetPlannerSnapshot(
            events: events,
            todos: todos,
            habitCount: habits.filter { $0.archivedAt == nil }.count,
            weekStartPreference: preference.weekStartPreference,
            showChineseCalendar: preference.showChineseCalendar,
            showCompletedSchedules: preference.showCompletedSchedules,
            completedSchedulesUseStrikethrough: preference.completedSchedulesUseStrikethrough
        )
    }
}

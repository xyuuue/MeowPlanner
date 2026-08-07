import MeowPlannerCore
import AppIntents
import SwiftUI
import WidgetKit

#if os(macOS)
import AppKit
#else
import UIKit
#endif

#if os(iOS)
@available(iOS 17.0, *)
public typealias MeowPlannerTodayConfigurationIntent = MeowPlannerWidgetLocalConfigurationIntent

@available(iOS 17.0, *)
private extension MeowPlannerWidgetScheduleDisplayRule {
    var coreDisplayRule: WidgetScheduleDisplayRule {
        switch self {
        case .nextSevenDays:
            .nextSevenDays
        case .calendarWeek:
            .calendarWeek
        }
    }
}
#else
@available(macOS 14.0, *)
public typealias MeowPlannerTodayConfigurationIntent = MeowPlannerWidgetConfigurationIntent

@available(macOS 14.0, *)
private extension WidgetScheduleDisplayRule {
    var coreDisplayRule: WidgetScheduleDisplayRule {
        self
    }
}
#endif

@available(iOS 17.0, macOS 14.0, *)
public struct MeowPlannerTodayEntry: TimelineEntry {
    public let date: Date
    public let visibleMonthDate: Date
    public let scheduleCount: Int
    public let todoCount: Int
    public let habitCount: Int
    public let showsEmptyState: Bool
    public let monthDays: [MonthPlannerDay]
    public let weekStartPreference: WeekStartPreference
    public let showChineseCalendar: Bool
    public let completedSchedulesUseStrikethrough: Bool
    public let scheduleDisplayRule: WidgetScheduleDisplayRule
    public let weeklyScheduleDays: [WidgetWeeklyScheduleDay]
    public let widgetBackgroundRefreshToken: Double
    public let widgetBackgroundRefreshRequestID: String
    public let widgetBackgroundRefreshSignature: String
    public let widgetContentRefreshSignature: String
    public let widgetBackgroundStyle: WidgetBackgroundStyle
    public let hasWallpaperWidgetBackgroundImage: Bool
    public let hasCustomPhotoWidgetBackgroundImage: Bool
    public let customPhotoWidgetBackgroundImageData: Data?
    public let widgetCustomPhotoBackgroundAdjustment: WidgetCustomPhotoBackgroundAdjustment
    public let widgetCustomPhotoBackgroundScreenMetrics: WidgetCustomPhotoBackgroundScreenMetrics

    public init(
        date: Date,
        visibleMonthDate: Date,
        scheduleCount: Int,
        todoCount: Int,
        habitCount: Int,
        showsEmptyState: Bool = false,
        monthDays: [MonthPlannerDay],
        weekStartPreference: WeekStartPreference,
        showChineseCalendar: Bool = true,
        completedSchedulesUseStrikethrough: Bool = true,
        scheduleDisplayRule: WidgetScheduleDisplayRule = .nextSevenDays,
        weeklyScheduleDays: [WidgetWeeklyScheduleDay] = [],
        widgetBackgroundRefreshToken: Double = 0,
        widgetBackgroundRefreshRequestID: String = "",
        widgetBackgroundRefreshSignature: String = "",
        widgetContentRefreshSignature: String = "",
        widgetBackgroundStyle: WidgetBackgroundStyle = .defaultArtwork,
        hasWallpaperWidgetBackgroundImage: Bool = false,
        hasCustomPhotoWidgetBackgroundImage: Bool = false,
        customPhotoWidgetBackgroundImageData: Data? = nil,
        widgetCustomPhotoBackgroundAdjustment: WidgetCustomPhotoBackgroundAdjustment = .defaultValue,
        widgetCustomPhotoBackgroundScreenMetrics: WidgetCustomPhotoBackgroundScreenMetrics = .defaultValue
    ) {
        self.date = date
        self.visibleMonthDate = visibleMonthDate
        self.scheduleCount = scheduleCount
        self.todoCount = todoCount
        self.habitCount = habitCount
        self.showsEmptyState = showsEmptyState
        self.monthDays = monthDays
        self.weekStartPreference = weekStartPreference
        self.showChineseCalendar = showChineseCalendar
        self.completedSchedulesUseStrikethrough = completedSchedulesUseStrikethrough
        self.scheduleDisplayRule = scheduleDisplayRule
        self.weeklyScheduleDays = weeklyScheduleDays
        self.widgetBackgroundRefreshToken = widgetBackgroundRefreshToken
        self.widgetBackgroundRefreshRequestID = widgetBackgroundRefreshRequestID
        self.widgetBackgroundRefreshSignature = widgetBackgroundRefreshSignature
        self.widgetContentRefreshSignature = widgetContentRefreshSignature
        self.widgetBackgroundStyle = widgetBackgroundStyle
        self.hasWallpaperWidgetBackgroundImage = hasWallpaperWidgetBackgroundImage
        self.hasCustomPhotoWidgetBackgroundImage = hasCustomPhotoWidgetBackgroundImage
        self.customPhotoWidgetBackgroundImageData = customPhotoWidgetBackgroundImageData
        self.widgetCustomPhotoBackgroundAdjustment = widgetCustomPhotoBackgroundAdjustment
        self.widgetCustomPhotoBackgroundScreenMetrics = widgetCustomPhotoBackgroundScreenMetrics
    }
}

#if os(iOS)
@available(iOS 17.0, *)
private extension MeowPlannerTodayEntry {
    var customPhotoWidgetBackgroundImage: UIImage? {
        guard let customPhotoWidgetBackgroundImageData else {
            return nil
        }

        return UIImage(data: customPhotoWidgetBackgroundImageData)
    }
}
#endif

@available(iOS 17.0, macOS 14.0, *)
public struct MeowPlannerTodayProvider: AppIntentTimelineProvider {
    public init() {}

    public func placeholder(in context: Context) -> MeowPlannerTodayEntry {
        makeEntry(date: Date(), snapshot: nil, configuration: MeowPlannerTodayConfigurationIntent(), includeSamplePlans: true)
    }

    public func snapshot(
        for configuration: MeowPlannerTodayConfigurationIntent,
        in context: Context
    ) async -> MeowPlannerTodayEntry {
        let snapshot = Self.currentSnapshot()
        let shouldUseSample = context.isPreview && snapshot == nil
        return makeEntry(
            date: Date(),
            snapshot: snapshot,
            configuration: configuration,
            includeSamplePlans: shouldUseSample
        )
    }

    public func timeline(
        for configuration: MeowPlannerTodayConfigurationIntent,
        in context: Context
    ) async -> Timeline<MeowPlannerTodayEntry> {
        let snapshot = Self.currentSnapshot()
        let entry = makeEntry(date: Date(), snapshot: snapshot, configuration: configuration)
        return Timeline(entries: [entry], policy: .after(Self.nextRefreshDate(after: entry.date)))
    }

    static func currentSnapshot() -> WidgetPlannerSnapshot? {
        WidgetPlannerSnapshotStore.loadFromFiles()
    }

    private func makeEntry(
        date: Date,
        snapshot: WidgetPlannerSnapshot?,
        configuration: MeowPlannerTodayConfigurationIntent,
        includeSamplePlans: Bool = false
    ) -> MeowPlannerTodayEntry {
        let weekStartPreference = includeSamplePlans ? .sunday : (snapshot?.weekStartPreference ?? .sunday)
        let scheduleDisplayRule = configuration.scheduleDisplayRule.coreDisplayRule
        let calendar = weekStartPreference.configuredCalendar
        let monthOffset = includeSamplePlans ? 0 : WidgetMonthSelectionStore.currentMonthOffset
        let weekOffset = includeSamplePlans ? 0 : WidgetWeekSelectionStore.currentWeekOffset
        let visibleMonthDate = calendar.date(
            byAdding: .month,
            value: monthOffset,
            to: date
        ) ?? date
        let allEvents = includeSamplePlans ? sampleEvents(anchor: visibleMonthDate) : (snapshot?.plannerEvents ?? [])
        let showCompletedSchedules = includeSamplePlans ? true : (snapshot?.showCompletedSchedules ?? true)
        let events = allEvents.filter { showCompletedSchedules || !$0.isCompleted }
        let todos = includeSamplePlans ? [] : (snapshot?.todoItems ?? [])
        let monthDays = MonthPlannerGridBuilder.days(
            for: visibleMonthDate,
            events: events,
            todos: todos,
            maxVisibleItems: 2,
            calendar: calendar
        )
        let weeklyScheduleDays = WidgetWeeklySchedulePlanner.days(
            anchorDate: date,
            displayRule: scheduleDisplayRule,
            events: allEvents.map(WidgetPlannerSnapshot.Event.init(event:)),
            weekStartPreference: weekStartPreference,
            showCompletedSchedules: showCompletedSchedules,
            weekOffset: weekOffset,
            calendar: calendar
        )
        let hasWallpaperWidgetBackgroundImage = WidgetBackgroundImageLoader.wallpaperBackgroundImage() != nil
        let customPhotoWidgetBackgroundImageData = WidgetPlannerPreferenceStore.customBackgroundImageData(platform: .current)
        #if os(iOS)
        let hasCustomPhotoWidgetBackgroundImage = customPhotoWidgetBackgroundImageData.flatMap { UIImage(data: $0) } != nil
        #else
        let hasCustomPhotoWidgetBackgroundImage = WidgetBackgroundImageLoader.customBackgroundImage() != nil
        #endif
        let widgetBackgroundRefreshSignature = WidgetPlannerPreferenceStore.widgetBackgroundRefreshSignature(platform: .current)
        let widgetContentRefreshSignature = [
            "background:\(widgetBackgroundRefreshSignature)",
            "snapshot:\(snapshot?.updatedAt.timeIntervalSinceReferenceDate ?? 0)",
            "weekOffset:\(weekOffset)",
            "monthOffset:\(monthOffset)",
            "scheduleRule:\(scheduleDisplayRule.rawValue)"
        ].joined(separator: "|")
        let widgetBackgroundStyle = Self.iOSSupportedWidgetBackgroundStyle(
            WidgetPlannerPreferenceStore.widgetBackgroundStyle(platform: .current)
        )
            .fallbackIfImageUnavailable(
                hasCustomPhotoImage: hasCustomPhotoWidgetBackgroundImage,
                hasWallpaperPhotoImage: hasWallpaperWidgetBackgroundImage
            )

        return MeowPlannerTodayEntry(
            date: date,
            visibleMonthDate: visibleMonthDate,
            scheduleCount: events.count,
            todoCount: todos.count,
            habitCount: includeSamplePlans ? 1 : (snapshot?.habitCount ?? 0),
            showsEmptyState: snapshot == nil && !includeSamplePlans,
            monthDays: monthDays,
            weekStartPreference: weekStartPreference,
            showChineseCalendar: includeSamplePlans ? true : (snapshot?.showChineseCalendar ?? true),
            completedSchedulesUseStrikethrough: includeSamplePlans ? true : (snapshot?.completedSchedulesUseStrikethrough ?? true),
            scheduleDisplayRule: scheduleDisplayRule,
            weeklyScheduleDays: weeklyScheduleDays,
            widgetBackgroundRefreshToken: WidgetPlannerPreferenceStore.widgetBackgroundRefreshToken(platform: .current),
            widgetBackgroundRefreshRequestID: WidgetPlannerPreferenceStore.widgetBackgroundRefreshRequestID(platform: .current),
            widgetBackgroundRefreshSignature: widgetBackgroundRefreshSignature,
            widgetContentRefreshSignature: widgetContentRefreshSignature,
            widgetBackgroundStyle: widgetBackgroundStyle,
            hasWallpaperWidgetBackgroundImage: hasWallpaperWidgetBackgroundImage,
            hasCustomPhotoWidgetBackgroundImage: hasCustomPhotoWidgetBackgroundImage,
            customPhotoWidgetBackgroundImageData: customPhotoWidgetBackgroundImageData,
            widgetCustomPhotoBackgroundAdjustment: WidgetPlannerPreferenceStore.widgetCustomPhotoBackgroundAdjustment(platform: .current),
            widgetCustomPhotoBackgroundScreenMetrics: WidgetPlannerPreferenceStore.widgetCustomPhotoBackgroundScreenMetrics(platform: .current)
        )
    }

    private static func iOSSupportedWidgetBackgroundStyle(_ style: WidgetBackgroundStyle) -> WidgetBackgroundStyle {
        #if os(iOS)
        switch style {
        case .customPhoto:
            return .customPhoto
        default:
            return .defaultArtwork
        }
        #else
        return style
        #endif
    }

    private static func nextRefreshDate(after date: Date, calendar: Calendar = .current) -> Date {
        let shortRefreshDate = date.addingTimeInterval(60)
        let nextMidnightRefreshDate = calendar.nextDate(
            after: date,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) ?? calendar.date(byAdding: .hour, value: 1, to: date) ?? date.addingTimeInterval(3600)
        return min(shortRefreshDate, nextMidnightRefreshDate)
    }

    private func sampleEvents(anchor: Date) -> [PlannerEvent] {
        let calendar = Calendar.current
        let monthStart = calendar.dateInterval(of: .month, for: anchor)?.start ?? anchor
        let sampleDays = [3, 10, 17, 24]

        return sampleDays.compactMap { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: dayOffset - 1, to: monthStart) else {
                return nil
            }
            return PlannerEvent(title: "Nail Repair", startDate: date)
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
public struct MeowPlannerTodayWidget: Widget {
    public let kind = WidgetConstants.todayKind

    private static var supportedFamilies: [WidgetFamily] {
        #if os(iOS)
        return [.systemSmall, .systemMedium, .systemLarge]
        #else
        return [.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge]
        #endif
    }

    public init() {}

    public var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: MeowPlannerTodayConfigurationIntent.self, provider: MeowPlannerTodayProvider()) { entry in
            MeowPlannerTodayWidgetView(entry: entry)
        }
        .configurationDisplayName("MeowPlanner")
        .description("See FuFu's schedules and plans.")
        .supportedFamilies(Self.supportedFamilies)
        .contentMarginsDisabled()
        #if os(iOS)
        .containerBackgroundRemovable(false)
        #else
        .containerBackgroundRemovable(false)
        #endif
    }
}

@available(iOS 17.0, macOS 14.0, *)
private struct MeowPlannerTodayWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: MeowPlannerTodayEntry

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                #if os(iOS)
                WeeklyScheduleWidgetView(entry: entry)
                #else
                SummaryWidgetView(entry: entry)
                #endif
            case .systemLarge, .systemExtraLarge:
                MonthWidgetView(entry: entry, family: family)
            default:
                SummaryWidgetView(entry: entry)
            }
        }
        .meowPlannerWidgetContainerBackground(entry: entry)
        #if os(iOS)
        .id(entry.widgetContentRefreshSignature)
        #endif
    }
}

@available(iOS 17.0, macOS 14.0, *)
private extension View {
    func meowPlannerWidgetContainerBackground(entry: MeowPlannerTodayEntry) -> some View {
        containerBackground(for: .widget) {
            WidgetContainerBackgroundView(entry: entry)
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
@ViewBuilder
private func widgetFullColorImage(_ image: Image) -> some View {
    if #available(iOS 18.0, macOS 15.0, *) {
        image.widgetAccentedRenderingMode(.fullColor)
    } else {
        image
    }
}

@available(iOS 17.0, macOS 14.0, *)
private struct WidgetWallpaperBackgroundImageView: View {
    #if os(iOS)
    var image: UIImage
    #else
    var image: Image
    #endif

    var body: some View {
        GeometryReader { proxy in
            let adjustment = WidgetPlannerPreferenceStore.widgetWallpaperBackgroundAdjustment
            let screenMetrics = WidgetPlannerPreferenceStore.widgetWallpaperBackgroundScreenMetrics
            let widgetSize = CGSize(
                width: max(1, proxy.size.width),
                height: max(1, proxy.size.height)
            )
            let screenSize = CGSize(
                width: max(proxy.size.width, CGFloat(screenMetrics.width)),
                height: max(proxy.size.height, CGFloat(screenMetrics.height))
            )
            let widgetOrigin = WidgetWallpaperBackgroundLayout.mediumWidgetOrigin(
                screenMetrics: WidgetWallpaperBackgroundScreenMetrics(
                    width: Double(screenSize.width),
                    height: Double(screenSize.height),
                    scale: screenMetrics.scale
                ),
                widgetSize: WidgetWallpaperBackgroundWidgetSize(
                    width: Double(proxy.size.width),
                    height: Double(proxy.size.height)
                ),
                adjustment: adjustment
            )
            let adjustmentScale = CGFloat(adjustment.scale)

            #if os(iOS)
            widgetFullColorImage(
                Image(uiImage: renderedWidgetImage(
                    widgetSize: widgetSize,
                    screenSize: screenSize,
                    screenMetrics: screenMetrics,
                    widgetOrigin: widgetOrigin,
                    adjustmentScale: adjustmentScale
                ))
                .resizable()
            )
            .frame(width: widgetSize.width, height: widgetSize.height)
            #else
            widgetFullColorImage(image.resizable())
                .frame(width: screenSize.width, height: screenSize.height)
                .scaleEffect(adjustmentScale, anchor: .topLeading)
                .offset(
                    x: -CGFloat(widgetOrigin.x) * adjustmentScale,
                    y: -CGFloat(widgetOrigin.y) * adjustmentScale
                )
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
            #endif
        }
    }

    #if os(iOS)
    private func renderedWidgetImage(
        widgetSize: CGSize,
        screenSize: CGSize,
        screenMetrics: WidgetWallpaperBackgroundScreenMetrics,
        widgetOrigin: WidgetWallpaperBackgroundOrigin,
        adjustmentScale: CGFloat
    ) -> UIImage {
        let rendererFormat = UIGraphicsImageRendererFormat()
        rendererFormat.scale = CGFloat(screenMetrics.scale)
        rendererFormat.opaque = false

        let renderer = UIGraphicsImageRenderer(size: widgetSize, format: rendererFormat)
        return renderer.image { _ in
            image.draw(in: CGRect(
                x: -CGFloat(widgetOrigin.x) * adjustmentScale,
                y: -CGFloat(widgetOrigin.y) * adjustmentScale,
                width: screenSize.width * adjustmentScale,
                height: screenSize.height * adjustmentScale
            ))
        }
    }
    #endif
}

#if os(iOS)
@available(iOS 17.0, *)
private struct WidgetCustomPhotoBackgroundImageView: View {
    var image: UIImage
    var adjustment: WidgetCustomPhotoBackgroundAdjustment
    var screenMetrics: WidgetCustomPhotoBackgroundScreenMetrics

    var body: some View {
        GeometryReader { proxy in
            let widgetSize = CGSize(
                width: max(1, proxy.size.width),
                height: max(1, proxy.size.height)
            )
            let screenSize = CGSize(
                width: max(proxy.size.width, CGFloat(screenMetrics.width)),
                height: max(proxy.size.height, CGFloat(screenMetrics.height))
            )
            let widgetOrigin = WidgetCustomPhotoBackgroundLayout.widgetOrigin(
                screenMetrics: WidgetCustomPhotoBackgroundScreenMetrics(
                    width: Double(screenSize.width),
                    height: Double(screenSize.height),
                    scale: screenMetrics.scale
                ),
                widgetSize: WidgetCustomPhotoBackgroundWidgetSize(
                    width: Double(proxy.size.width),
                    height: Double(proxy.size.height)
                ),
                adjustment: adjustment
            )
            let adjustmentScale = CGFloat(adjustment.scale)

            widgetFullColorImage(
                Image(uiImage: renderedWidgetImage(
                    widgetSize: widgetSize,
                    screenSize: screenSize,
                    screenMetrics: screenMetrics,
                    widgetOrigin: widgetOrigin,
                    adjustmentScale: adjustmentScale
                ))
                .resizable()
            )
            .frame(width: widgetSize.width, height: widgetSize.height)
        }
    }

    private func renderedWidgetImage(
        widgetSize: CGSize,
        screenSize: CGSize,
        screenMetrics: WidgetCustomPhotoBackgroundScreenMetrics,
        widgetOrigin: WidgetCustomPhotoBackgroundOrigin,
        adjustmentScale: CGFloat
    ) -> UIImage {
        let rendererFormat = UIGraphicsImageRendererFormat()
        rendererFormat.scale = CGFloat(screenMetrics.scale)
        rendererFormat.opaque = true

        let renderer = UIGraphicsImageRenderer(size: widgetSize, format: rendererFormat)
        return renderer.image { _ in
            image.draw(in: CGRect(
                x: -CGFloat(widgetOrigin.x) * adjustmentScale,
                y: -CGFloat(widgetOrigin.y) * adjustmentScale,
                width: screenSize.width * adjustmentScale,
                height: screenSize.height * adjustmentScale
            ))
        }
    }
}
#endif

@available(iOS 17.0, macOS 14.0, *)
private struct WidgetContainerBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.showsWidgetContainerBackground) private var showsWidgetContainerBackground

    var entry: MeowPlannerTodayEntry

    var body: some View {
        if shouldHideMeowPlannerBackground {
            Color.clear
        } else {
            switch entry.widgetBackgroundStyle {
            case .defaultArtwork:
                defaultBackground
            case .customPhoto:
                #if os(iOS)
                if entry.hasCustomPhotoWidgetBackgroundImage,
                   let image = entry.customPhotoWidgetBackgroundImage {
                    WidgetCustomPhotoBackgroundImageView(
                        image: image,
                        adjustment: entry.widgetCustomPhotoBackgroundAdjustment,
                        screenMetrics: entry.widgetCustomPhotoBackgroundScreenMetrics
                    )
                } else {
                    defaultBackground
                }
                #else
                if entry.hasCustomPhotoWidgetBackgroundImage,
                   let image = WidgetBackgroundImageLoader.customBackgroundImage() {
                    widgetFullColorImage(
                        Image(nsImage: image)
                            .resizable()
                    )
                        .scaledToFill()
                } else {
                    defaultBackground
                }
                #endif
            case .wallpaperPhoto:
                if entry.hasWallpaperWidgetBackgroundImage,
                   let image = WidgetBackgroundImageLoader.wallpaperBackgroundImage() {
                    #if os(iOS)
                    WidgetWallpaperBackgroundImageView(image: image)
                    #else
                    defaultBackground
                    #endif
                } else {
                    defaultBackground
                }
            }
        }
    }

    private var shouldHideMeowPlannerBackground: Bool {
        #if os(iOS)
        return !showsWidgetContainerBackground
            && entry.widgetBackgroundStyle != .wallpaperPhoto
            && entry.widgetBackgroundStyle != .customPhoto
        #else
        !showsWidgetContainerBackground && entry.widgetBackgroundStyle != .wallpaperPhoto
        #endif
    }

    private var defaultBackground: some View {
        #if os(macOS)
        macOSSystemWidgetBackground
        #else
        defaultGradient
        #endif
    }

    #if os(macOS)
    private var macOSWidgetBackgroundIsDark: Bool {
        WidgetPlannerPreferenceStore.isDarkWidgetAppearance(systemIsDark: colorScheme == .dark)
    }

    private var macOSSystemWidgetBackground: some View {
        ZStack {
            Rectangle()
                .fill(.regularMaterial)

            WidgetPalette.macOSGlassBackgroundOverlay(isDark: macOSWidgetBackgroundIsDark)

            WidgetPalette.macOSGlassBackgroundWash(isDark: macOSWidgetBackgroundIsDark)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(WidgetPalette.macOSGlassBackgroundBorder(isDark: macOSWidgetBackgroundIsDark), lineWidth: 1)
        }
    }
    #endif

    private var defaultGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.94, blue: 0.86),
                Color(red: 0.93, green: 0.97, blue: 0.98)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

@available(iOS 17.0, macOS 14.0, *)
private struct WeeklyScheduleWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.showsWidgetContainerBackground) private var showsWidgetContainerBackground

    var entry: MeowPlannerTodayEntry

    private let cardCornerRadius: CGFloat = 26

    private var isDarkBackground: Bool {
        WidgetPlannerPreferenceStore.isDarkWidgetAppearance(
            systemIsDark: colorScheme == .dark,
            backgroundStyle: entry.widgetBackgroundStyle
        )
    }

    private var customWidgetTextColor: Color? {
        #if os(iOS)
        WidgetPalette.widgetTextColor(hex: WidgetPlannerPreferenceStore.widgetTextColorHex(platform: .iOS))
        #else
        nil
        #endif
    }

    private var weeklyScheduleCardFill: Color {
        if usesWallpaperWidgetBackground {
            return WidgetPalette.weeklyWallpaperCardFill
        }

        if usesCustomPhotoWidgetBackground {
            return WidgetPalette.weeklyCustomPhotoCardFill
        }

        return usesLiveTransparentWidgetBackground
            ? WidgetPalette.weeklyLiveTransparentCardFill
            : WidgetPalette.weeklyGlassFill(isDark: isDarkBackground)
    }

    private var weeklyScheduleCardStroke: Color {
        if usesWallpaperWidgetBackground {
            return WidgetPalette.weeklyWallpaperSeparator
        }

        if usesCustomPhotoWidgetBackground {
            return WidgetPalette.weeklyCustomPhotoSeparator
        }

        return usesLiveTransparentWidgetBackground
            ? WidgetPalette.weeklyLiveTransparentSeparator
            : WidgetPalette.weeklyGlassStroke(isDark: isDarkBackground)
    }

    private var primaryTextColor: Color {
        if let customWidgetTextColor {
            return customWidgetTextColor
        }

        if usesWallpaperWidgetBackground {
            return WidgetPalette.weeklyWallpaperPrimaryText
        }

        if usesCustomPhotoWidgetBackground {
            return WidgetPalette.weeklyCustomPhotoPrimaryText
        }

        if usesLiveTransparentWidgetBackground {
            return WidgetPalette.weeklyLiveTransparentPrimaryText
        }

        return WidgetPalette.weeklyPrimaryText(isDark: isDarkBackground)
    }

    private var secondaryTextColor: Color {
        if let customWidgetTextColor {
            return WidgetPalette.secondaryWidgetTextColor(from: customWidgetTextColor)
        }

        if usesWallpaperWidgetBackground {
            return WidgetPalette.weeklyWallpaperSecondaryText
        }

        if usesCustomPhotoWidgetBackground {
            return WidgetPalette.weeklyCustomPhotoSecondaryText
        }

        if usesLiveTransparentWidgetBackground {
            return WidgetPalette.weeklyLiveTransparentSecondaryText
        }

        return WidgetPalette.weeklySecondaryText(isDark: isDarkBackground)
    }

    private var separatorColor: Color {
        if usesWallpaperWidgetBackground {
            return WidgetPalette.weeklyWallpaperSeparator
        }

        if usesCustomPhotoWidgetBackground {
            return WidgetPalette.weeklyCustomPhotoSeparator
        }

        return usesLiveTransparentWidgetBackground
            ? WidgetPalette.weeklyLiveTransparentSeparator
            : WidgetPalette.weeklySeparator(isDark: isDarkBackground)
    }

    private var usesTransparentWidgetBackground: Bool {
        usesSeeThroughWidgetBackground
    }

    private var usesSeeThroughWidgetBackground: Bool {
        usesLiveTransparentWidgetBackground || usesWallpaperWidgetBackground || usesCustomPhotoWidgetBackground
    }

    private var usesLiveTransparentWidgetBackground: Bool {
        #if os(iOS)
        return !showsWidgetContainerBackground
            && entry.widgetBackgroundStyle != .wallpaperPhoto
            && entry.widgetBackgroundStyle != .customPhoto
        #else
        !showsWidgetContainerBackground && entry.widgetBackgroundStyle != .wallpaperPhoto
        #endif
    }

    private var usesWallpaperWidgetBackground: Bool {
        entry.widgetBackgroundStyle == .wallpaperPhoto
    }

    private var usesCustomPhotoWidgetBackground: Bool {
        #if os(iOS)
        entry.widgetBackgroundStyle == .customPhoto
        #else
        false
        #endif
    }

    private var hasSchedules: Bool {
        entry.weeklyScheduleDays.contains { !$0.events.isEmpty }
    }

    private var calendar: Calendar {
        entry.weekStartPreference.configuredCalendar
    }

    private var monthTitle: String {
        guard let firstDate = entry.weeklyScheduleDays.first?.date else {
            return entry.date.formatted(.dateTime.month(.wide))
        }

        let firstMonth = calendar.component(.month, from: firstDate)
        guard let lastDate = entry.weeklyScheduleDays.last?.date else {
            return "\(firstMonth)月"
        }

        let lastMonth = calendar.component(.month, from: lastDate)
        return firstMonth == lastMonth ? "\(firstMonth)月" : "\(firstMonth)-\(lastMonth)月"
    }

    var body: some View {
        ZStack {
            WidgetScheduleBackgroundView(entry: entry)

            VStack(spacing: 0) {
                header
                    .frame(height: 28)

                weekdayStrip
                    .frame(height: 18)

                calendarColumns
                    .overlay(alignment: .bottom) {
                        if !hasSchedules && !usesTransparentWidgetBackground {
                            Text("No schedules this week")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundStyle(secondaryTextColor)
                                .lineLimit(1)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(WidgetPalette.weeklyBadgeFill(isDark: isDarkBackground), in: Capsule())
                                .padding(.bottom, 4)
                        }
                    }
            }
            .background(weeklyScheduleCardFill, in: RoundedRectangle(cornerRadius: cardCornerRadius))
            .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cardCornerRadius)
                    .stroke(weeklyScheduleCardStroke, lineWidth: 1)
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
        }
        .clipped()
    }

    private var header: some View {
        HStack(spacing: 5) {
            weekNavigationButton(delta: -1, systemImage: "chevron.left")

            Link(destination: WidgetConstants.appLaunchURL) {
                Text(monthTitle)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(primaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(minWidth: 31, alignment: .center)
            }
            .buttonStyle(.plain)

            weekNavigationButton(delta: 1, systemImage: "chevron.right")

            Spacer(minLength: 4)

            #if os(iOS)
            Button(intent: ReturnWidgetToTodayIntent()) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 22, height: 22)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(primaryTextColor)
            .accessibilityLabel("回到今日并刷新小组件")
            #endif
        }
        .padding(.horizontal, 9)
    }

    private func weekNavigationButton(delta: Int, systemImage: String) -> some View {
        Button(intent: ChangeWidgetWeekIntent(weekDelta: delta)) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 22, height: 22)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(primaryTextColor)
    }

    private var weekdayStrip: some View {
        HStack(spacing: 0) {
            ForEach(entry.weeklyScheduleDays) { day in
                Text(weekdayText(for: day.date))
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(weekdayColor(for: day.date))
                    .frame(maxWidth: .infinity)
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(separatorColor)
                .frame(height: 1)
        }
    }

    private var calendarColumns: some View {
        HStack(spacing: 0) {
            ForEach(entry.weeklyScheduleDays) { day in
                WeeklyScheduleCalendarDayColumn(
                    entry: entry,
                    day: day,
                    calendar: calendar,
                    usesTransparentBackground: usesTransparentWidgetBackground,
                    usesWallpaperBackground: usesWallpaperWidgetBackground,
                    usesCustomPhotoBackground: usesCustomPhotoWidgetBackground,
                    backgroundStyle: entry.widgetBackgroundStyle,
                    customWidgetTextColor: customWidgetTextColor
                )
                .overlay(alignment: .trailing) {
                    Rectangle()
                        .fill(separatorColor)
                        .frame(width: 1)
                }
            }
        }
    }

    private func weekdayText(for date: Date) -> String {
        let symbols = ["日", "一", "二", "三", "四", "五", "六"]
        let index = max(1, min(7, calendar.component(.weekday, from: date))) - 1
        return symbols[index]
    }

    private func weekdayColor(for date: Date) -> Color {
        let weekday = calendar.component(.weekday, from: date)
        if weekday == 1 || weekday == 7 {
            return primaryTextColor
        }

        return secondaryTextColor
    }
}

@available(iOS 17.0, macOS 14.0, *)
private struct WidgetContentBackgroundView: View {
    var entry: MeowPlannerTodayEntry

    var body: some View {
        GeometryReader { proxy in
            contentBackground
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        #if os(iOS)
        .id(entry.widgetBackgroundRefreshSignature)
        #endif
    }

    @ViewBuilder
    private var contentBackground: some View {
        #if os(iOS)
        switch entry.widgetBackgroundStyle {
        case .wallpaperPhoto:
            if entry.hasWallpaperWidgetBackgroundImage,
               let image = WidgetBackgroundImageLoader.wallpaperBackgroundImage() {
                WidgetWallpaperBackgroundImageView(image: image)
            } else {
                Color.clear
            }
        case .customPhoto:
            if entry.hasCustomPhotoWidgetBackgroundImage,
               let image = entry.customPhotoWidgetBackgroundImage {
                WidgetCustomPhotoBackgroundImageView(
                    image: image,
                    adjustment: entry.widgetCustomPhotoBackgroundAdjustment,
                    screenMetrics: entry.widgetCustomPhotoBackgroundScreenMetrics
                )
            } else {
                Color.clear
            }
        case .defaultArtwork:
            Color.clear
        }
        #else
        Color.clear
        #endif
    }
}

@available(iOS 17.0, macOS 14.0, *)
private struct WidgetScheduleBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.showsWidgetContainerBackground) private var showsWidgetContainerBackground

    var entry: MeowPlannerTodayEntry

    private var isDarkBackground: Bool {
        WidgetPlannerPreferenceStore.isDarkWidgetAppearance(
            systemIsDark: colorScheme == .dark,
            backgroundStyle: entry.widgetBackgroundStyle
        )
    }

    var body: some View {
        GeometryReader { proxy in
            Group {
                if shouldHideMeowPlannerBackground {
                    Color.clear
                } else if entry.widgetBackgroundStyle == .wallpaperPhoto {
                    #if os(iOS)
                    if entry.hasWallpaperWidgetBackgroundImage,
                       let image = WidgetBackgroundImageLoader.wallpaperBackgroundImage() {
                        WidgetWallpaperBackgroundImageView(image: image)
                    } else {
                        WidgetPalette.weeklyFallbackBackground(isDark: isDarkBackground)
                    }
                    #else
                    WidgetPalette.weeklyFallbackBackground(isDark: isDarkBackground)
                    #endif
                } else if entry.widgetBackgroundStyle == .customPhoto {
                    #if os(iOS)
                    if entry.hasCustomPhotoWidgetBackgroundImage,
                       let image = entry.customPhotoWidgetBackgroundImage {
                        WidgetCustomPhotoBackgroundImageView(
                            image: image,
                            adjustment: entry.widgetCustomPhotoBackgroundAdjustment,
                            screenMetrics: entry.widgetCustomPhotoBackgroundScreenMetrics
                        )
                    } else {
                        WidgetPalette.weeklyFallbackBackground(isDark: isDarkBackground)
                    }
                    #else
                    WidgetPalette.weeklyFallbackBackground(isDark: isDarkBackground)
                    #endif
                } else if let image = WidgetBackgroundImageLoader.image(
                    style: entry.widgetBackgroundStyle,
                    isDark: isDarkBackground
                ) {
                    #if os(iOS)
                    widgetFullColorImage(
                        Image(uiImage: image)
                            .resizable()
                    )
                        .scaledToFill()
                    #else
                    widgetFullColorImage(
                        Image(nsImage: image)
                            .resizable()
                    )
                        .scaledToFill()
                    #endif
                } else {
                    WidgetPalette.weeklyFallbackBackground(isDark: isDarkBackground)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        #if os(iOS)
        .id(entry.widgetBackgroundRefreshSignature)
        #endif
    }

    private var shouldHideMeowPlannerBackground: Bool {
        #if os(iOS)
        return !showsWidgetContainerBackground
            && entry.widgetBackgroundStyle != .wallpaperPhoto
            && entry.widgetBackgroundStyle != .customPhoto
        #else
        !showsWidgetContainerBackground && entry.widgetBackgroundStyle != .wallpaperPhoto
        #endif
    }

}

@available(iOS 17.0, macOS 14.0, *)
private struct WeeklyScheduleCalendarDayColumn: View {
    @Environment(\.colorScheme) private var colorScheme

    var entry: MeowPlannerTodayEntry
    var day: WidgetWeeklyScheduleDay
    var calendar: Calendar
    var usesTransparentBackground: Bool
    var usesWallpaperBackground: Bool
    var usesCustomPhotoBackground: Bool
    var backgroundStyle: WidgetBackgroundStyle
    var customWidgetTextColor: Color?

    private let eventTextSize: CGFloat = 8
    private let eventRowHeight: CGFloat = 16
    private let eventRowSpacing: CGFloat = 3
    private let dayHeaderHeight: CGFloat = 19
    private let headerToEventsSpacing: CGFloat = 5
    private let columnTopPadding: CGFloat = 6
    private let columnHorizontalPadding: CGFloat = 4
    private let columnBottomInset: CGFloat = 6

    private var isDarkBackground: Bool {
        WidgetPlannerPreferenceStore.isDarkWidgetAppearance(
            systemIsDark: colorScheme == .dark,
            backgroundStyle: backgroundStyle
        )
    }

    private var primaryTextColor: Color {
        if let customWidgetTextColor {
            return customWidgetTextColor
        }

        if usesWallpaperBackground {
            return WidgetPalette.weeklyWallpaperPrimaryText
        }

        if usesCustomPhotoBackground {
            return WidgetPalette.weeklyCustomPhotoPrimaryText
        }

        if usesLiveTransparentBackground {
            return WidgetPalette.weeklyLiveTransparentPrimaryText
        }

        return WidgetPalette.weeklyPrimaryText(isDark: isDarkBackground)
    }

    private var secondaryTextColor: Color {
        if let customWidgetTextColor {
            return WidgetPalette.secondaryWidgetTextColor(from: customWidgetTextColor)
        }

        if usesWallpaperBackground {
            return WidgetPalette.weeklyWallpaperSecondaryText
        }

        if usesCustomPhotoBackground {
            return WidgetPalette.weeklyCustomPhotoSecondaryText
        }

        if usesLiveTransparentBackground {
            return WidgetPalette.weeklyLiveTransparentSecondaryText
        }

        return WidgetPalette.weeklySecondaryText(isDark: isDarkBackground)
    }

    private var usesLiveTransparentBackground: Bool {
        usesTransparentBackground && !usesWallpaperBackground && !usesCustomPhotoBackground
    }

    private var isToday: Bool {
        calendar.isDate(day.date, inSameDayAs: entry.date)
    }

    private var chineseCalendarInfo: ChineseCalendarDayInfo {
        ChineseCalendarInfoProvider.info(for: day.date, calendar: calendar)
    }

    private var festivalTextColor: Color {
        customWidgetTextColor ?? WidgetPalette.weeklyFestivalText(isDark: isDarkBackground)
    }

    var body: some View {
        GeometryReader { proxy in
            let visibleRows = visibleEventRows(for: proxy.size.height)
            let visibleEvents = visibleEvents(for: visibleRows)
            let overflowCount = day.events.count - visibleEvents.count

            VStack(alignment: .leading, spacing: headerToEventsSpacing) {
                dayHeader
                    .frame(height: dayHeaderHeight, alignment: .topLeading)

                VStack(alignment: .leading, spacing: eventRowSpacing) {
                    ForEach(visibleEvents, id: \.id) { event in
                        eventPill(event)
                    }

                    if overflowCount > 0 {
                        overflowIndicator(overflowCount)
                    }

                    if day.events.isEmpty && !usesTransparentBackground {
                        emptySkeleton
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, columnHorizontalPadding)
            .padding(.top, columnTopPadding)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var dayHeader: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            if isToday && (usesWallpaperBackground || usesLiveTransparentBackground || usesCustomPhotoBackground) {
                Text("\(calendar.component(.day, from: day.date))")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .frame(width: 20, height: 20)
                    .background(
                        usesWallpaperBackground
                            ? WidgetPalette.weeklyWallpaperTodayFill
                            : (
                                usesCustomPhotoBackground
                                    ? WidgetPalette.weeklyCustomPhotoTodayFill
                                    : WidgetPalette.weeklyLiveTransparentTodayFill
                            ),
                        in: Circle()
                    )
                    .shadow(color: Color.black.opacity(0.28), radius: 1.5, x: 0, y: 1)
            } else if isToday && !usesTransparentBackground {
                Text("今")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 18, height: 18)
                    .background(WidgetPalette.widgetTodayHighlightFill, in: Circle())
            } else {
                Text("\(calendar.component(.day, from: day.date))")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(primaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }

            if entry.showChineseCalendar {
                Text(chineseCalendarInfo.displayText)
                    .font(.system(size: 8, weight: chineseCalendarInfo.isFestival ? .bold : .medium))
                    .foregroundStyle(chineseCalendarInfo.isFestival ? festivalTextColor : secondaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            }
        }
    }

    private var emptySkeleton: some View {
        VStack(alignment: .leading, spacing: 5) {
            Capsule()
                .fill(WidgetPalette.weeklySkeletonFill(isDark: isDarkBackground, strong: true))
                .frame(maxWidth: .infinity)
                .frame(height: 4)

            Capsule()
                .fill(WidgetPalette.weeklySkeletonFill(isDark: isDarkBackground, strong: false))
                .frame(width: 22, height: 4)
        }
        .padding(.top, 2)
    }

    private func visibleEvents(for visibleRows: Int) -> [WidgetPlannerSnapshot.Event] {
        guard visibleRows > 0 else {
            return []
        }

        guard day.events.count > visibleRows else {
            return day.events
        }

        return Array(day.events.prefix(max(0, visibleRows - 1)))
    }

    private func visibleEventRows(for columnHeight: CGFloat) -> Int {
        let availableHeight = max(
            0,
            columnHeight - columnTopPadding - dayHeaderHeight - headerToEventsSpacing - columnBottomInset
        )
        let fullRowHeight = eventRowHeight + eventRowSpacing
        return max(0, Int((availableHeight + eventRowSpacing) / fullRowHeight))
    }

    private func eventPill(_ event: WidgetPlannerSnapshot.Event) -> some View {
        Text(event.title)
            .font(.system(size: eventTextSize, weight: .medium))
            .foregroundStyle(primaryTextColor)
            .lineLimit(1)
            .truncationMode(.tail)
            .strikethrough(event.isCompleted && entry.completedSchedulesUseStrikethrough)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, minHeight: eventRowHeight, maxHeight: eventRowHeight, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .fill(eventColor(hex: event.colorHex).opacity(event.isCompleted ? completedEventOpacity : activeEventOpacity))
            }
            .shadow(
                color: usesTransparentBackground ? Color.black.opacity(0.18) : Color.clear,
                radius: usesTransparentBackground ? 1.5 : 0,
                x: 0,
                y: usesTransparentBackground ? 1 : 0
            )
            .opacity(event.isCompleted ? 0.68 : 1)
    }

    private func overflowIndicator(_ count: Int) -> some View {
        Text("+\(count)")
            .font(.system(size: eventTextSize, weight: .bold))
            .foregroundStyle(customWidgetTextColor ?? (isDarkBackground ? Color.white.opacity(0.78) : WidgetPalette.blue))
            .lineLimit(1)
            .frame(maxWidth: .infinity, minHeight: eventRowHeight, maxHeight: eventRowHeight, alignment: .leading)
    }

    private var activeEventOpacity: Double {
        usesTransparentBackground ? 0.34 : (isDarkBackground ? 0.36 : 0.22)
    }

    private var completedEventOpacity: Double {
        usesTransparentBackground ? 0.16 : (isDarkBackground ? 0.18 : 0.10)
    }

    private func eventColor(hex: String) -> Color {
        let normalizedHex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#").union(.whitespacesAndNewlines))
        guard normalizedHex.count == 6,
              let rawValue = UInt64(normalizedHex, radix: 16) else {
            return WidgetPalette.blue
        }

        let red = Double((rawValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rawValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rawValue & 0x0000FF) / 255.0
        return Color(red: red, green: green, blue: blue)
    }
}

@available(iOS 17.0, macOS 14.0, *)
private struct SummaryWidgetView: View {
    var entry: MeowPlannerTodayEntry

    private var customWidgetTextColor: Color? {
        #if os(iOS)
        WidgetPalette.widgetTextColor(hex: WidgetPlannerPreferenceStore.widgetTextColorHex(platform: .iOS))
        #else
        nil
        #endif
    }

    private var usesWallpaperWidgetBackground: Bool {
        entry.widgetBackgroundStyle == .wallpaperPhoto
    }

    private var usesCustomPhotoWidgetBackground: Bool {
        #if os(iOS)
        entry.widgetBackgroundStyle == .customPhoto
        #else
        false
        #endif
    }

    private var primaryTextColor: Color {
        if let customWidgetTextColor {
            return customWidgetTextColor
        }

        if usesWallpaperWidgetBackground {
            return WidgetPalette.weeklyWallpaperPrimaryText
        }

        if usesCustomPhotoWidgetBackground {
            return WidgetPalette.weeklyCustomPhotoPrimaryText
        }

        return WidgetPalette.cocoa
    }

    private var secondaryTextColor: Color {
        if let customWidgetTextColor {
            return WidgetPalette.secondaryWidgetTextColor(from: customWidgetTextColor)
        }

        if usesWallpaperWidgetBackground {
            return WidgetPalette.weeklyWallpaperSecondaryText
        }

        if usesCustomPhotoWidgetBackground {
            return WidgetPalette.weeklyCustomPhotoSecondaryText
        }

        return WidgetPalette.caramel
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            #if os(iOS)
            WidgetContentBackgroundView(entry: entry)
            #endif

            VStack(alignment: .leading, spacing: 8) {
                Link(destination: WidgetConstants.appLaunchURL) {
                    HStack {
                        Image(systemName: "pawprint.fill")
                            .foregroundStyle(primaryTextColor)
                        Text("MeowPlanner")
                            .font(.headline)
                            .foregroundStyle(primaryTextColor)
                    }
                }
                .buttonStyle(.plain)

                if entry.showChineseCalendar {
                    let info = ChineseCalendarInfoProvider.info(for: entry.date, calendar: entry.weekStartPreference.configuredCalendar)
                    Text(info.displayText)
                        .font(.caption.weight(info.isFestival ? .bold : .medium))
                        .foregroundStyle(info.isFestival ? primaryTextColor : secondaryTextColor)
                        .lineLimit(1)
                }

                Spacer()

                if entry.showsEmptyState {
                    emptyStateSummary
                } else {
                    Label("\(entry.scheduleCount) schedules", systemImage: "calendar")
                        .foregroundStyle(primaryTextColor)
                    Label("\(entry.todoCount) todos", systemImage: "checklist")
                        .foregroundStyle(primaryTextColor)
                    Label("\(entry.habitCount) habits", systemImage: "checkmark.seal")
                        .foregroundStyle(primaryTextColor)
                }
            }
        }
        .font(.caption)
        .clipped()
    }

    private var emptyStateSummary: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: "pawprint.fill")
                    .foregroundStyle(primaryTextColor)

                Text("No plans yet")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(primaryTextColor)

            Text("Open MeowPlanner to sync")
                .font(.caption2.weight(.medium))
                .foregroundStyle(secondaryTextColor)
                .lineLimit(2)
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
private struct MonthWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode
    @Environment(\.showsWidgetContainerBackground) private var showsWidgetContainerBackground

    var entry: MeowPlannerTodayEntry
    var family: WidgetFamily

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        GeometryReader { proxy in
            let outerPadding: CGFloat = family == .systemExtraLarge ? 7 : 5
            let headerHeight: CGFloat = family == .systemExtraLarge ? 22 : 20
            let weekdayHeight: CGFloat = 15
            let verticalSpacing: CGFloat = 2
            let rowCount = max(1, entry.monthDays.count / 7)
            let rowHeight = floor(max(
                16,
                (proxy.size.height - (outerPadding * 2) - headerHeight - weekdayHeight - verticalSpacing) / CGFloat(rowCount)
            ))

            ZStack(alignment: .bottomTrailing) {
                #if os(iOS)
                WidgetContentBackgroundView(entry: entry)
                #endif

                #if os(macOS)
                if showsWidgetContainerBackground && WidgetPlannerPreferenceStore.widgetBackgroundStyle == .defaultArtwork {
                    fufuPawWatermark
                }
                #else
                if showsWidgetContainerBackground && entry.widgetBackgroundStyle == .defaultArtwork {
                    fufuPawWatermark
                }
                #endif

                VStack(alignment: .leading, spacing: verticalSpacing) {
                    monthHeader
                        .frame(height: headerHeight)
                        .zIndex(1)

                    calendarGrid(rowHeight: rowHeight, weekdayHeight: weekdayHeight)
                }
                .padding(outerPadding)

                if entry.showsEmptyState {
                    emptyStateOverlay
                }
            }
        }
    }

    private var monthTitle: String {
        entry.visibleMonthDate.formatted(.dateTime.month(.abbreviated).year())
    }

    private var calendar: Calendar {
        entry.weekStartPreference.configuredCalendar
    }

    private var weekdaySymbols: [String] {
        entry.weekStartPreference.orderedVeryShortWeekdaySymbols(calendar: calendar)
    }

    private var usesFullColorRendering: Bool {
        widgetRenderingMode == .fullColor
    }

    private var usesMacOSGlassBackground: Bool {
        #if os(macOS)
        showsWidgetContainerBackground && WidgetPlannerPreferenceStore.widgetBackgroundStyle == .defaultArtwork
        #else
        false
        #endif
    }

    private var usesWallpaperWidgetBackground: Bool {
        entry.widgetBackgroundStyle == .wallpaperPhoto
    }

    private var usesCustomPhotoWidgetBackground: Bool {
        #if os(iOS)
        entry.widgetBackgroundStyle == .customPhoto
        #else
        false
        #endif
    }

    private var isDarkBackground: Bool {
        WidgetPlannerPreferenceStore.isDarkWidgetAppearance(
            systemIsDark: colorScheme == .dark,
            backgroundStyle: entry.widgetBackgroundStyle
        )
    }

    private var customWidgetTextColor: Color? {
        #if os(iOS)
        WidgetPalette.widgetTextColor(hex: WidgetPlannerPreferenceStore.widgetTextColorHex(platform: .iOS))
        #else
        nil
        #endif
    }

    private var monthPrimaryTextColor: Color {
        if let customWidgetTextColor {
            return customWidgetTextColor
        }

        if usesWallpaperWidgetBackground {
            return WidgetPalette.weeklyWallpaperPrimaryText
        }

        if usesCustomPhotoWidgetBackground {
            return WidgetPalette.weeklyCustomPhotoPrimaryText
        }

        return usesMacOSGlassBackground ? WidgetPalette.macOSGlassPrimaryText(isDark: isDarkBackground) : WidgetPalette.cocoa
    }

    private var monthSecondaryTextColor: Color {
        if let customWidgetTextColor {
            return WidgetPalette.secondaryWidgetTextColor(from: customWidgetTextColor)
        }

        if usesWallpaperWidgetBackground {
            return WidgetPalette.weeklyWallpaperSecondaryText
        }

        if usesCustomPhotoWidgetBackground {
            return WidgetPalette.weeklyCustomPhotoSecondaryText
        }

        return usesMacOSGlassBackground ? WidgetPalette.macOSGlassSecondaryText(isDark: isDarkBackground) : WidgetPalette.caramel
    }

    private var monthMutedTextColor: Color {
        if let customWidgetTextColor {
            return customWidgetTextColor.opacity(0.48)
        }

        if usesWallpaperWidgetBackground {
            return WidgetPalette.weeklyWallpaperSecondaryText.opacity(0.62)
        }

        if usesCustomPhotoWidgetBackground {
            return WidgetPalette.weeklyCustomPhotoSecondaryText.opacity(0.62)
        }

        return usesMacOSGlassBackground ? WidgetPalette.macOSGlassMutedText(isDark: isDarkBackground) : Color.secondary
    }

    private var monthFestivalTextColor: Color {
        if let customWidgetTextColor {
            return customWidgetTextColor
        }

        if usesWallpaperWidgetBackground {
            return WidgetPalette.weeklyWallpaperPrimaryText
        }

        if usesCustomPhotoWidgetBackground {
            return WidgetPalette.weeklyCustomPhotoPrimaryText
        }

        return usesMacOSGlassBackground ? WidgetPalette.macOSGlassFestivalText(isDark: isDarkBackground) : WidgetPalette.blush
    }

    private var monthGridLineColor: Color {
        if usesWallpaperWidgetBackground {
            return WidgetPalette.weeklyWallpaperSeparator
        }

        if usesCustomPhotoWidgetBackground {
            return WidgetPalette.weeklyCustomPhotoSeparator
        }

        return usesMacOSGlassBackground ? WidgetPalette.macOSGlassGridLine(isDark: isDarkBackground) : WidgetPalette.caramel.opacity(0.12)
    }

    private var monthGridBorderColor: Color {
        if usesWallpaperWidgetBackground {
            return WidgetPalette.weeklyWallpaperSeparator
        }

        if usesCustomPhotoWidgetBackground {
            return WidgetPalette.weeklyCustomPhotoSeparator
        }

        return usesMacOSGlassBackground ? WidgetPalette.macOSGlassGridBorder(isDark: isDarkBackground) : WidgetPalette.caramel.opacity(0.18)
    }

    private var monthTodayCellHighlightColor: Color {
        #if os(macOS)
        return usesMacOSGlassBackground ? WidgetPalette.macOSGlassTodayCellHighlight(isDark: isDarkBackground) : WidgetPalette.blue.opacity(0.16)
        #else
        return WidgetPalette.widgetTodayHighlightSoftFill
        #endif
    }

    private var showsTodayIndicator: Bool {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }

    private var monthTodayIndicatorColor: Color {
        #if os(macOS)
        return usesMacOSGlassBackground ? WidgetPalette.macOSGlassTodayIndicator(isDark: isDarkBackground) : WidgetPalette.blush
        #else
        return usesMacOSGlassBackground ? WidgetPalette.macOSGlassTodayIndicator(isDark: isDarkBackground) : WidgetPalette.widgetTodayIndicatorFill
        #endif
    }

    private var fufuPawPrimaryWatermarkColor: Color {
        usesMacOSGlassBackground ? WidgetPalette.macOSGlassPawPrimary(isDark: isDarkBackground) : WidgetPalette.caramel.opacity(0.10)
    }

    private var fufuPawSecondaryWatermarkColor: Color {
        usesMacOSGlassBackground ? WidgetPalette.macOSGlassPawSecondary(isDark: isDarkBackground) : WidgetPalette.blue.opacity(0.10)
    }

    private var completedEventPillOpacity: Double {
        usesFullColorRendering ? 0.52 : 0.76
    }

    private var activeEventPillDarkeningOpacity: Double {
        usesMacOSGlassBackground ? WidgetPalette.macOSGlassActiveEventPillDarkeningOpacity(isDark: isDarkBackground) : 0
    }

    private var emptyStateBackgroundColor: Color {
        usesMacOSGlassBackground ? WidgetPalette.macOSGlassEmptyStateFill(isDark: isDarkBackground) : WidgetPalette.cream.opacity(0.84)
    }

    private var emptyStateOverlay: some View {
        VStack(spacing: 4) {
            fufuWidgetMascot(size: family == .systemExtraLarge ? 28 : 24)

            Text("No plans yet")
                .font(.caption.weight(.semibold))
                .foregroundStyle(monthPrimaryTextColor)

            Text("Open MeowPlanner to sync")
                .font(.caption2.weight(.medium))
                .foregroundStyle(monthSecondaryTextColor)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(emptyStateBackgroundColor, in: RoundedRectangle(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(monthGridBorderColor, lineWidth: 1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .allowsHitTesting(false)
    }

    private var monthHeader: some View {
        HStack(spacing: 5) {
            #if os(iOS)
            Button(intent: ChangeWidgetMonthIntent(monthDelta: -1)) {
                Image(systemName: "chevron.left")
                    .font(.caption2.weight(.bold))
                    .frame(width: 18, height: 18)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(monthPrimaryTextColor)
            #else
            Button(intent: ChangeWidgetMonthIntent(monthDelta: -1)) {
                Image(systemName: "chevron.left")
                    .font(.caption2.weight(.bold))
                    .frame(width: 18, height: 18)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(monthPrimaryTextColor)
            #endif

            Link(destination: WidgetConstants.appLaunchURL) {
                Label(monthTitle, systemImage: "pawprint.fill")
                    .font((family == .systemExtraLarge ? Font.subheadline : Font.caption2).weight(.bold))
                    .foregroundStyle(monthPrimaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .buttonStyle(.plain)

            #if os(iOS)
            Button(intent: ChangeWidgetMonthIntent(monthDelta: 1)) {
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .frame(width: 18, height: 18)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(monthPrimaryTextColor)
            #else
            Button(intent: ChangeWidgetMonthIntent(monthDelta: 1)) {
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .frame(width: 18, height: 18)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(monthPrimaryTextColor)
            #endif

            Spacer(minLength: 4)

            #if os(iOS)
            Button(intent: ReturnWidgetToTodayIntent()) {
                Image(systemName: "pawprint.fill")
                    .font((family == .systemExtraLarge ? Font.body : Font.caption).weight(.bold))
                    .foregroundStyle(monthPrimaryTextColor)
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("回到今日并刷新小组件")

            #else
            Button(intent: RefreshWidgetTimelineIntent()) {
                Image(systemName: "pawprint.fill")
                    .font((family == .systemExtraLarge ? Font.body : Font.caption).weight(.bold))
                    .foregroundStyle(monthPrimaryTextColor)
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            #endif
        }
        .padding(.horizontal, 2)
    }

    private func calendarGrid(rowHeight: CGFloat, weekdayHeight: CGFloat) -> some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, weekday in
                weekdayHeaderCell(weekday, height: weekdayHeight)
            }

            ForEach(entry.monthDays) { day in
                dayCell(day, rowHeight: rowHeight)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(monthGridBorderColor, lineWidth: 1)
        }
    }

    private var weekdaySeparatorColor: Color {
        monthGridLineColor
    }

    private func weekdayHeaderCell(_ weekday: String, height: CGFloat) -> some View {
        Text(weekday)
            .font(.caption2.weight(.bold))
            .foregroundStyle(monthSecondaryTextColor)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(weekdaySeparatorColor)
                    .frame(height: 1)
            }
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(weekdaySeparatorColor)
                    .frame(width: 1)
            }
    }

    private func dayCell(_ day: MonthPlannerDay, rowHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 3) {
                Text(day.date.formatted(.dateTime.day()))
                    .font(.caption.weight(calendar.isDate(day.date, inSameDayAs: entry.date) ? .bold : .semibold))
                    .foregroundStyle(day.isInSelectedMonth ? monthPrimaryTextColor : monthMutedTextColor)

                if entry.showChineseCalendar {
                    Text(day.chineseCalendarInfo.displayText)
                        .font(.caption2.weight(day.chineseCalendarInfo.isFestival ? .bold : .medium))
                        .foregroundStyle(day.chineseCalendarInfo.isFestival ? monthFestivalTextColor : monthSecondaryTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.60)
                }

                if showsTodayIndicator && calendar.isDateInToday(day.date) {
                    Circle()
                        .fill(monthTodayIndicatorColor)
                        .frame(width: 4, height: 4)
                }

                Spacer(minLength: 0)
            }

            let maxVisibleItems: Int = family == .systemExtraLarge ? 2 : 1
            ForEach(day.items.prefix(maxVisibleItems)) { item in
                eventPill(item)
            }

            Spacer(minLength: 0)
        }
        .padding(5)
        .frame(height: rowHeight, alignment: .top)
        .frame(maxWidth: .infinity)
        .background(dayBackground(day), in: Rectangle())
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(weekdaySeparatorColor)
                .frame(height: 1)
        }
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(weekdaySeparatorColor)
                .frame(width: 1)
        }
    }

    private func dayBackground(_ day: MonthPlannerDay) -> some ShapeStyle {
        if calendar.isDateInToday(day.date) {
            return AnyShapeStyle(monthTodayCellHighlightColor)
        }
        return AnyShapeStyle(Color.clear)
    }

    private func eventPill(_ item: MonthPlannerItem) -> some View {
        Text(item.title)
            .font(.caption2.weight(.medium))
            .foregroundStyle(eventPillTitleColor())
            .lineLimit(1)
            .strikethrough(item.isCompleted && entry.completedSchedulesUseStrikethrough)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 3)
                    .fill(eventPillBackground(item))
                    .overlay {
                        if !item.isCompleted && activeEventPillDarkeningOpacity > 0 {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.black.opacity(activeEventPillDarkeningOpacity))
                        }
                    }
            }
            .opacity(item.isCompleted ? completedEventPillOpacity : 1)
    }

    private func eventPillTitleColor() -> some ShapeStyle {
        if let customWidgetTextColor {
            return AnyShapeStyle(customWidgetTextColor)
        }

        if usesWallpaperWidgetBackground {
            return AnyShapeStyle(WidgetPalette.weeklyWallpaperPrimaryText)
        }

        if usesCustomPhotoWidgetBackground {
            return AnyShapeStyle(WidgetPalette.weeklyCustomPhotoPrimaryText)
        }

        return usesMacOSGlassBackground ? AnyShapeStyle(WidgetPalette.macOSGlassEventPillText(isDark: isDarkBackground)) : AnyShapeStyle(WidgetPalette.cocoa)
    }

    private func eventPillBackground(_ item: MonthPlannerItem) -> some ShapeStyle {
        AnyShapeStyle(
            widgetColor(
                hex: item.colorHex,
                fallback: item.kind == .event ? WidgetPalette.blue : WidgetPalette.caramel
            )
        )
    }

    private func widgetColor(hex: String, fallback: Color) -> Color {
        let normalizedHex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#").union(.whitespacesAndNewlines))
        guard normalizedHex.count == 6,
              let rawValue = UInt64(normalizedHex, radix: 16) else {
            return fallback
        }

        let red = Double((rawValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rawValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rawValue & 0x0000FF) / 255.0
        return Color(red: red, green: green, blue: blue)
    }

    private var fufuPawWatermark: some View {
        VStack {
            HStack {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: family == .systemExtraLarge ? 74 : 46, weight: .bold))
                    .rotationEffect(.degrees(-16))
                    .foregroundStyle(fufuPawPrimaryWatermarkColor)
                Spacer()
            }

            Spacer()

            HStack {
                Spacer()
                Image(systemName: "pawprint.fill")
                    .font(.system(size: family == .systemExtraLarge ? 92 : 56, weight: .bold))
                    .rotationEffect(.degrees(18))
                    .foregroundStyle(fufuPawSecondaryWatermarkColor)
            }
        }
        .allowsHitTesting(false)
    }

    private func fufuWidgetMascot(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(WidgetPalette.cream.opacity(0.72))

            if let image = WidgetFuFuImageLoader.image() {
                #if os(macOS)
                widgetFullColorImage(
                    Image(nsImage: image)
                        .interpolation(.none)
                        .resizable()
                )
                    .scaledToFit()
                    .padding(size * 0.14)
                #else
                widgetFullColorImage(
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                )
                    .scaledToFit()
                    .padding(size * 0.14)
                #endif
            } else {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: size * 0.48, weight: .bold))
                    .foregroundStyle(WidgetPalette.caramel)
            }
        }
        .frame(width: size, height: size)
    }
}

private enum WidgetFuFuImageLoader {
    #if os(macOS)
    static func image() -> NSImage? {
        guard let url = Bundle.main.url(
            forResource: "fufu-idle",
            withExtension: "png",
            subdirectory: "FuFu"
        ) else {
            return nil
        }
        return NSImage(contentsOf: url)
    }
    #else
    static func image() -> UIImage? {
        guard let url = Bundle.main.url(
            forResource: "fufu-idle",
            withExtension: "png",
            subdirectory: "FuFu"
        ) else {
            return nil
        }
        return UIImage(contentsOfFile: url.path)
    }
    #endif
}

private enum WidgetResourceBundle {
    static func url(forResource name: String, withExtension extensionName: String, subdirectory: String? = nil) -> URL? {
        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(
            forResource: name,
            withExtension: extensionName,
            subdirectory: subdirectory
        ) {
            return url
        }
        #endif

        return Bundle.main.url(
            forResource: name,
            withExtension: extensionName,
            subdirectory: subdirectory
        )
    }
}

private enum WidgetBackgroundImageLoader {
    #if os(iOS)
    static func image(style: WidgetBackgroundStyle, isDark: Bool) -> UIImage? {
        switch style {
        case .defaultArtwork:
            bundledImage(isDark: isDark)
        case .customPhoto:
            customBackgroundImage()
        case .wallpaperPhoto:
            wallpaperBackgroundImage()
        }
    }

    static func bundledImage(isDark: Bool) -> UIImage? {
        guard let url = WidgetResourceBundle.url(
            forResource: isDark ? "WidgetBackgroundDark" : "WidgetBackgroundLight",
            withExtension: "png"
        ) else {
            return nil
        }
        return UIImage(contentsOfFile: url.path)
    }

    static func customBackgroundImage() -> UIImage? {
        if let data = WidgetPlannerPreferenceStore.customBackgroundImageData(platform: .current) {
            return UIImage(data: data)
        }

        return image(from: WidgetPlannerPreferenceStore.customBackgroundImageURLs)
    }

    static func wallpaperBackgroundImage() -> UIImage? {
        if let data = WidgetPlannerPreferenceStore.wallpaperBackgroundImageData(platform: .current) {
            return UIImage(data: data)
        }

        return image(from: WidgetPlannerPreferenceStore.wallpaperBackgroundImageURLs)
    }

    private static func image(from fileURLs: [URL]) -> UIImage? {
        for url in fileURLs {
            guard let data = try? Data(contentsOf: url),
                  let image = UIImage(data: data)
            else {
                continue
            }

            return image
        }

        return nil
    }
    #else
    static func image(style: WidgetBackgroundStyle, isDark: Bool) -> NSImage? {
        switch style {
        case .defaultArtwork:
            bundledImage(isDark: isDark)
        case .customPhoto:
            customBackgroundImage()
        case .wallpaperPhoto:
            wallpaperBackgroundImage()
        }
    }

    static func bundledImage(isDark: Bool) -> NSImage? {
        guard let url = WidgetResourceBundle.url(
            forResource: isDark ? "WidgetBackgroundDark" : "WidgetBackgroundLight",
            withExtension: "png"
        ) else {
            return nil
        }
        return NSImage(contentsOf: url)
    }

    static func customBackgroundImage() -> NSImage? {
        if let data = WidgetPlannerPreferenceStore.customBackgroundImageData(platform: .current) {
            return NSImage(data: data)
        }

        return image(from: WidgetPlannerPreferenceStore.customBackgroundImageURLs)
    }

    static func wallpaperBackgroundImage() -> NSImage? {
        if let data = WidgetPlannerPreferenceStore.wallpaperBackgroundImageData(platform: .current) {
            return NSImage(data: data)
        }

        return image(from: WidgetPlannerPreferenceStore.wallpaperBackgroundImageURLs)
    }

    private static func image(from fileURLs: [URL]) -> NSImage? {
        for url in fileURLs {
            guard let data = try? Data(contentsOf: url),
                  let image = NSImage(data: data)
            else {
                continue
            }

            return image
        }

        return nil
    }
    #endif
}

private enum WidgetPalette {
    static let cream = Color(red: 0.98, green: 0.94, blue: 0.86)
    static let cocoa = Color(red: 0.24, green: 0.15, blue: 0.10)
    static let caramel = Color(red: 0.68, green: 0.45, blue: 0.27)
    static let blue = Color(red: 0.18, green: 0.45, blue: 0.68)
    static let blush = Color(red: 0.88, green: 0.58, blue: 0.51)
    static let orange = Color(red: 1.00, green: 0.53, blue: 0.04)
    static let widgetTodayHighlightFill = caramel.opacity(0.92)
    static let widgetTodayHighlightSoftFill = caramel.opacity(0.16)
    static let widgetTodayIndicatorFill = caramel

    static func widgetTextColor(hex: String?) -> Color? {
        guard let hex else {
            return nil
        }

        let normalizedHex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#").union(.whitespacesAndNewlines))
        guard normalizedHex.count == 6,
              let rawValue = UInt64(normalizedHex, radix: 16) else {
            return nil
        }

        let red = Double((rawValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rawValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rawValue & 0x0000FF) / 255.0
        return Color(red: red, green: green, blue: blue)
    }

    static func secondaryWidgetTextColor(from color: Color) -> Color {
        color.opacity(0.72)
    }

    static func macOSGlassBackgroundOverlay(isDark: Bool) -> LinearGradient {
        LinearGradient(
            colors: isDark
                ? [
                    Color(red: 0.10, green: 0.11, blue: 0.11).opacity(0.78),
                    Color(red: 0.18, green: 0.19, blue: 0.18).opacity(0.56),
                    Color(red: 0.04, green: 0.05, blue: 0.05).opacity(0.62)
                ]
                : [
                    Color.white.opacity(0.74),
                    Color(red: 0.91, green: 0.91, blue: 0.88).opacity(0.56),
                    Color(red: 0.78, green: 0.79, blue: 0.77).opacity(0.34)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func macOSGlassBackgroundWash(isDark: Bool) -> Color {
        isDark ? Color.black.opacity(0.16) : Color.white.opacity(0.18)
    }

    static func macOSGlassBackgroundBorder(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.18) : Color.black.opacity(0.12)
    }

    static func macOSGlassPrimaryText(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.86) : Color.black.opacity(0.68)
    }

    static func macOSGlassSecondaryText(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.64) : Color.black.opacity(0.50)
    }

    static func macOSGlassMutedText(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.42) : Color.black.opacity(0.34)
    }

    static func macOSGlassFestivalText(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.84) : Color.black.opacity(0.62)
    }

    static func macOSGlassGridLine(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.16) : Color.black.opacity(0.12)
    }

    static func macOSGlassGridBorder(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.26) : Color.black.opacity(0.18)
    }

    static func macOSGlassTodayCellHighlight(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.16) : Color.black.opacity(0.12)
    }

    static func macOSGlassTodayIndicator(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.78) : Color.black.opacity(0.46)
    }

    static func macOSGlassEventPillText(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.86) : Color.black.opacity(0.70)
    }

    static func macOSGlassActiveEventPillDarkeningOpacity(isDark: Bool) -> Double {
        isDark ? 0.26 : 0.18
    }

    static func macOSGlassPawPrimary(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05)
    }

    static func macOSGlassPawSecondary(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.04)
    }

    static func macOSGlassEmptyStateFill(isDark: Bool) -> Color {
        isDark ? Color.black.opacity(0.24) : Color.white.opacity(0.64)
    }

    static func weeklyGlassFill(isDark: Bool) -> Color {
        isDark ? Color.black.opacity(0.46) : Color.white.opacity(0.72)
    }

    static func weeklyGlassStroke(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.16) : caramel.opacity(0.18)
    }

    static let weeklyLiveTransparentCardFill = Color.clear

    static let weeklyLiveTransparentPrimaryText = Color.white.opacity(0.96)

    static let weeklyLiveTransparentSecondaryText = Color.white.opacity(0.70)

    static let weeklyLiveTransparentSeparator = Color.white.opacity(0.28)

    static let weeklyLiveTransparentTodayFill = widgetTodayHighlightFill

    static let weeklyWallpaperCardFill = Color.clear

    static let weeklyWallpaperPrimaryText = Color.white.opacity(0.94)

    static let weeklyWallpaperSecondaryText = Color.white.opacity(0.68)

    static let weeklyWallpaperSeparator = Color.white.opacity(0.24)

    static let weeklyWallpaperTodayFill = widgetTodayHighlightFill

    static let weeklyCustomPhotoCardFill = Color.clear

    static let weeklyCustomPhotoPrimaryText = cocoa.opacity(0.96)

    static let weeklyCustomPhotoSecondaryText = caramel.opacity(0.86)

    static let weeklyCustomPhotoSeparator = caramel.opacity(0.26)

    static let weeklyCustomPhotoTodayFill = widgetTodayHighlightFill

    static func weeklyPrimaryText(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.92) : cocoa
    }

    static func weeklySecondaryText(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.62) : caramel.opacity(0.82)
    }

    static func weeklyFestivalText(isDark: Bool) -> Color {
        isDark ? Color(red: 1.0, green: 0.70, blue: 0.63) : blush
    }

    static func weeklySeparator(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.12) : caramel.opacity(0.12)
    }

    static func weeklyTransparentSeparator(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.20) : caramel.opacity(0.20)
    }

    static func weeklyBadgeFill(isDark: Bool) -> Color {
        isDark ? Color.black.opacity(0.26) : cream.opacity(0.72)
    }

    static func weeklySkeletonFill(isDark: Bool, strong: Bool) -> Color {
        if isDark {
            return Color.white.opacity(strong ? 0.16 : 0.10)
        }
        return caramel.opacity(strong ? 0.12 : 0.07)
    }

    static func weeklyFallbackBackground(isDark: Bool) -> LinearGradient {
        LinearGradient(
            colors: isDark
                ? [
                    Color(red: 0.12, green: 0.13, blue: 0.14),
                    Color(red: 0.05, green: 0.06, blue: 0.07)
                ]
                : [
                    Color(red: 0.99, green: 0.92, blue: 0.86),
                    Color(red: 0.98, green: 0.97, blue: 0.93)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

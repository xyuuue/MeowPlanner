import SwiftUI

#if os(macOS)
@preconcurrency import AppKit
#else
import UIKit
#endif

enum MeowPlannerTheme {
    #if os(macOS)
    static func macOSSystemColor(_ color: NSColor) -> Color {
        Color(NSColor(name: nil) { appearance in
            var resolvedColor = color
            appearance.performAsCurrentDrawingAppearance {
                resolvedColor = color.usingColorSpace(.sRGB) ?? color
            }
            return resolvedColor
        })
    }

    private static let darkWindowBackground = macOSSystemColor(.windowBackgroundColor)
    private static let darkUnderPageBackground = macOSSystemColor(.underPageBackgroundColor)
    private static let darkControlBackground = macOSSystemColor(.controlBackgroundColor)
    private static let darkSeparator = macOSSystemColor(.separatorColor)
    private static let darkLabel = macOSSystemColor(.labelColor)
    private static let darkSecondaryLabel = macOSSystemColor(.secondaryLabelColor)
    private static let darkTertiaryLabel = macOSSystemColor(.tertiaryLabelColor)
    private static let darkSoftBrownHighlight = Color(red: 0.62, green: 0.47, blue: 0.34)
    private static let darkPawButtonBrown = Color(red: 0.62, green: 0.40, blue: 0.24)
    private static let darkCreamRing = Color(red: 0.94, green: 0.87, blue: 0.76)
    #else
    private static let darkWindowBackground = Color(UIColor.systemBackground)
    private static let darkUnderPageBackground = Color(UIColor.secondarySystemBackground)
    private static let darkControlBackground = Color(UIColor.tertiarySystemBackground)
    private static let darkSeparator = Color(UIColor.separator)
    private static let darkLabel = Color(UIColor.label)
    private static let darkSecondaryLabel = Color(UIColor.secondaryLabel)
    private static let darkTertiaryLabel = Color(UIColor.tertiaryLabel)
    private static let darkSoftBrownHighlight = Color(red: 0.62, green: 0.47, blue: 0.34)
    private static let darkPawButtonBrown = Color(red: 0.62, green: 0.40, blue: 0.24)
    private static let darkCreamRing = Color(red: 0.94, green: 0.87, blue: 0.76)
    #endif

    static let cream = adaptiveColor(
        light: Color(red: 0.98, green: 0.94, blue: 0.86),
        dark: darkControlBackground
    )
    static let warmCream = adaptiveColor(
        light: Color(red: 0.93, green: 0.85, blue: 0.73),
        dark: darkUnderPageBackground
    )
    static let coffee = adaptiveColor(
        light: Color(red: 0.37, green: 0.22, blue: 0.13),
        dark: darkSecondaryLabel
    )
    static let cocoa = adaptiveColor(
        light: Color(red: 0.24, green: 0.15, blue: 0.10),
        dark: darkLabel
    )
    static let caramel = adaptiveColor(
        light: Color(red: 0.68, green: 0.45, blue: 0.27),
        dark: darkSoftBrownHighlight
    )
    static let fufuBlue = adaptiveColor(
        light: Color(red: 0.18, green: 0.45, blue: 0.68),
        dark: darkLabel
    )
    static let accentText = adaptiveColor(
        light: Color(red: 0.68, green: 0.45, blue: 0.27),
        dark: darkLabel
    )
    static let softBrownHighlight = adaptiveColor(
        light: Color(red: 0.86, green: 0.67, blue: 0.48),
        dark: darkSoftBrownHighlight
    )
    static let pawButtonBrown = adaptiveColor(
        light: Color(red: 0.70, green: 0.45, blue: 0.27),
        dark: darkPawButtonBrown
    )
    static let creamRing = adaptiveColor(
        light: Color(red: 0.98, green: 0.91, blue: 0.80),
        dark: darkCreamRing
    )
    static let blush = adaptiveColor(
        light: Color(red: 0.88, green: 0.58, blue: 0.51),
        dark: Color(red: 0.96, green: 0.47, blue: 0.42)
    )
    static let mint = adaptiveColor(
        light: Color(red: 0.50, green: 0.67, blue: 0.58),
        dark: Color(red: 0.49, green: 0.78, blue: 0.68)
    )
    static let lavender = adaptiveColor(
        light: Color(red: 0.58, green: 0.49, blue: 0.74),
        dark: Color(red: 0.68, green: 0.61, blue: 0.88)
    )
    static let fufuPlannerBackground = adaptiveColor(
        light: Color(red: 1.00, green: 0.945, blue: 0.915),
        dark: darkWindowBackground
    )
    static let fufuCalendarBackground = adaptiveColor(
        light: Color(red: 1.00, green: 0.965, blue: 0.940),
        dark: darkUnderPageBackground
    )
    static let fufuPawTint = adaptiveColor(
        light: Color(red: 0.83, green: 0.57, blue: 0.42),
        dark: darkTertiaryLabel
    )
    static let monthGridHeaderBackground = adaptiveColor(
        light: Color(red: 0.995, green: 0.930, blue: 0.840),
        dark: darkControlBackground
    )
    static let monthGridSelectedDayBackground = adaptiveColor(
        light: Color(red: 0.875, green: 0.905, blue: 0.925),
        dark: darkSoftBrownHighlight
    )
    static let monthGridCurrentMonthCellBackground = adaptiveColor(
        light: Color(red: 1.000, green: 0.970, blue: 0.945),
        dark: darkUnderPageBackground
    )
    static let monthGridOutsideMonthCellBackground = adaptiveColor(
        light: Color(red: 0.985, green: 0.920, blue: 0.885),
        dark: darkWindowBackground
    )
    static let monthGridDivider = adaptiveColor(
        light: Color(red: 0.800, green: 0.540, blue: 0.390),
        dark: darkSeparator
    )

    static var plannerGradient: LinearGradient {
        LinearGradient(
            colors: [
                fufuPlannerBackground,
                adaptiveColor(
                    light: Color(red: 1.00, green: 0.965, blue: 0.935),
                    dark: darkWindowBackground
                ),
                adaptiveColor(
                    light: Color(red: 0.985, green: 0.920, blue: 0.890),
                    dark: darkUnderPageBackground
                )
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func adaptiveColor(light: Color, dark: Color) -> Color {
        #if os(macOS)
        Color(NSColor(name: nil) { appearance in
            let matchedAppearance = appearance.bestMatch(from: [.darkAqua, .aqua])
            let selectedColor = matchedAppearance == .darkAqua ? dark : light
            let platformColor = NSColor(selectedColor)
            var resolvedColor = platformColor
            appearance.performAsCurrentDrawingAppearance {
                resolvedColor = platformColor.usingColorSpace(.sRGB) ?? platformColor
            }
            return resolvedColor
        })
        #else
        Color(UIColor { traits in
            let selectedColor = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(selectedColor)
        })
        #endif
    }

    static func color(hex: String) -> Color {
        let trimmed = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#").union(.whitespacesAndNewlines))
        guard trimmed.count == 6,
              let value = Int(trimmed, radix: 16) else {
            return fufuBlue
        }

        return Color(
            red: Double((value >> 16) & 0xFF) / 255.0,
            green: Double((value >> 8) & 0xFF) / 255.0,
            blue: Double(value & 0xFF) / 255.0
        )
    }

    static func normalizedHex(_ value: String) -> String? {
        let trimmed = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#"))
            .uppercased()

        guard trimmed.count == 6,
              Int(trimmed, radix: 16) != nil else {
            return nil
        }

        return "#\(trimmed)"
    }

    static func hex(color: Color) -> String? {
        #if os(macOS)
        let platformColor = NSColor(color)
        guard let converted = platformColor.usingColorSpace(.sRGB) else {
            return nil
        }
        let red = Int((converted.redComponent * 255).rounded())
        let green = Int((converted.greenComponent * 255).rounded())
        let blue = Int((converted.blueComponent * 255).rounded())
        #else
        let platformColor = UIColor(color)
        var redValue: CGFloat = 0
        var greenValue: CGFloat = 0
        var blueValue: CGFloat = 0
        var alphaValue: CGFloat = 0
        guard platformColor.getRed(&redValue, green: &greenValue, blue: &blueValue, alpha: &alphaValue) else {
            return nil
        }
        let red = Int((redValue * 255).rounded())
        let green = Int((greenValue * 255).rounded())
        let blue = Int((blueValue * 255).rounded())
        #endif

        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}

struct PlannerNumberInputRow: View {
    var title: String
    @Binding var value: Int
    var range: ClosedRange<Int>
    var suffix: String = ""

    @State private var draftText = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .foregroundStyle(MeowPlannerTheme.cocoa)

            Spacer()

            TextField("", text: $draftText)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.roundedBorder)
                .frame(width: 88)
                .focused($isInputFocused)
                .onSubmit(commitDraftValue)
                .onAppear(perform: syncDraftText)
                .onChange(of: isInputFocused) { _, newValue in
                    if !newValue {
                        commitDraftValue()
                    }
                }
                .onChange(of: value) { _, _ in
                    if !isInputFocused {
                        syncDraftText()
                    }
                }
                .background(
                    NumericInputOutsideClickCommitter(
                        isFocused: isInputFocused,
                        onOutsideClick: commitDraftAndClearFocus
                    )
                )

            if !suffix.isEmpty {
                Text(suffix)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 36, alignment: .leading)
            }
        }
        .padding(.vertical, 10)
    }

    private func commitDraftValue() {
        let trimmedText = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let newValue = Int(trimmedText) else {
            syncDraftText()
            return
        }

        let clampedValue = min(max(newValue, range.lowerBound), range.upperBound)
        if value != clampedValue {
            value = clampedValue
        }
        draftText = "\(clampedValue)"
    }

    private func syncDraftText() {
        let clampedValue = min(max(value, range.lowerBound), range.upperBound)
        if value != clampedValue {
            value = clampedValue
        }
        draftText = "\(clampedValue)"
    }

    private func commitDraftAndClearFocus() {
        commitDraftValue()
        isInputFocused = false
    }
}

#if os(macOS)
struct NumericInputOutsideClickCommitter: NSViewRepresentable {
    var isFocused: Bool
    var onOutsideClick: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(isFocused: isFocused, onOutsideClick: onOutsideClick)
    }

    func makeNSView(context: Context) -> NSView {
        let view = TrackingView()
        view.coordinator = context.coordinator
        context.coordinator.install(for: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.isFocused = isFocused
        context.coordinator.onOutsideClick = onOutsideClick
        context.coordinator.refreshRegion(from: nsView)
        context.coordinator.install(for: nsView)
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.uninstall()
    }

    final class Coordinator {
        var isFocused: Bool
        var onOutsideClick: () -> Void

        private var monitor: Any?
        private var windowNumber: Int?
        private var rectInWindow: CGRect = .zero

        init(isFocused: Bool, onOutsideClick: @escaping () -> Void) {
            self.isFocused = isFocused
            self.onOutsideClick = onOutsideClick
        }

        @MainActor
        func install(for view: NSView) {
            refreshRegion(from: view)
            guard monitor == nil else { return }

            monitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
                self?.handle(event)
                return event
            }
        }

        func uninstall() {
            if let monitor {
                NSEvent.removeMonitor(monitor)
            }
            monitor = nil
            windowNumber = nil
            rectInWindow = .zero
        }

        @MainActor
        func refreshRegion(from view: NSView) {
            windowNumber = view.window?.windowNumber
            rectInWindow = view.convert(view.bounds, to: nil)
        }

        @preconcurrency
        private func handle(_ event: NSEvent) {
            guard isFocused,
                  event.windowNumber == windowNumber,
                  !rectInWindow.contains(event.locationInWindow)
            else { return }

            onOutsideClick()
        }
    }

    final class TrackingView: NSView {
        weak var coordinator: Coordinator?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            coordinator?.refreshRegion(from: self)
        }

        override func layout() {
            super.layout()
            coordinator?.refreshRegion(from: self)
        }

        override func setFrameSize(_ newSize: NSSize) {
            super.setFrameSize(newSize)
            coordinator?.refreshRegion(from: self)
        }
    }
}
#else
struct NumericInputOutsideClickCommitter: View {
    var isFocused: Bool
    var onOutsideClick: () -> Void

    var body: some View {
        Color.clear
    }
}
#endif

private enum MeowPlannerResourceBundle {
    static func url(forResource name: String, withExtension extensionName: String, subdirectory: String) -> URL? {
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

struct FuFuAssetImage: View {
    var size: CGFloat

    var body: some View {
        Group {
            if let image = platformImage {
                #if os(macOS)
                Image(nsImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                #else
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                #endif
            } else {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: size * 0.48, weight: .bold))
                    .foregroundStyle(MeowPlannerTheme.coffee)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: MeowPlannerTheme.coffee.opacity(0.18), radius: size * 0.05, y: size * 0.025)
        .accessibilityLabel("FuFu")
    }

    #if os(macOS)
    private var platformImage: NSImage? {
        guard let url = MeowPlannerResourceBundle.url(
            forResource: "fufu-idle",
            withExtension: "png",
            subdirectory: "FuFu"
        ) else {
            return nil
        }
        return NSImage(contentsOf: url)
    }
    #else
    private var platformImage: UIImage? {
        guard let url = MeowPlannerResourceBundle.url(
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

extension View {
    func verticalPageScrollOnly() -> some View {
        #if os(macOS)
        background(VerticalOnlyScrollConfigurator())
        #else
        self
        #endif
    }

    func hiddenVerticalScrollIndicatorsOnMac() -> some View {
        #if os(macOS)
        background(HiddenVerticalScrollIndicatorConfigurator())
        #else
        self
        #endif
    }
}

#if os(macOS)
struct HiddenVerticalScrollIndicatorConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> ConfiguratorView {
        ConfiguratorView()
    }

    func updateNSView(_ nsView: ConfiguratorView, context: Context) {
        nsView.configureEnclosingScrollView()
    }

    final class ConfiguratorView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            configureEnclosingScrollView()
        }

        override func layout() {
            super.layout()
            configureEnclosingScrollView()
        }

        func configureEnclosingScrollView() {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }

                var view: NSView? = self
                while let currentView = view {
                    if let scrollView = currentView as? NSScrollView {
                        configure(scrollView)
                        return
                    }
                    view = currentView.superview
                }
            }
        }

        private func configure(_ scrollView: NSScrollView) {
            scrollView.hasVerticalScroller = false
            scrollView.autohidesScrollers = true
            scrollView.scrollerStyle = .overlay
            scrollView.usesPredominantAxisScrolling = true
        }
    }
}

struct VerticalOnlyScrollConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> ConfiguratorView {
        ConfiguratorView()
    }

    func updateNSView(_ nsView: ConfiguratorView, context: Context) {
        nsView.configureEnclosingScrollView()
    }

    final class ConfiguratorView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            configureEnclosingScrollView()
        }

        override func layout() {
            super.layout()
            configureEnclosingScrollView()
        }

        func configureEnclosingScrollView() {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }

                var view: NSView? = self
                while let currentView = view {
                    if let scrollView = currentView as? NSScrollView {
                        configure(scrollView)
                        return
                    }
                    view = currentView.superview
                }
            }
        }

        private func configure(_ scrollView: NSScrollView) {
            scrollView.hasHorizontalScroller = false
            scrollView.horizontalScrollElasticity = .none
            scrollView.usesPredominantAxisScrolling = true

            if scrollView.contentView.bounds.origin.x != 0 {
                scrollView.contentView.scroll(
                    NSPoint(x: 0, y: scrollView.contentView.bounds.origin.y)
                )
            }

            if var documentFrame = scrollView.documentView?.frame,
               documentFrame.origin.x != 0 {
                documentFrame.origin.x = 0
                scrollView.documentView?.frame = documentFrame
            }
        }
    }
}

struct HorizontalSwipeScrollDetector: NSViewRepresentable {
    var threshold: CGFloat = 18
    var onSwipe: (CGFloat) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(threshold: threshold, onSwipe: onSwipe)
    }

    func makeNSView(context: Context) -> NSView {
        let view = DetectorView()
        view.coordinator = context.coordinator
        context.coordinator.install(for: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.threshold = threshold
        context.coordinator.onSwipe = onSwipe
        context.coordinator.install(for: nsView)
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.uninstall()
    }

    final class Coordinator {
        var threshold: CGFloat
        var onSwipe: (CGFloat) -> Void

        private var monitor: Any?
        private var accumulatedHorizontal: CGFloat = 0
        private var windowNumber: Int?
        private var rectInWindow: CGRect = .zero
        private var didTriggerForCurrentSwipe = false
        private var idleResetWorkItem: DispatchWorkItem?

        init(threshold: CGFloat, onSwipe: @escaping (CGFloat) -> Void) {
            self.threshold = threshold
            self.onSwipe = onSwipe
        }

        @MainActor
        func install(for view: NSView) {
            refreshRegion(from: view)
            guard monitor == nil else { return }

            monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                self?.handle(event)
                return event
            }
        }

        func uninstall() {
            if let monitor {
                NSEvent.removeMonitor(monitor)
            }
            monitor = nil
            idleResetWorkItem?.cancel()
            idleResetWorkItem = nil
            didTriggerForCurrentSwipe = false
            accumulatedHorizontal = 0
            windowNumber = nil
            rectInWindow = .zero
        }

        @MainActor
        func refreshRegion(from view: NSView) {
            windowNumber = view.window?.windowNumber
            rectInWindow = view.convert(view.bounds, to: nil)
        }

        @preconcurrency
        private func handle(_ event: NSEvent) {
            guard event.windowNumber == windowNumber,
                  rectInWindow.contains(event.locationInWindow)
            else { return }

            if event.phase.contains(.began) || event.phase.contains(.mayBegin) {
                resetSwipeState()
            }

            if event.momentumPhase != [] {
                return
            }

            let horizontal = event.scrollingDeltaX
            let vertical = event.scrollingDeltaY
            guard abs(horizontal) > abs(vertical), abs(horizontal) > 0 else { return }

            scheduleIdleReset()
            guard !didTriggerForCurrentSwipe else { return }

            accumulatedHorizontal += horizontal
            guard abs(accumulatedHorizontal) >= threshold else { return }

            let direction = accumulatedHorizontal
            accumulatedHorizontal = 0
            didTriggerForCurrentSwipe = true
            onSwipe(direction)
        }

        private func resetSwipeState() {
            idleResetWorkItem?.cancel()
            idleResetWorkItem = nil
            accumulatedHorizontal = 0
            didTriggerForCurrentSwipe = false
        }

        private func scheduleIdleReset() {
            idleResetWorkItem?.cancel()
            let workItem = DispatchWorkItem { [weak self] in
                self?.resetSwipeState()
            }
            idleResetWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: workItem)
        }
    }

    final class DetectorView: NSView {
        weak var coordinator: Coordinator?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            coordinator?.refreshRegion(from: self)
        }

        override func layout() {
            super.layout()
            coordinator?.refreshRegion(from: self)
        }

        override func setFrameSize(_ newSize: NSSize) {
            super.setFrameSize(newSize)
            coordinator?.refreshRegion(from: self)
        }
    }
}
#else
struct HorizontalSwipeScrollDetector: View {
    var threshold: CGFloat = 18
    var onSwipe: (CGFloat) -> Void

    var body: some View {
        Color.clear
    }
}
#endif

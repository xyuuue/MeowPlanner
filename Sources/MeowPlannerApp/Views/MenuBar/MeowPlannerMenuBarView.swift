import MeowPlannerCore
import SwiftData
import SwiftUI

#if os(macOS)
import AppKit

struct MeowPlannerMenuBarLabel: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var focusTimerStore: FocusTimerStore
    var openAppKitMainWindow: () -> Void

    var body: some View {
        Group {
            if focusTimerStore.hasActiveSession {
                Text(focusTimerStore.hasActiveSession ? focusTimerStore.formattedRemainingTime : "MeowPlanner")
                    .font(.system(.body, design: .rounded).monospacedDigit())
            } else {
                Label("MeowPlanner", systemImage: "calendar.badge.clock")
            }
        }
        .onAppear {
            MainWindowLaunchCoordinator.openInitialMainWindowIfNeeded(openWindow: openMainWindow)
        }
        .onReceive(NotificationCenter.default.publisher(for: .meowPlannerRestoreMainWindow)) { _ in
            MainWindowLaunchCoordinator.openOrFocusMainWindowFromAppLifecycle(openWindow: openMainWindow)
        }
        .onReceive(NotificationCenter.default.publisher(for: .meowPlannerExternalOpenURL)) { _ in
            MainWindowLaunchCoordinator.focusSystemCreatedMainWindowFromExternalURL(openWindow: openMainWindow)
        }
    }

    private func openMainWindow() {
        openWindow(id: "main")
        openAppKitMainWindow()
    }
}

struct MeowPlannerMenuBarView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var focusTimerStore: FocusTimerStore
    var openAppKitMainWindow: () -> Void

    var body: some View {
        Group {
            if focusTimerStore.hasActiveSession {
                FocusTimerMenuPanel(
                    appLanguage: appLanguage,
                    focusTimerStore: focusTimerStore,
                    openFocusPage: openFocusPage,
                    pauseOrResume: pauseOrResume,
                    finishFromMenuBar: finishFromMenuBar
                )
            } else {
                inactiveMenu
            }
        }
    }

    private var inactiveMenu: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                openCalendarPage()
            } label: {
                Label(PlannerCopy.text(.openMeowPlanner, language: appLanguage), systemImage: "calendar")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                openFocusPage()
            } label: {
                Label(PlannerCopy.text(.focusTimer, language: appLanguage), systemImage: "timer")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                openSettingsPage()
            } label: {
                Label(PlannerCopy.text(.settings, language: appLanguage), systemImage: "gearshape")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label(PlannerCopy.text(.quitMeowPlanner, language: appLanguage), systemImage: "xmark.circle")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .keyboardShortcut("q", modifiers: [.command])
        }
        .buttonStyle(.plain)
        .padding(12)
        .frame(width: 230)
        .background(MeowPlannerTheme.fufuPlannerBackground)
    }

    private func openCalendarPage() {
        openSection(.calendar)
    }

    private func openFocusPage() {
        openSection(.focus)
    }

    private func openSettingsPage() {
        openSection(.settings)
    }

    private func openSection(_ section: AppSection) {
        MainWindowLaunchCoordinator.openOrFocusMainWindow(openWindow: openMainWindow)

        AppNavigationRequest.open(section)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            AppNavigationRequest.open(section)
        }
    }

    private func openMainWindow() {
        openWindow(id: "main")
        openAppKitMainWindow()
    }

    private func pauseOrResume() {
        if focusTimerStore.isRunning {
            focusTimerStore.pause()
        } else {
            focusTimerStore.resume()
        }
    }

    private func finishFromMenuBar() {
        guard let startedAt = focusTimerStore.startedAt else {
            return
        }

        let finishedAt = Date()
        if focusTimerStore.isRunning {
            focusTimerStore.pause(at: finishedAt)
        }

        let title = focusTimerStore.focusTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let session = FocusSession(
            title: title.isEmpty ? PlannerCopy.text(.defaultFocusBlock, language: appLanguage) : title,
            startedAt: startedAt,
            endedAt: finishedAt,
            plannedDurationSeconds: focusTimerStore.durationSeconds,
            completedDurationSeconds: focusTimerStore.completedSeconds(at: finishedAt),
            tagID: focusTimerStore.focusTagID,
            mode: focusTimerStore.focusMode
        )
        modelContext.insert(session)
        focusTimerStore.reset(defaultDurationSeconds: focusTimerStore.durationSeconds)
    }
}

private struct FocusTimerMenuPanel: View {
    var appLanguage: AppLanguage
    @ObservedObject var focusTimerStore: FocusTimerStore
    var openFocusPage: () -> Void
    var pauseOrResume: () -> Void
    var finishFromMenuBar: () -> Void

    private var progress: Double {
        let remainingSeconds = focusTimerStore.timer.remainingSeconds(at: focusTimerStore.now)
        guard focusTimerStore.durationSeconds > 0 else {
            return 0
        }
        return min(1, max(0, 1 - Double(remainingSeconds) / Double(focusTimerStore.durationSeconds)))
    }

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                FuFuAssetImage(size: 42)

                VStack(alignment: .leading, spacing: 2) {
                    Text(PlannerCopy.text(.focusTimer, language: appLanguage))
                        .font(.headline)
                        .foregroundStyle(MeowPlannerTheme.cocoa)
                    Text(displayTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Button(action: openFocusPage) {
                    Image(systemName: "arrow.up.right.square")
                }
                .buttonStyle(.borderless)
            }

            circularProgressRing

            HStack(spacing: 34) {
                Button(action: pauseOrResume) {
                    Image(systemName: focusTimerStore.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(MeowPlannerTheme.cream)
                        .frame(width: 70, height: 70)
                        .background(MeowPlannerTheme.cocoa, in: Circle())
                }
                .buttonStyle(.plain)

                Button(action: finishFromMenuBar) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(MeowPlannerTheme.cream)
                        .frame(width: 70, height: 70)
                        .background(MeowPlannerTheme.cocoa, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .frame(width: 320)
        .background(
            ZStack {
                MeowPlannerTheme.fufuPlannerBackground
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 132, weight: .bold))
                    .foregroundStyle(MeowPlannerTheme.fufuPawTint.opacity(0.08))
                    .offset(x: 82, y: 84)
            }
        )
    }

    private var circularProgressRing: some View {
        ZStack {
            Circle()
                .stroke(MeowPlannerTheme.warmCream.opacity(0.42), lineWidth: 12)

            Circle().trim(from: 0, to: progress)
                .stroke(
                    MeowPlannerTheme.blush,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 6) {
                Text(focusTimerStore.formattedRemainingTime)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(MeowPlannerTheme.cocoa)

                Text(displayTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: 170)
            }
        }
        .frame(width: 210, height: 210)
    }

    private var displayTitle: String {
        let title = focusTimerStore.focusTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? PlannerCopy.text(.defaultFocusBlock, language: appLanguage) : title
    }
}
#endif

import Foundation
import MeowPlannerCore
import SwiftData

#if canImport(WidgetKit)
import WidgetKit
#endif

enum WidgetTimelineSyncService {
    @MainActor
    static func publishSnapshotAndReload(using modelContext: ModelContext, shouldReload: Bool = true) {
        do {
            if modelContext.hasChanges {
                try modelContext.save()
            }

            let snapshot = try WidgetPlannerSnapshotBuilder.makeSnapshot(using: modelContext)

            publish(snapshot)

            if shouldReload {
                reloadWidgetTimelines()

                // Persist and reload can race with AppKit/WidgetKit state updates.
                // Re-publish the same account-scoped snapshot so retries cannot fall back
                // to the legacy default store and overwrite signed-in widget data.
                Task {
                    let retryDelays: [UInt64] = [80_000_000, 180_000_000, 300_000_000, 500_000_000, 800_000_000, 1_200_000_000]
                    for delay in retryDelays {
                        try? await Task.sleep(nanoseconds: delay)
                        await MainActor.run {
                            publish(snapshot)
                            reloadWidgetTimelines()
                        }
                    }
                }
            }
        } catch {
            assertionFailure("Failed to sync widget snapshot: \(error)")
        }
    }

    @MainActor
    static func clearSnapshotAndReload() {
        WidgetPlannerSnapshotStore.clear()
        WidgetPlannerPreferenceStore.weekStartPreference = .sunday
        WidgetPlannerPreferenceStore.showChineseCalendar = true
        reloadWidgetTimelines()
    }

    @MainActor
    private static func publish(_ snapshot: WidgetPlannerSnapshot) {
        WidgetPlannerPreferenceStore.weekStartPreference = snapshot.weekStartPreference
        WidgetPlannerPreferenceStore.showChineseCalendar = snapshot.showChineseCalendar
        WidgetPlannerSnapshotStore.save(snapshot)
    }

    @MainActor
    private static func reloadWidgetTimelines() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetConstants.todayKind)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}

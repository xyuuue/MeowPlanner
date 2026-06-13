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
                Task {
                    let retryDelays: [UInt64] = [80_000_000, 180_000_000, 300_000_000, 500_000_000, 800_000_000, 1_200_000_000]
                    for delay in retryDelays {
                        try? await Task.sleep(nanoseconds: delay)
                        await MainActor.run {
                            refreshSnapshotFromPersistentStore()
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
    private static func refreshSnapshotFromPersistentStore() {
        do {
            let snapshot = try WidgetPlannerSnapshotBuilder.makeSnapshotFromPersistentStore()
            publish(snapshot)
        } catch {
            assertionFailure("Failed to refresh widget snapshot from persistent store: \(error)")
        }
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

import FirebaseAuth
import FirebaseFirestore
import Foundation
import MeowPlannerCore
import SwiftData

@MainActor
final class FirestoreAppDataSyncService {
    static let shared = FirestoreAppDataSyncService()

    private let database: Firestore
    private let defaults: UserDefaults
    private var syncTask: Task<Void, Never>?
    private var isSyncing = false

    init(
        database: Firestore = Firestore.firestore(),
        defaults: UserDefaults = .standard
    ) {
        self.database = database
        self.defaults = defaults
    }

    func scheduleSync(for userID: String?, using modelContext: ModelContext) {
        guard let userID else {
            stopSync()
            return
        }
        guard currentUserID == userID else {
            stopSync()
            return
        }

        syncTask?.cancel()
        syncTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else {
                return
            }
            await syncNow(for: userID, using: modelContext)
        }
    }

    func stopSync() {
        syncTask?.cancel()
        syncTask = nil
        isSyncing = false
    }

    private var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }

    private func syncNow(for userID: String, using modelContext: ModelContext) async {
        guard !isSyncing,
              currentUserID == userID
        else {
            return
        }

        isSyncing = true
        defer {
            isSyncing = false
        }

        stageLocalDeletions(for: userID, from: modelContext)
        await downloadAllCollections(for: userID, into: modelContext)
        uploadAllLocalData(for: userID, from: modelContext)
    }

    private func downloadAllCollections(for userID: String, into modelContext: ModelContext) async {
        for collection in CloudDataCollection.allCases {
            guard let collectionPath = try? collection.collectionPath(userID: userID) else {
                continue
            }

            do {
                let snapshot = try await database.collection(collectionPath).getDocuments()
                applyDocuments(snapshot.documents, collection: collection, userID: userID, to: modelContext)
            } catch {
                continue
            }
        }
    }

    private func stageLocalDeletions(for userID: String, from modelContext: ModelContext) {
        let records = localRecords(from: modelContext)
        let recordsByCollection = Dictionary(grouping: records, by: \.collection)

        for collection in CloudDataCollection.allCases {
            let collectionRecords = recordsByCollection[collection, default: []]
            let currentIDs = Set(collectionRecords.map(\.documentID))
            let previousIDs = uploadedDocumentIDs(userID: userID, collection: collection)
            let newlyDeletedIDs = Set(CloudDeletionTracker.missingUploadedDocumentIDs(
                previousUploadedIDs: previousIDs,
                currentLocalIDs: currentIDs
            ))
            let pendingIDs = pendingDeletedDocumentIDs(userID: userID, collection: collection)
            let deletedIDs = pendingIDs.union(newlyDeletedIDs)

            guard !deletedIDs.isEmpty else {
                continue
            }

            storePendingDeletedDocumentIDs(deletedIDs, userID: userID, collection: collection)
            for documentID in deletedIDs.sorted() {
                writeDeletedRecord(userID: userID, collection: collection, documentID: documentID)
            }
        }
    }

    private func uploadAllLocalData(for userID: String, from modelContext: ModelContext) {
        let records = localRecords(from: modelContext)
        let recordsByCollection = Dictionary(grouping: records, by: \.collection)

        for collection in CloudDataCollection.allCases {
            let collectionRecords = recordsByCollection[collection, default: []]
            let currentIDs = Set(collectionRecords.map(\.documentID))
            let previousIDs = uploadedDocumentIDs(userID: userID, collection: collection)
            let deletedIDs = CloudDeletionTracker.missingUploadedDocumentIDs(
                previousUploadedIDs: previousIDs,
                currentLocalIDs: currentIDs
            )
            let pendingIDs = pendingDeletedDocumentIDs(userID: userID, collection: collection)
            let allDeletedIDs = pendingIDs.union(deletedIDs)

            if !allDeletedIDs.isEmpty {
                storePendingDeletedDocumentIDs(allDeletedIDs, userID: userID, collection: collection)
            }

            for documentID in allDeletedIDs.sorted() {
                writeDeletedRecord(userID: userID, collection: collection, documentID: documentID)
            }

            for record in collectionRecords {
                writeRecord(userID: userID, record: record)
            }

            storeUploadedDocumentIDs(currentIDs, userID: userID, collection: collection)
        }
    }

    private func writeRecord(userID: String, record: FirestoreAppDataRecord) {
        guard let path = try? record.collection.documentPath(userID: userID, documentID: record.documentID) else {
            return
        }
        database.document(path).setData(record.data, merge: true)
    }

    private func writeDeletedRecord(userID: String, collection: CloudDataCollection, documentID: String) {
        guard let path = try? collection.documentPath(userID: userID, documentID: documentID) else {
            return
        }
        database.document(path).setData([
            "id": documentID,
            "isDeleted": true,
            "updatedAt": Date()
        ], merge: true)
    }

    private func uploadedDocumentIDs(userID: String, collection: CloudDataCollection) -> Set<String> {
        let key = uploadedIDsStorageKey(userID: userID, collection: collection)
        guard let values = defaults.array(forKey: key) as? [String] else {
            return []
        }
        return Set(values)
    }

    private func storeUploadedDocumentIDs(_ ids: Set<String>, userID: String, collection: CloudDataCollection) {
        let key = uploadedIDsStorageKey(userID: userID, collection: collection)
        defaults.set(ids.sorted(), forKey: key)
    }

    private func uploadedIDsStorageKey(userID: String, collection: CloudDataCollection) -> String {
        "meowplanner.firestore.uploadedIDs.\(userID).\(collection.rawValue)"
    }

    private func pendingDeletedDocumentIDs(userID: String, collection: CloudDataCollection) -> Set<String> {
        let key = pendingDeletedIDsStorageKey(userID: userID, collection: collection)
        guard let values = defaults.array(forKey: key) as? [String] else {
            return []
        }
        return Set(values)
    }

    private func storePendingDeletedDocumentIDs(_ ids: Set<String>, userID: String, collection: CloudDataCollection) {
        let key = pendingDeletedIDsStorageKey(userID: userID, collection: collection)
        defaults.set(ids.sorted(), forKey: key)
    }

    private func clearPendingDeletedDocumentID(_ documentID: String, userID: String, collection: CloudDataCollection) {
        var ids = pendingDeletedDocumentIDs(userID: userID, collection: collection)
        ids.remove(documentID)
        storePendingDeletedDocumentIDs(ids, userID: userID, collection: collection)
    }

    private func pendingDeletedIDsStorageKey(userID: String, collection: CloudDataCollection) -> String {
        "meowplanner.firestore.pendingDeletedIDs.\(userID).\(collection.rawValue)"
    }
}

private struct FirestoreAppDataRecord {
    var collection: CloudDataCollection
    var documentID: String
    var data: [String: Any]
}

private extension FirestoreAppDataSyncService {
    func localRecords(from modelContext: ModelContext) -> [FirestoreAppDataRecord] {
        records(for: fetch(PlannerEvent.self, in: modelContext))
            + records(for: fetch(TodoGroup.self, in: modelContext))
            + records(for: fetch(TodoItem.self, in: modelContext))
            + records(for: fetch(Habit.self, in: modelContext))
            + records(for: fetch(HabitCheckIn.self, in: modelContext))
            + records(for: fetch(FocusTag.self, in: modelContext))
            + records(for: fetch(FocusSession.self, in: modelContext))
            + records(for: localPreferences(in: modelContext))
            + records(for: fetch(CourseTimetable.self, in: modelContext))
            + records(for: fetch(CoursePeriod.self, in: modelContext))
            + records(for: fetch(Course.self, in: modelContext))
            + records(for: fetch(CourseSession.self, in: modelContext))
    }

    func fetch<T: PersistentModel>(_ type: T.Type, in modelContext: ModelContext) -> [T] {
        (try? modelContext.fetch(FetchDescriptor<T>())) ?? []
    }

    func localPreferences(in modelContext: ModelContext) -> [PlannerPreference] {
        let preferences = fetch(PlannerPreference.self, in: modelContext)
        return preferences.isEmpty ? [PlannerPreference.defaults] : preferences
    }

    func baseRecord(
        collection: CloudDataCollection,
        id: String,
        updatedAt: Date,
        fields: [String: Any]
    ) -> FirestoreAppDataRecord {
        var data = fields
        data["id"] = id
        data["updatedAt"] = updatedAt
        data["isDeleted"] = false
        return FirestoreAppDataRecord(collection: collection, documentID: id, data: data)
    }

    func records(for events: [PlannerEvent]) -> [FirestoreAppDataRecord] {
        events.map { event in
            baseRecord(
                collection: .events,
                id: event.id.uuidString,
                updatedAt: event.updatedAt,
                fields: [
                    "title": event.title,
                    "startDate": event.startDate,
                    "endDate": event.endDate as Any? ?? NSNull(),
                    "isAllDay": event.isAllDay,
                    "notes": event.notes,
                    "isCompleted": event.isCompleted,
                    "completedAt": event.completedAt as Any? ?? NSNull(),
                    "reminderOffsetMinutes": event.reminderOffsetMinutes as Any? ?? NSNull(),
                    "repeatRuleDataBase64": event.repeatRuleData?.base64EncodedString() as Any? ?? NSNull(),
                    "tagName": event.tagName,
                    "colorHex": event.colorHex,
                    "createdAt": event.createdAt
                ]
            )
        }
    }

    func records(for groups: [TodoGroup]) -> [FirestoreAppDataRecord] {
        groups.map { group in
            baseRecord(
                collection: .todoGroups,
                id: group.id.uuidString,
                updatedAt: group.updatedAt,
                fields: [
                    "name": group.name,
                    "colorHex": group.colorHex,
                    "createdAt": group.createdAt
                ]
            )
        }
    }

    func records(for todos: [TodoItem]) -> [FirestoreAppDataRecord] {
        todos.map { todo in
            baseRecord(
                collection: .todos,
                id: todo.id.uuidString,
                updatedAt: todo.updatedAt,
                fields: [
                    "title": todo.title,
                    "notes": todo.notes,
                    "dueDate": todo.dueDate as Any? ?? NSNull(),
                    "groupID": todo.groupID?.uuidString as Any? ?? NSNull(),
                    "sortOrder": todo.sortOrder as Any? ?? NSNull(),
                    "isCompleted": todo.isCompleted,
                    "completedAt": todo.completedAt as Any? ?? NSNull(),
                    "reminderDate": todo.reminderDate as Any? ?? NSNull(),
                    "createdAt": todo.createdAt
                ]
            )
        }
    }

    func records(for habits: [Habit]) -> [FirestoreAppDataRecord] {
        habits.map { habit in
            baseRecord(
                collection: .habits,
                id: habit.id.uuidString,
                updatedAt: habit.archivedAt ?? habit.createdAt,
                fields: [
                    "title": habit.title,
                    "symbolName": habit.symbolName,
                    "colorHex": habit.colorHex,
                    "reminderDate": habit.reminderDate as Any? ?? NSNull(),
                    "createdAt": habit.createdAt,
                    "archivedAt": habit.archivedAt as Any? ?? NSNull()
                ]
            )
        }
    }

    func records(for checkIns: [HabitCheckIn]) -> [FirestoreAppDataRecord] {
        checkIns.map { checkIn in
            baseRecord(
                collection: .habitCheckIns,
                id: checkIn.id.uuidString,
                updatedAt: checkIn.createdAt,
                fields: [
                    "habitID": checkIn.habitID.uuidString,
                    "date": checkIn.date,
                    "note": checkIn.note,
                    "createdAt": checkIn.createdAt
                ]
            )
        }
    }

    func records(for tags: [FocusTag]) -> [FirestoreAppDataRecord] {
        tags.map { tag in
            baseRecord(
                collection: .focusTags,
                id: tag.id.uuidString,
                updatedAt: tag.createdAt,
                fields: [
                    "name": tag.name,
                    "colorHex": tag.colorHex,
                    "createdAt": tag.createdAt,
                    "sortOrder": tag.sortOrder
                ]
            )
        }
    }

    func records(for sessions: [FocusSession]) -> [FirestoreAppDataRecord] {
        sessions.map { session in
            baseRecord(
                collection: .focusSessions,
                id: session.id.uuidString,
                updatedAt: session.endedAt ?? session.startedAt,
                fields: [
                    "title": session.title,
                    "startedAt": session.startedAt,
                    "endedAt": session.endedAt as Any? ?? NSNull(),
                    "plannedDurationSeconds": session.plannedDurationSeconds,
                    "completedDurationSeconds": session.completedDurationSeconds,
                    "linkedTodoID": session.linkedTodoID?.uuidString as Any? ?? NSNull(),
                    "linkedHabitID": session.linkedHabitID?.uuidString as Any? ?? NSNull(),
                    "tagID": session.tagID?.uuidString as Any? ?? NSNull(),
                    "modeRawValue": session.modeRawValue
                ]
            )
        }
    }

    func records(for preferences: [PlannerPreference]) -> [FirestoreAppDataRecord] {
        preferences.map { preference in
            let languageUpdatedAt = languageUpdatedAtDate()
            let appearanceUpdatedAt = appearanceUpdatedAtDate()

            return baseRecord(
                collection: .preferences,
                id: preference.id,
                updatedAt: preference.updatedAt,
                fields: [
                    "localeIdentifier": preference.localeIdentifier,
                    "defaultFocusMinutes": preference.defaultFocusMinutes,
                    "cloudKitContainerIdentifier": preference.cloudKitContainerIdentifier,
                    "showFuFuTheme": preference.showFuFuTheme,
                    "notificationLeadMinutes": preference.notificationLeadMinutes,
                    "weekStartDayRawValue": preference.weekStartDayRawValue,
                    "localRemindersEnabled": preference.localRemindersEnabled,
                    "eventColorHexList": preference.eventColorHexList,
                    "eventTagNameList": preference.eventTagNameList,
                    "defaultEventIsAllDay": preference.defaultEventIsAllDay,
                    "showCompletedSchedules": preference.showCompletedSchedules,
                    "completedSchedulesUseStrikethrough": preference.completedSchedulesUseStrikethrough,
                    "showChineseCalendar": preference.showChineseCalendar,
                    "scheduleTimeCollapseEnabled": preference.scheduleTimeCollapseEnabled,
                    "scheduleCollapsedStartHour": preference.scheduleCollapsedStartHour,
                    "scheduleCollapsedEndHour": preference.scheduleCollapsedEndHour,
                    "timeDisplayRawValue": preference.timeDisplayRawValue,
                    "appLanguageID": defaults.string(forKey: AppLanguage.storageKey) ?? AppLanguage.english.rawValue,
                    "appLanguageUpdatedAt": languageUpdatedAt,
                    "appearanceID": defaults.string(forKey: AppAppearancePreference.storageKey) ?? AppAppearancePreference.system.rawValue,
                    "appearanceUpdatedAt": appearanceUpdatedAt,
                    "showDockIcon": defaults.object(forKey: AppDockIconController.storageKey) as? Bool ?? AppDockIconController.defaultShowDockIcon,
                    "sidebarSectionOrder": defaults.string(forKey: "meowplanner.sidebar.sectionOrder") ?? AppSection.defaultSidebarOrderStorageValue
                ]
            )
        }
    }

    func records(for timetables: [CourseTimetable]) -> [FirestoreAppDataRecord] {
        timetables.map { timetable in
            baseRecord(
                collection: .courseTimetables,
                id: timetable.id.uuidString,
                updatedAt: timetable.updatedAt,
                fields: [
                    "name": timetable.name,
                    "semesterStartDate": timetable.semesterStartDate,
                    "semesterWeeks": timetable.semesterWeeks,
                    "periodsPerDay": timetable.periodsPerDay,
                    "lessonDurationMinutes": timetable.lessonDurationMinutes,
                    "breakDurationMinutes": timetable.breakDurationMinutes,
                    "skipHolidays": timetable.skipHolidays,
                    "createdAt": timetable.createdAt
                ]
            )
        }
    }

    func records(for periods: [CoursePeriod]) -> [FirestoreAppDataRecord] {
        periods.map { period in
            baseRecord(
                collection: .coursePeriods,
                id: period.id.uuidString,
                updatedAt: Date(timeIntervalSince1970: 0),
                fields: [
                    "timetableID": period.timetableID.uuidString,
                    "index": period.index,
                    "startMinutesFromMidnight": period.startMinutesFromMidnight,
                    "endMinutesFromMidnight": period.endMinutesFromMidnight
                ]
            )
        }
    }

    func records(for courses: [Course]) -> [FirestoreAppDataRecord] {
        courses.map { course in
            baseRecord(
                collection: .courses,
                id: course.id.uuidString,
                updatedAt: course.updatedAt,
                fields: [
                    "timetableID": course.timetableID.uuidString,
                    "name": course.name,
                    "colorHex": course.colorHex,
                    "teacherName": course.teacherName,
                    "location": course.location,
                    "createdAt": course.createdAt
                ]
            )
        }
    }

    func records(for sessions: [CourseSession]) -> [FirestoreAppDataRecord] {
        sessions.map { session in
            baseRecord(
                collection: .courseSessions,
                id: session.id.uuidString,
                updatedAt: Date(timeIntervalSince1970: 0),
                fields: [
                    "courseID": session.courseID.uuidString,
                    "weekday": session.weekday,
                    "startPeriodIndex": session.startPeriodIndex,
                    "endPeriodIndex": session.endPeriodIndex,
                    "startWeek": session.startWeek,
                    "endWeek": session.endWeek
                ]
            )
        }
    }
}

private extension FirestoreAppDataSyncService {
    func applyDocuments(
        _ documents: [QueryDocumentSnapshot],
        collection: CloudDataCollection,
        userID: String,
        to modelContext: ModelContext
    ) {
        switch collection {
        case .events:
            applyEvents(documents, userID: userID, to: modelContext)
        case .todoGroups:
            applyTodoGroups(documents, userID: userID, to: modelContext)
        case .todos:
            applyTodos(documents, userID: userID, to: modelContext)
        case .habits:
            applyHabits(documents, userID: userID, to: modelContext)
        case .habitCheckIns:
            applyHabitCheckIns(documents, userID: userID, to: modelContext)
        case .focusTags:
            applyFocusTags(documents, userID: userID, to: modelContext)
        case .focusSessions:
            applyFocusSessions(documents, userID: userID, to: modelContext)
        case .preferences:
            applyPreferences(documents, userID: userID, to: modelContext)
        case .courseTimetables:
            applyCourseTimetables(documents, userID: userID, to: modelContext)
        case .coursePeriods:
            applyCoursePeriods(documents, userID: userID, to: modelContext)
        case .courses:
            applyCourses(documents, userID: userID, to: modelContext)
        case .courseSessions:
            applyCourseSessions(documents, userID: userID, to: modelContext)
        }
    }

    func applyEvents(_ documents: [QueryDocumentSnapshot], userID: String, to modelContext: ModelContext) {
        var local = Dictionary(uniqueKeysWithValues: fetch(PlannerEvent.self, in: modelContext).map { ($0.id, $0) })
        for document in documents {
            let data = document.data()
            guard let id = data.uuid("id", fallback: document.documentID) else {
                continue
            }
            let existing = local[id]
            if data.bool("isDeleted") {
                clearPendingDeletedDocumentID(id.uuidString, userID: userID, collection: .events)
                if let existing,
                   shouldApplyRemoteDeletion(existingUpdatedAt: existing.updatedAt, remoteData: data) {
                    modelContext.delete(existing)
                    local.removeValue(forKey: id)
                }
                continue
            }
            guard shouldApplyRemoteRecord(
                existingUpdatedAt: existing?.updatedAt,
                remoteData: data,
                userID: userID,
                collection: .events,
                documentID: id.uuidString
            ) else {
                continue
            }
            let event = existing ?? PlannerEvent(id: id, title: "", startDate: data.date("startDate") ?? Date())
            event.title = data.string("title") ?? event.title
            event.startDate = data.date("startDate") ?? event.startDate
            event.endDate = data.date("endDate")
            event.isAllDay = data.bool("isAllDay")
            event.notes = data.string("notes") ?? ""
            event.isCompleted = data.bool("isCompleted")
            event.completedAt = data.date("completedAt")
            event.reminderOffsetMinutes = data.optionalInt("reminderOffsetMinutes")
            event.repeatRuleData = data.base64Data("repeatRuleDataBase64")
            event.tagName = data.string("tagName") ?? ""
            event.colorHex = data.string("colorHex") ?? PlannerPreference.defaultEventColorHexes[0]
            event.createdAt = data.date("createdAt") ?? event.createdAt
            event.updatedAt = data.date("updatedAt") ?? event.updatedAt
            if local[id] == nil {
                modelContext.insert(event)
                local[id] = event
            }
        }
        saveAfterApplyingCloudData(modelContext)
    }

    func applyTodoGroups(_ documents: [QueryDocumentSnapshot], userID: String, to modelContext: ModelContext) {
        var local = Dictionary(uniqueKeysWithValues: fetch(TodoGroup.self, in: modelContext).map { ($0.id, $0) })
        for document in documents {
            let data = document.data()
            guard let id = data.uuid("id", fallback: document.documentID) else {
                continue
            }
            let existing = local[id]
            if data.bool("isDeleted") {
                clearPendingDeletedDocumentID(id.uuidString, userID: userID, collection: .todoGroups)
                if let existing,
                   shouldApplyRemoteDeletion(existingUpdatedAt: existing.updatedAt, remoteData: data) {
                    modelContext.delete(existing)
                    local.removeValue(forKey: id)
                }
                continue
            }
            guard shouldApplyRemoteRecord(
                existingUpdatedAt: existing?.updatedAt,
                remoteData: data,
                userID: userID,
                collection: .todoGroups,
                documentID: id.uuidString
            ) else {
                continue
            }
            let group = existing ?? TodoGroup(id: id, name: data.string("name") ?? "")
            group.name = data.string("name") ?? group.name
            group.colorHex = data.string("colorHex") ?? TodoGroup.defaultColorHex
            group.createdAt = data.date("createdAt") ?? group.createdAt
            group.updatedAt = data.date("updatedAt") ?? group.updatedAt
            if local[id] == nil {
                modelContext.insert(group)
                local[id] = group
            }
        }
        saveAfterApplyingCloudData(modelContext)
    }

    func applyTodos(_ documents: [QueryDocumentSnapshot], userID: String, to modelContext: ModelContext) {
        var local = Dictionary(uniqueKeysWithValues: fetch(TodoItem.self, in: modelContext).map { ($0.id, $0) })
        for document in documents {
            let data = document.data()
            guard let id = data.uuid("id", fallback: document.documentID) else {
                continue
            }
            let existing = local[id]
            if data.bool("isDeleted") {
                clearPendingDeletedDocumentID(id.uuidString, userID: userID, collection: .todos)
                if let existing,
                   shouldApplyRemoteDeletion(existingUpdatedAt: existing.updatedAt, remoteData: data) {
                    modelContext.delete(existing)
                    local.removeValue(forKey: id)
                }
                continue
            }
            guard shouldApplyRemoteRecord(
                existingUpdatedAt: existing?.updatedAt,
                remoteData: data,
                userID: userID,
                collection: .todos,
                documentID: id.uuidString
            ) else {
                continue
            }
            let todo = existing ?? TodoItem(id: id, title: data.string("title") ?? "")
            todo.title = data.string("title") ?? todo.title
            todo.notes = data.string("notes") ?? ""
            todo.dueDate = data.date("dueDate")
            todo.groupID = data.uuid("groupID")
            todo.sortOrder = data.optionalInt("sortOrder")
            todo.isCompleted = data.bool("isCompleted")
            todo.completedAt = data.date("completedAt")
            todo.reminderDate = data.date("reminderDate")
            todo.createdAt = data.date("createdAt") ?? todo.createdAt
            todo.updatedAt = data.date("updatedAt") ?? todo.updatedAt
            if local[id] == nil {
                modelContext.insert(todo)
                local[id] = todo
            }
        }
        saveAfterApplyingCloudData(modelContext)
    }

    func applyHabits(_ documents: [QueryDocumentSnapshot], userID: String, to modelContext: ModelContext) {
        var local = Dictionary(uniqueKeysWithValues: fetch(Habit.self, in: modelContext).map { ($0.id, $0) })
        for document in documents {
            let data = document.data()
            guard let id = data.uuid("id", fallback: document.documentID) else {
                continue
            }
            if data.bool("isDeleted") {
                clearPendingDeletedDocumentID(id.uuidString, userID: userID, collection: .habits)
                if let existing = local[id] {
                    modelContext.delete(existing)
                    local.removeValue(forKey: id)
                }
                continue
            }
            guard shouldApplyRemoteRecord(
                existingUpdatedAt: nil,
                remoteData: data,
                userID: userID,
                collection: .habits,
                documentID: id.uuidString
            ) else {
                continue
            }
            let habit = local[id] ?? Habit(id: id, title: data.string("title") ?? "")
            habit.title = data.string("title") ?? habit.title
            habit.symbolName = data.string("symbolName") ?? "pawprint.fill"
            habit.colorHex = data.string("colorHex") ?? "#4F6F8F"
            habit.reminderDate = data.date("reminderDate")
            habit.createdAt = data.date("createdAt") ?? habit.createdAt
            habit.archivedAt = data.date("archivedAt")
            if local[id] == nil {
                modelContext.insert(habit)
                local[id] = habit
            }
        }
        saveAfterApplyingCloudData(modelContext)
    }

    func applyHabitCheckIns(_ documents: [QueryDocumentSnapshot], userID: String, to modelContext: ModelContext) {
        var local = Dictionary(uniqueKeysWithValues: fetch(HabitCheckIn.self, in: modelContext).map { ($0.id, $0) })
        for document in documents {
            let data = document.data()
            guard let id = data.uuid("id", fallback: document.documentID),
                  let habitID = data.uuid("habitID")
            else {
                continue
            }
            if data.bool("isDeleted") {
                clearPendingDeletedDocumentID(id.uuidString, userID: userID, collection: .habitCheckIns)
                if let existing = local[id] {
                    modelContext.delete(existing)
                    local.removeValue(forKey: id)
                }
                continue
            }
            guard shouldApplyRemoteRecord(
                existingUpdatedAt: nil,
                remoteData: data,
                userID: userID,
                collection: .habitCheckIns,
                documentID: id.uuidString
            ) else {
                continue
            }
            let checkIn = local[id] ?? HabitCheckIn(id: id, habitID: habitID, date: data.date("date") ?? Date())
            checkIn.habitID = habitID
            checkIn.date = data.date("date") ?? checkIn.date
            checkIn.note = data.string("note") ?? ""
            checkIn.createdAt = data.date("createdAt") ?? checkIn.createdAt
            if local[id] == nil {
                modelContext.insert(checkIn)
                local[id] = checkIn
            }
        }
        saveAfterApplyingCloudData(modelContext)
    }

    func applyFocusTags(_ documents: [QueryDocumentSnapshot], userID: String, to modelContext: ModelContext) {
        var local = Dictionary(uniqueKeysWithValues: fetch(FocusTag.self, in: modelContext).map { ($0.id, $0) })
        for document in documents {
            let data = document.data()
            guard let id = data.uuid("id", fallback: document.documentID) else {
                continue
            }
            if data.bool("isDeleted") {
                clearPendingDeletedDocumentID(id.uuidString, userID: userID, collection: .focusTags)
                if let existing = local[id] {
                    modelContext.delete(existing)
                    local.removeValue(forKey: id)
                }
                continue
            }
            guard shouldApplyRemoteRecord(
                existingUpdatedAt: nil,
                remoteData: data,
                userID: userID,
                collection: .focusTags,
                documentID: id.uuidString
            ) else {
                continue
            }
            let tag = local[id] ?? FocusTag(id: id, name: data.string("name") ?? "")
            tag.name = data.string("name") ?? tag.name
            tag.colorHex = data.string("colorHex") ?? "#71B7ED"
            tag.createdAt = data.date("createdAt") ?? tag.createdAt
            tag.sortOrder = data.int("sortOrder") ?? tag.sortOrder
            if local[id] == nil {
                modelContext.insert(tag)
                local[id] = tag
            }
        }
        saveAfterApplyingCloudData(modelContext)
    }

    func applyFocusSessions(_ documents: [QueryDocumentSnapshot], userID: String, to modelContext: ModelContext) {
        var local = Dictionary(uniqueKeysWithValues: fetch(FocusSession.self, in: modelContext).map { ($0.id, $0) })
        for document in documents {
            let data = document.data()
            guard let id = data.uuid("id", fallback: document.documentID) else {
                continue
            }
            if data.bool("isDeleted") {
                clearPendingDeletedDocumentID(id.uuidString, userID: userID, collection: .focusSessions)
                if let existing = local[id] {
                    modelContext.delete(existing)
                    local.removeValue(forKey: id)
                }
                continue
            }
            guard shouldApplyRemoteRecord(
                existingUpdatedAt: nil,
                remoteData: data,
                userID: userID,
                collection: .focusSessions,
                documentID: id.uuidString
            ) else {
                continue
            }
            let session = local[id] ?? FocusSession(id: id, title: data.string("title") ?? "", startedAt: data.date("startedAt") ?? Date())
            session.title = data.string("title") ?? session.title
            session.startedAt = data.date("startedAt") ?? session.startedAt
            session.endedAt = data.date("endedAt")
            session.plannedDurationSeconds = data.int("plannedDurationSeconds") ?? session.plannedDurationSeconds
            session.completedDurationSeconds = data.int("completedDurationSeconds") ?? session.completedDurationSeconds
            session.linkedTodoID = data.uuid("linkedTodoID")
            session.linkedHabitID = data.uuid("linkedHabitID")
            session.tagID = data.uuid("tagID")
            session.modeRawValue = data.string("modeRawValue") ?? FocusMode.countdown.rawValue
            if local[id] == nil {
                modelContext.insert(session)
                local[id] = session
            }
        }
        saveAfterApplyingCloudData(modelContext)
    }

    func applyPreferences(_ documents: [QueryDocumentSnapshot], userID: String, to modelContext: ModelContext) {
        var local = Dictionary(uniqueKeysWithValues: fetch(PlannerPreference.self, in: modelContext).map { ($0.id, $0) })
        for document in documents {
            let data = document.data()
            let id = data.string("id") ?? document.documentID
            if data.bool("isDeleted") {
                clearPendingDeletedDocumentID(id, userID: userID, collection: .preferences)
                if let existing = local[id] {
                    modelContext.delete(existing)
                    local.removeValue(forKey: id)
                }
                continue
            }
            guard shouldApplyRemoteRecord(
                existingUpdatedAt: local[id]?.updatedAt,
                remoteData: data,
                userID: userID,
                collection: .preferences,
                documentID: id
            ) else {
                continue
            }
            let preference = local[id] ?? PlannerPreference(id: id)
            preference.localeIdentifier = data.string("localeIdentifier") ?? preference.localeIdentifier
            preference.defaultFocusMinutes = data.int("defaultFocusMinutes") ?? preference.defaultFocusMinutes
            preference.cloudKitContainerIdentifier = data.string("cloudKitContainerIdentifier") ?? preference.cloudKitContainerIdentifier
            preference.showFuFuTheme = data.bool("showFuFuTheme", default: preference.showFuFuTheme)
            preference.notificationLeadMinutes = data.int("notificationLeadMinutes") ?? preference.notificationLeadMinutes
            preference.weekStartDayRawValue = data.int("weekStartDayRawValue") ?? preference.weekStartDayRawValue
            preference.localRemindersEnabled = data.bool("localRemindersEnabled", default: preference.localRemindersEnabled)
            preference.eventColorHexList = data.string("eventColorHexList") ?? preference.eventColorHexList
            preference.eventTagNameList = data.string("eventTagNameList") ?? preference.eventTagNameList
            preference.defaultEventIsAllDay = data.bool("defaultEventIsAllDay", default: preference.defaultEventIsAllDay)
            preference.showCompletedSchedules = data.bool("showCompletedSchedules", default: preference.showCompletedSchedules)
            preference.completedSchedulesUseStrikethrough = data.bool("completedSchedulesUseStrikethrough", default: preference.completedSchedulesUseStrikethrough)
            preference.showChineseCalendar = data.bool("showChineseCalendar", default: preference.showChineseCalendar)
            preference.scheduleTimeCollapseEnabled = data.bool("scheduleTimeCollapseEnabled", default: preference.scheduleTimeCollapseEnabled)
            preference.scheduleCollapsedStartHour = data.int("scheduleCollapsedStartHour") ?? preference.scheduleCollapsedStartHour
            preference.scheduleCollapsedEndHour = data.int("scheduleCollapsedEndHour") ?? preference.scheduleCollapsedEndHour
            preference.timeDisplayRawValue = data.string("timeDisplayRawValue") ?? preference.timeDisplayRawValue
            preference.updatedAt = data.date("updatedAt") ?? preference.updatedAt
            applySyncedUserDefaults(from: data)
            if local[id] == nil {
                modelContext.insert(preference)
                local[id] = preference
            }
        }
        saveAfterApplyingCloudData(modelContext)
    }

    func applyCourseTimetables(_ documents: [QueryDocumentSnapshot], userID: String, to modelContext: ModelContext) {
        var local = Dictionary(uniqueKeysWithValues: fetch(CourseTimetable.self, in: modelContext).map { ($0.id, $0) })
        for document in documents {
            let data = document.data()
            guard let id = data.uuid("id", fallback: document.documentID) else {
                continue
            }
            let existing = local[id]
            if data.bool("isDeleted") {
                clearPendingDeletedDocumentID(id.uuidString, userID: userID, collection: .courseTimetables)
                if let existing,
                   shouldApplyRemoteDeletion(existingUpdatedAt: existing.updatedAt, remoteData: data) {
                    modelContext.delete(existing)
                    local.removeValue(forKey: id)
                }
                continue
            }
            guard shouldApplyRemoteRecord(
                existingUpdatedAt: existing?.updatedAt,
                remoteData: data,
                userID: userID,
                collection: .courseTimetables,
                documentID: id.uuidString
            ) else {
                continue
            }
            let timetable = existing ?? CourseTimetable(id: id, name: data.string("name") ?? "", semesterStartDate: data.date("semesterStartDate") ?? Date())
            timetable.name = data.string("name") ?? timetable.name
            timetable.semesterStartDate = data.date("semesterStartDate") ?? timetable.semesterStartDate
            timetable.semesterWeeks = data.int("semesterWeeks") ?? timetable.semesterWeeks
            timetable.periodsPerDay = data.int("periodsPerDay") ?? timetable.periodsPerDay
            timetable.lessonDurationMinutes = data.int("lessonDurationMinutes") ?? timetable.lessonDurationMinutes
            timetable.breakDurationMinutes = data.int("breakDurationMinutes") ?? timetable.breakDurationMinutes
            timetable.skipHolidays = data.bool("skipHolidays", default: timetable.skipHolidays)
            timetable.createdAt = data.date("createdAt") ?? timetable.createdAt
            timetable.updatedAt = data.date("updatedAt") ?? timetable.updatedAt
            if local[id] == nil {
                modelContext.insert(timetable)
                local[id] = timetable
            }
        }
        saveAfterApplyingCloudData(modelContext)
    }

    func applyCoursePeriods(_ documents: [QueryDocumentSnapshot], userID: String, to modelContext: ModelContext) {
        var local = Dictionary(uniqueKeysWithValues: fetch(CoursePeriod.self, in: modelContext).map { ($0.id, $0) })
        for document in documents {
            let data = document.data()
            guard let id = data.uuid("id", fallback: document.documentID),
                  let timetableID = data.uuid("timetableID")
            else {
                continue
            }
            if data.bool("isDeleted") {
                clearPendingDeletedDocumentID(id.uuidString, userID: userID, collection: .coursePeriods)
                if let existing = local[id] {
                    modelContext.delete(existing)
                    local.removeValue(forKey: id)
                }
                continue
            }
            guard shouldApplyRemoteRecord(
                existingUpdatedAt: nil,
                remoteData: data,
                userID: userID,
                collection: .coursePeriods,
                documentID: id.uuidString
            ) else {
                continue
            }
            let period = local[id] ?? CoursePeriod(
                id: id,
                timetableID: timetableID,
                index: data.int("index") ?? 1,
                startMinutesFromMidnight: data.int("startMinutesFromMidnight") ?? 0,
                endMinutesFromMidnight: data.int("endMinutesFromMidnight") ?? 1
            )
            period.timetableID = timetableID
            period.index = data.int("index") ?? period.index
            period.startMinutesFromMidnight = data.int("startMinutesFromMidnight") ?? period.startMinutesFromMidnight
            period.endMinutesFromMidnight = data.int("endMinutesFromMidnight") ?? period.endMinutesFromMidnight
            if local[id] == nil {
                modelContext.insert(period)
                local[id] = period
            }
        }
        saveAfterApplyingCloudData(modelContext)
    }

    func applyCourses(_ documents: [QueryDocumentSnapshot], userID: String, to modelContext: ModelContext) {
        var local = Dictionary(uniqueKeysWithValues: fetch(Course.self, in: modelContext).map { ($0.id, $0) })
        for document in documents {
            let data = document.data()
            guard let id = data.uuid("id", fallback: document.documentID),
                  let timetableID = data.uuid("timetableID")
            else {
                continue
            }
            let existing = local[id]
            if data.bool("isDeleted") {
                clearPendingDeletedDocumentID(id.uuidString, userID: userID, collection: .courses)
                if let existing,
                   shouldApplyRemoteDeletion(existingUpdatedAt: existing.updatedAt, remoteData: data) {
                    modelContext.delete(existing)
                    local.removeValue(forKey: id)
                }
                continue
            }
            guard shouldApplyRemoteRecord(
                existingUpdatedAt: existing?.updatedAt,
                remoteData: data,
                userID: userID,
                collection: .courses,
                documentID: id.uuidString
            ) else {
                continue
            }
            let course = existing ?? Course(id: id, timetableID: timetableID, name: data.string("name") ?? "")
            course.timetableID = timetableID
            course.name = data.string("name") ?? course.name
            course.colorHex = data.string("colorHex") ?? PlannerPreference.defaultEventColorHexes[0]
            course.teacherName = data.string("teacherName") ?? ""
            course.location = data.string("location") ?? ""
            course.createdAt = data.date("createdAt") ?? course.createdAt
            course.updatedAt = data.date("updatedAt") ?? course.updatedAt
            if local[id] == nil {
                modelContext.insert(course)
                local[id] = course
            }
        }
        saveAfterApplyingCloudData(modelContext)
    }

    func applyCourseSessions(_ documents: [QueryDocumentSnapshot], userID: String, to modelContext: ModelContext) {
        var local = Dictionary(uniqueKeysWithValues: fetch(CourseSession.self, in: modelContext).map { ($0.id, $0) })
        for document in documents {
            let data = document.data()
            guard let id = data.uuid("id", fallback: document.documentID),
                  let courseID = data.uuid("courseID")
            else {
                continue
            }
            if data.bool("isDeleted") {
                clearPendingDeletedDocumentID(id.uuidString, userID: userID, collection: .courseSessions)
                if let existing = local[id] {
                    modelContext.delete(existing)
                    local.removeValue(forKey: id)
                }
                continue
            }
            guard shouldApplyRemoteRecord(
                existingUpdatedAt: nil,
                remoteData: data,
                userID: userID,
                collection: .courseSessions,
                documentID: id.uuidString
            ) else {
                continue
            }
            let session = local[id] ?? CourseSession(
                id: id,
                courseID: courseID,
                weekday: data.int("weekday") ?? 1,
                startPeriodIndex: data.int("startPeriodIndex") ?? 1,
                endPeriodIndex: data.int("endPeriodIndex") ?? 1,
                startWeek: data.int("startWeek") ?? 1,
                endWeek: data.int("endWeek") ?? 1
            )
            session.courseID = courseID
            session.weekday = data.int("weekday") ?? session.weekday
            session.startPeriodIndex = data.int("startPeriodIndex") ?? session.startPeriodIndex
            session.endPeriodIndex = data.int("endPeriodIndex") ?? session.endPeriodIndex
            session.startWeek = data.int("startWeek") ?? session.startWeek
            session.endWeek = data.int("endWeek") ?? session.endWeek
            if local[id] == nil {
                modelContext.insert(session)
                local[id] = session
            }
        }
        saveAfterApplyingCloudData(modelContext)
    }

    func applySyncedUserDefaults(from data: [String: Any]) {
        if let appLanguageID = data.string("appLanguageID"),
           shouldApplyRemoteLanguagePreference(from: data) {
            defaults.set(appLanguageID, forKey: AppLanguage.storageKey)
            storeLanguageUpdatedAt(data.date("appLanguageUpdatedAt"))
        }
        if let appearanceID = data.string("appearanceID"),
           shouldApplyRemoteAppearancePreference(from: data) {
            defaults.set(appearanceID, forKey: AppAppearancePreference.storageKey)
            storeAppearanceUpdatedAt(data.date("appearanceUpdatedAt"))
        }
        if let showDockIcon = data.optionalBool("showDockIcon") {
            defaults.set(showDockIcon, forKey: AppDockIconController.storageKey)
            AppDockIconController.apply(showDockIcon: showDockIcon)
        }
        if let sidebarSectionOrder = data.string("sidebarSectionOrder") {
            defaults.set(sidebarSectionOrder, forKey: "meowplanner.sidebar.sectionOrder")
        }
    }

    func shouldApplyRemoteAppearancePreference(from data: [String: Any]) -> Bool {
        SyncedUserDefaultMergeDecision.shouldApplyRemoteValue(
            localUpdatedAt: appearanceUpdatedAtDateFromDefaults(),
            remoteUpdatedAt: data.date("appearanceUpdatedAt")
        )
    }

    func shouldApplyRemoteLanguagePreference(from data: [String: Any]) -> Bool {
        SyncedUserDefaultMergeDecision.shouldApplyRemoteValue(
            localUpdatedAt: languageUpdatedAtDateFromDefaults(),
            remoteUpdatedAt: data.date("appLanguageUpdatedAt")
        )
    }

    func languageUpdatedAtDate() -> Date {
        languageUpdatedAtDateFromDefaults() ?? Date(timeIntervalSince1970: 0)
    }

    func languageUpdatedAtDateFromDefaults() -> Date? {
        if let date = defaults.object(forKey: AppLanguage.updatedAtStorageKey) as? Date {
            return date
        }
        if let number = defaults.object(forKey: AppLanguage.updatedAtStorageKey) as? NSNumber {
            return Date(timeIntervalSince1970: number.doubleValue)
        }
        if let timeInterval = defaults.object(forKey: AppLanguage.updatedAtStorageKey) as? TimeInterval {
            return Date(timeIntervalSince1970: timeInterval)
        }
        if defaults.object(forKey: AppLanguage.storageKey) != nil {
            return Date(timeIntervalSince1970: 0)
        }
        return nil
    }

    func appearanceUpdatedAtDate() -> Date {
        appearanceUpdatedAtDateFromDefaults() ?? Date(timeIntervalSince1970: 0)
    }

    func appearanceUpdatedAtDateFromDefaults() -> Date? {
        if let date = defaults.object(forKey: AppAppearancePreference.updatedAtStorageKey) as? Date {
            return date
        }
        if let number = defaults.object(forKey: AppAppearancePreference.updatedAtStorageKey) as? NSNumber {
            return Date(timeIntervalSince1970: number.doubleValue)
        }
        if let timeInterval = defaults.object(forKey: AppAppearancePreference.updatedAtStorageKey) as? TimeInterval {
            return Date(timeIntervalSince1970: timeInterval)
        }
        if defaults.object(forKey: AppAppearancePreference.storageKey) != nil {
            return Date(timeIntervalSince1970: 0)
        }
        return nil
    }

    func storeLanguageUpdatedAt(_ date: Date?) {
        let updatedAt = date ?? Date(timeIntervalSince1970: 0)
        defaults.set(updatedAt.timeIntervalSince1970, forKey: AppLanguage.updatedAtStorageKey)
    }

    func storeAppearanceUpdatedAt(_ date: Date?) {
        let updatedAt = date ?? Date(timeIntervalSince1970: 0)
        defaults.set(updatedAt.timeIntervalSince1970, forKey: AppAppearancePreference.updatedAtStorageKey)
    }

    func saveAfterApplyingCloudData(_ modelContext: ModelContext) {
        try? modelContext.save()
        WidgetTimelineSyncService.publishSnapshotAndReload(using: modelContext)
    }

    func shouldApplyRemoteRecord(
        existingUpdatedAt: Date?,
        remoteData: [String: Any],
        userID: String,
        collection: CloudDataCollection,
        documentID: String
    ) -> Bool {
        CloudRecordMergeDecision.shouldApplyRemoteRecord(
            localUpdatedAt: existingUpdatedAt,
            remoteUpdatedAt: remoteData.date("updatedAt"),
            isPendingLocalDeletion: pendingDeletedDocumentIDs(userID: userID, collection: collection).contains(documentID),
            remoteIsDeleted: remoteData.bool("isDeleted")
        )
    }

    func shouldApplyRemoteDeletion(existingUpdatedAt: Date?, remoteData: [String: Any]) -> Bool {
        CloudRecordMergeDecision.shouldApplyRemoteDeletion(
            localUpdatedAt: existingUpdatedAt,
            remoteUpdatedAt: remoteData.date("updatedAt")
        )
    }
}

private extension Dictionary where Key == String, Value == Any {
    func string(_ key: String) -> String? {
        guard let value = self[key], !(value is NSNull) else {
            return nil
        }
        return value as? String
    }

    func int(_ key: String) -> Int? {
        guard let value = self[key], !(value is NSNull) else {
            return nil
        }
        if let intValue = value as? Int {
            return intValue
        }
        if let number = value as? NSNumber {
            return number.intValue
        }
        return nil
    }

    func optionalInt(_ key: String) -> Int? {
        int(key)
    }

    func bool(_ key: String, default defaultValue: Bool = false) -> Bool {
        optionalBool(key) ?? defaultValue
    }

    func optionalBool(_ key: String) -> Bool? {
        guard let value = self[key], !(value is NSNull) else {
            return nil
        }
        if let boolValue = value as? Bool {
            return boolValue
        }
        if let number = value as? NSNumber {
            return number.boolValue
        }
        return nil
    }

    func date(_ key: String) -> Date? {
        guard let value = self[key], !(value is NSNull) else {
            return nil
        }
        if let timestamp = value as? Timestamp {
            return timestamp.dateValue()
        }
        if let date = value as? Date {
            return date
        }
        if let number = value as? NSNumber {
            return Date(timeIntervalSince1970: number.doubleValue)
        }
        if let timeInterval = value as? TimeInterval {
            return Date(timeIntervalSince1970: timeInterval)
        }
        return nil
    }

    func uuid(_ key: String, fallback: String? = nil) -> UUID? {
        if let value = string(key), let uuid = UUID(uuidString: value) {
            return uuid
        }
        if let fallback, let uuid = UUID(uuidString: fallback) {
            return uuid
        }
        return nil
    }

    func base64Data(_ key: String) -> Data? {
        guard let value = string(key) else {
            return nil
        }
        return Data(base64Encoded: value)
    }
}

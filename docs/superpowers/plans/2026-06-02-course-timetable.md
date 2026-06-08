# Course Timetable Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a standalone `课程表 / Timetable` feature with semester setup, editable class periods, weekly course blocks, and course editing.

**Architecture:** Add timetable-specific SwiftData models in `MeowPlannerCore`, timetable calculation helpers, and a new SwiftUI timetable section routed from the existing sidebar/tab system. Keep course data separate from `PlannerEvent`; the timetable grid reads `CourseTimetable`, `CoursePeriod`, `Course`, and `CourseSession` by IDs.

**Tech Stack:** Swift 6, SwiftData, SwiftUI, Testing, existing MeowPlanner theme/copy/navigation patterns.

---

## File Structure

- Create `Sources/MeowPlannerCore/Models/CourseTimetable.swift`: SwiftData models for timetable, periods, courses, and sessions.
- Create `Sources/MeowPlannerCore/Services/CourseTimetablePlanner.swift`: pure helper functions for period generation, week calculation, and visible sessions.
- Modify `Sources/MeowPlannerCore/Stores/ModelContainerFactory.swift`: add timetable models to schema.
- Modify `Sources/MeowPlannerCore/Support/AppLanguage.swift`: add bilingual copy keys for timetable labels.
- Modify `Sources/MeowPlannerApp/Support/AppNavigation.swift`: add `.timetable`.
- Modify `Sources/MeowPlannerApp/Views/RootView.swift`: route `.timetable` to `CourseTimetableView`.
- Create `Sources/MeowPlannerApp/Views/Timetable/CourseTimetableView.swift`: main timetable page, setup form, weekly grid, course editor sheet.
- Modify `Tests/MeowPlannerCoreTests/PlannerRulesTests.swift`: add timetable model/default behavior tests.
- Modify `Tests/MeowPlannerCoreTests/XcodeWidgetProjectTests.swift`: add source-level navigation/UI structure tests.

Do not refactor the existing `ScheduleAgendaView` in this plan. It is large, but unrelated to the timetable feature.

---

### Task 1: Core Timetable Models

**Files:**
- Create: `Sources/MeowPlannerCore/Models/CourseTimetable.swift`
- Create: `Sources/MeowPlannerCore/Services/CourseTimetablePlanner.swift`
- Modify: `Sources/MeowPlannerCore/Stores/ModelContainerFactory.swift`
- Modify: `Tests/MeowPlannerCoreTests/PlannerRulesTests.swift`

- [ ] **Step 1: Write failing model tests**

Append these tests to `Tests/MeowPlannerCoreTests/PlannerRulesTests.swift`:

```swift
@Test("course timetable generates default class periods")
func courseTimetableGeneratesDefaultClassPeriods() throws {
    let timetable = CourseTimetable(
        name: "Spring 2026",
        semesterStartDate: try date("2026-01-20 00:00"),
        semesterWeeks: 16,
        periodsPerDay: 3,
        lessonDurationMinutes: 90,
        breakDurationMinutes: 10
    )

    let periods = CourseTimetablePlanner.defaultPeriods(for: timetable, firstStartMinutes: 9 * 60)

    #expect(periods.count == 3)
    #expect(periods[0].index == 1)
    #expect(periods[0].startMinutesFromMidnight == 540)
    #expect(periods[0].endMinutesFromMidnight == 630)
    #expect(periods[1].startMinutesFromMidnight == 640)
    #expect(periods[2].endMinutesFromMidnight == 830)
}

@Test("course session is visible only inside its week range")
func courseSessionVisibilityFollowsWeekRange() {
    let session = CourseSession(
        courseID: UUID(),
        weekday: 4,
        startPeriodIndex: 1,
        endPeriodIndex: 2,
        startWeek: 3,
        endWeek: 8
    )

    #expect(session.isVisible(inWeek: 3))
    #expect(session.isVisible(inWeek: 8))
    #expect(!session.isVisible(inWeek: 2))
    #expect(!session.isVisible(inWeek: 9))
}

@Test("course timetable calculates semester week")
func courseTimetableCalculatesSemesterWeek() throws {
    let timetable = CourseTimetable(
        name: "Spring 2026",
        semesterStartDate: try date("2026-01-20 00:00"),
        semesterWeeks: 16
    )

    #expect(CourseTimetablePlanner.weekNumber(for: try date("2026-01-20 12:00"), timetable: timetable, calendar: calendar) == 1)
    #expect(CourseTimetablePlanner.weekNumber(for: try date("2026-01-27 12:00"), timetable: timetable, calendar: calendar) == 2)
    #expect(CourseTimetablePlanner.weekNumber(for: try date("2026-05-25 12:00"), timetable: timetable, calendar: calendar) == 16)
}
```

- [ ] **Step 2: Run tests to verify RED**

Run:

```bash
swift test --filter "Planner domain rules"
```

Expected: FAIL because `CourseTimetable`, `CourseSession`, and `CourseTimetablePlanner` do not exist.

- [ ] **Step 3: Create timetable models**

Create `Sources/MeowPlannerCore/Models/CourseTimetable.swift`:

```swift
import Foundation
import SwiftData

@Model
public final class CourseTimetable {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var semesterStartDate: Date
    public var semesterWeeks: Int
    public var periodsPerDay: Int
    public var lessonDurationMinutes: Int
    public var breakDurationMinutes: Int
    public var skipHolidays: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        semesterStartDate: Date,
        semesterWeeks: Int = 16,
        periodsPerDay: Int = 6,
        lessonDurationMinutes: Int = 90,
        breakDurationMinutes: Int = 10,
        skipHolidays: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Spring 2026" : name
        self.semesterStartDate = semesterStartDate
        self.semesterWeeks = min(max(semesterWeeks, 1), 30)
        self.periodsPerDay = min(max(periodsPerDay, 1), 12)
        self.lessonDurationMinutes = min(max(lessonDurationMinutes, 15), 240)
        self.breakDurationMinutes = min(max(breakDurationMinutes, 0), 120)
        self.skipHolidays = skipHolidays
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
public final class CoursePeriod {
    @Attribute(.unique) public var id: UUID
    public var timetableID: UUID
    public var index: Int
    public var startMinutesFromMidnight: Int
    public var endMinutesFromMidnight: Int

    public init(
        id: UUID = UUID(),
        timetableID: UUID,
        index: Int,
        startMinutesFromMidnight: Int,
        endMinutesFromMidnight: Int
    ) {
        self.id = id
        self.timetableID = timetableID
        self.index = max(1, index)
        self.startMinutesFromMidnight = min(max(startMinutesFromMidnight, 0), 1_439)
        self.endMinutesFromMidnight = min(max(endMinutesFromMidnight, self.startMinutesFromMidnight + 1), 1_440)
    }
}

@Model
public final class Course {
    @Attribute(.unique) public var id: UUID
    public var timetableID: UUID
    public var name: String
    public var colorHex: String
    public var teacherName: String
    public var location: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        timetableID: UUID,
        name: String,
        colorHex: String = PlannerPreference.defaultEventColorHexes[0],
        teacherName: String = "",
        location: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.timetableID = timetableID
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.colorHex = colorHex
        self.teacherName = teacherName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.location = location.trimmingCharacters(in: .whitespacesAndNewlines)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
public final class CourseSession {
    @Attribute(.unique) public var id: UUID
    public var courseID: UUID
    public var weekday: Int
    public var startPeriodIndex: Int
    public var endPeriodIndex: Int
    public var startWeek: Int
    public var endWeek: Int

    public init(
        id: UUID = UUID(),
        courseID: UUID,
        weekday: Int,
        startPeriodIndex: Int,
        endPeriodIndex: Int,
        startWeek: Int = 1,
        endWeek: Int = 16
    ) {
        self.id = id
        self.courseID = courseID
        self.weekday = min(max(weekday, 1), 7)
        self.startPeriodIndex = max(1, startPeriodIndex)
        self.endPeriodIndex = max(self.startPeriodIndex, endPeriodIndex)
        self.startWeek = max(1, startWeek)
        self.endWeek = max(self.startWeek, endWeek)
    }

    public func isVisible(inWeek week: Int) -> Bool {
        week >= startWeek && week <= endWeek
    }
}
```

- [ ] **Step 4: Create timetable planner helper**

Create `Sources/MeowPlannerCore/Services/CourseTimetablePlanner.swift`:

```swift
import Foundation

public enum CourseTimetablePlanner {
    public static func defaultPeriods(
        for timetable: CourseTimetable,
        firstStartMinutes: Int = 9 * 60
    ) -> [CoursePeriod] {
        var result: [CoursePeriod] = []
        var start = min(max(firstStartMinutes, 0), 1_439)

        for index in 1...timetable.periodsPerDay {
            let end = min(start + timetable.lessonDurationMinutes, 1_440)
            result.append(
                CoursePeriod(
                    timetableID: timetable.id,
                    index: index,
                    startMinutesFromMidnight: start,
                    endMinutesFromMidnight: end
                )
            )
            start = min(end + timetable.breakDurationMinutes, 1_439)
        }

        return result
    }

    public static func weekNumber(
        for date: Date,
        timetable: CourseTimetable,
        calendar: Calendar = .current
    ) -> Int {
        let start = calendar.startOfDay(for: timetable.semesterStartDate)
        let target = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: start, to: target).day ?? 0
        let rawWeek = max(1, days / 7 + 1)
        return min(rawWeek, timetable.semesterWeeks)
    }
}
```

- [ ] **Step 5: Add models to SwiftData schema**

Modify `Sources/MeowPlannerCore/Stores/ModelContainerFactory.swift` schema list:

```swift
Schema([
    PlannerEvent.self,
    TodoItem.self,
    Habit.self,
    HabitCheckIn.self,
    FocusSession.self,
    PlannerPreference.self,
    CourseTimetable.self,
    CoursePeriod.self,
    Course.self,
    CourseSession.self
])
```

- [ ] **Step 6: Run tests to verify GREEN**

Run:

```bash
swift test --filter "Planner domain rules"
```

Expected: PASS.

---

### Task 2: Navigation And Copy

**Files:**
- Modify: `Sources/MeowPlannerApp/Support/AppNavigation.swift`
- Modify: `Sources/MeowPlannerApp/Views/RootView.swift`
- Modify: `Sources/MeowPlannerCore/Support/AppLanguage.swift`
- Modify: `Tests/MeowPlannerCoreTests/XcodeWidgetProjectTests.swift`

- [ ] **Step 1: Write failing navigation/copy test**

Append to `Tests/MeowPlannerCoreTests/XcodeWidgetProjectTests.swift`:

```swift
@Test("app navigation adds standalone course timetable section")
func appNavigationAddsStandaloneCourseTimetableSection() throws {
    let root = try packageRoot()
    let navigationFile = root.appendingPathComponent("Sources/MeowPlannerApp/Support/AppNavigation.swift")
    let rootFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/RootView.swift")
    let copyFile = root.appendingPathComponent("Sources/MeowPlannerCore/Support/AppLanguage.swift")

    let navigationSource = try String(contentsOf: navigationFile, encoding: .utf8)
    let rootSource = try String(contentsOf: rootFile, encoding: .utf8)
    let copySource = try String(contentsOf: copyFile, encoding: .utf8)

    #expect(navigationSource.contains("case timetable"))
    #expect(navigationSource.contains("PlannerCopy.text(.timetable"))
    #expect(navigationSource.contains("\"tablecells\""))
    #expect(rootSource.contains("CourseTimetableView()"))
    #expect(copySource.contains("case timetable"))
    #expect(copySource.contains(".timetable: \"Timetable\""))
    #expect(copySource.contains(".timetable: \"课程表\""))
}
```

- [ ] **Step 2: Run test to verify RED**

Run:

```bash
swift test --filter XcodeWidgetProjectTests/appNavigationAddsStandaloneCourseTimetableSection
```

Expected: FAIL because `.timetable` and `CourseTimetableView` do not exist.

- [ ] **Step 3: Add copy keys**

In `Sources/MeowPlannerCore/Support/AppLanguage.swift`, add keys to `PlannerTextKey`:

```swift
case timetable
case timetableName
case createTimetable
case semesterStartDate
case semesterWeeks
case periodsPerDay
case lessonDuration
case breakDuration
case skipHolidays
case newCourse
case editCourse
case courseName
case teacher
case location
case weekRange
case periodRange
case addOtherSessions
```

Add English dictionary entries:

```swift
.timetable: "Timetable",
.timetableName: "Timetable name",
.createTimetable: "Create Timetable",
.semesterStartDate: "Semester start",
.semesterWeeks: "Semester weeks",
.periodsPerDay: "Periods per day",
.lessonDuration: "Lesson duration",
.breakDuration: "Break duration",
.skipHolidays: "Skip holidays",
.newCourse: "New Course",
.editCourse: "Edit Course",
.courseName: "Course name",
.teacher: "Teacher",
.location: "Location",
.weekRange: "Week range",
.periodRange: "Period range",
.addOtherSessions: "Add other sessions",
```

Add Chinese dictionary entries:

```swift
.timetable: "课程表",
.timetableName: "课程表名称",
.createTimetable: "创建课程表",
.semesterStartDate: "开学日期",
.semesterWeeks: "学期周数",
.periodsPerDay: "每天上课节数",
.lessonDuration: "单节课时长",
.breakDuration: "课间休息时长",
.skipHolidays: "跳过节假日",
.newCourse: "新建课程",
.editCourse: "编辑课程",
.courseName: "课程名称",
.teacher: "老师",
.location: "上课地点",
.weekRange: "起止周",
.periodRange: "节次范围",
.addOtherSessions: "添加其他上课时间",
```

- [ ] **Step 4: Add navigation section**

Modify `Sources/MeowPlannerApp/Support/AppNavigation.swift`:

```swift
enum AppSection: String, CaseIterable, Identifiable {
    case calendar
    case schedule
    case timetable
    case focus
    case settings
```

Add switch cases:

```swift
case .timetable: PlannerCopy.text(.timetable, language: language)
```

```swift
case .timetable: "tablecells"
```

- [ ] **Step 5: Route section to a temporary stub view**

In `Sources/MeowPlannerApp/Views/RootView.swift`, add:

```swift
case .timetable:
    CourseTimetableView()
```

Create a temporary stub at the bottom of `RootView.swift` only for this task:

```swift
private struct CourseTimetableView: View {
    var body: some View {
        Text("课程表")
    }
}
```

Task 3 moves this view into its own file and deletes the temporary stub.

- [ ] **Step 6: Run test to verify GREEN**

Run:

```bash
swift test --filter XcodeWidgetProjectTests/appNavigationAddsStandaloneCourseTimetableSection
```

Expected: PASS.

---

### Task 3: Timetable Setup Screen

**Files:**
- Create: `Sources/MeowPlannerApp/Views/Timetable/CourseTimetableView.swift`
- Modify: `Sources/MeowPlannerApp/Views/RootView.swift`
- Modify: `Tests/MeowPlannerCoreTests/XcodeWidgetProjectTests.swift`

- [ ] **Step 1: Write failing setup UI structure test**

Append to `Tests/MeowPlannerCoreTests/XcodeWidgetProjectTests.swift`:

```swift
@Test("course timetable view exposes semester setup form")
func courseTimetableViewExposesSemesterSetupForm() throws {
    let root = try packageRoot()
    let timetableFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Timetable/CourseTimetableView.swift")

    #expect(FileManager.default.fileExists(atPath: timetableFile.path))
    let source = try String(contentsOf: timetableFile, encoding: .utf8)

    #expect(source.contains("struct CourseTimetableView"))
    #expect(source.contains("CourseTimetableSetupView"))
    #expect(source.contains("@Query(sort: \\CourseTimetable.createdAt"))
    #expect(source.contains("CourseTimetablePlanner.defaultPeriods"))
    #expect(source.contains("PlannerCopy.text(.timetableName"))
    #expect(source.contains("PlannerCopy.text(.semesterStartDate"))
    #expect(source.contains("PlannerCopy.text(.semesterWeeks"))
    #expect(source.contains("PlannerCopy.text(.periodsPerDay"))
    #expect(source.contains("PlannerCopy.text(.lessonDuration"))
    #expect(source.contains("PlannerCopy.text(.breakDuration"))
    #expect(source.contains("PlannerCopy.text(.skipHolidays"))
}
```

- [ ] **Step 2: Run test to verify RED**

Run:

```bash
swift test --filter XcodeWidgetProjectTests/courseTimetableViewExposesSemesterSetupForm
```

Expected: FAIL because `CourseTimetableView.swift` does not exist.

- [ ] **Step 3: Create timetable view file with setup form**

Create `Sources/MeowPlannerApp/Views/Timetable/CourseTimetableView.swift`:

```swift
import MeowPlannerCore
import SwiftData
import SwiftUI

struct CourseTimetableView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Query(sort: \CourseTimetable.createdAt) private var timetables: [CourseTimetable]
    @Query(sort: \CoursePeriod.index) private var periods: [CoursePeriod]
    @Query(sort: \Course.createdAt) private var courses: [Course]
    @Query private var sessions: [CourseSession]

    @State private var selectedWeek = 1
    @State private var showingCourseEditor = false

    private var timetable: CourseTimetable? {
        timetables.first
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            MeowPlannerTheme.fufuPlannerBackground
                .overlay { MeowPlannerTheme.plannerGradient.opacity(0.86) }
                .overlay { timetableBackgroundMotifs }
                .ignoresSafeArea()

            if let timetable {
                CourseTimetableGridView(
                    timetable: timetable,
                    periods: periods.filter { $0.timetableID == timetable.id },
                    courses: courses.filter { $0.timetableID == timetable.id },
                    sessions: sessions,
                    selectedWeek: $selectedWeek,
                    language: appLanguage
                )
                .padding()

                Button {
                    showingCourseEditor = true
                } label: {
                    Image(systemName: "pawprint.fill")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(MeowPlannerTheme.caramel, in: Circle())
                        .shadow(color: MeowPlannerTheme.coffee.opacity(0.22), radius: 12, y: 6)
                }
                .buttonStyle(.plain)
                .padding(28)
                .sheet(isPresented: $showingCourseEditor) {
                    CourseEditorView(timetable: timetable)
                        .environment(\.appLanguage, appLanguage)
                }
            } else {
                CourseTimetableSetupView()
                    .padding()
                    .frame(maxWidth: 720)
            }
        }
    }

    private var timetableBackgroundMotifs: some View {
        GeometryReader { proxy in
            ZStack {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 210, weight: .bold))
                    .foregroundStyle(MeowPlannerTheme.fufuPawTint.opacity(0.10))
                    .rotationEffect(.degrees(-12))
                    .position(x: proxy.size.width * 0.22, y: proxy.size.height * 0.56)
                Image(systemName: "pawprint")
                    .font(.system(size: 170, weight: .semibold))
                    .foregroundStyle(MeowPlannerTheme.blush.opacity(0.10))
                    .rotationEffect(.degrees(12))
                    .position(x: proxy.size.width * 0.82, y: proxy.size.height * 0.58)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct CourseTimetableSetupView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.modelContext) private var modelContext

    @State private var name = "Spring 2026"
    @State private var semesterStartDate = Date()
    @State private var semesterWeeks = 16
    @State private var periodsPerDay = 6
    @State private var lessonDurationMinutes = 90
    @State private var breakDurationMinutes = 10
    @State private var skipHolidays = true

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(PlannerCopy.text(.createTimetable, language: appLanguage))
                .font(.largeTitle.bold())
                .foregroundStyle(MeowPlannerTheme.cocoa)

            VStack(spacing: 0) {
                TextField(PlannerCopy.text(.timetableName, language: appLanguage), text: $name)
                DatePicker(PlannerCopy.text(.semesterStartDate, language: appLanguage), selection: $semesterStartDate, displayedComponents: .date)
                Stepper("\(PlannerCopy.text(.semesterWeeks, language: appLanguage)): \(semesterWeeks)", value: $semesterWeeks, in: 1...30)
                Stepper("\(PlannerCopy.text(.periodsPerDay, language: appLanguage)): \(periodsPerDay)", value: $periodsPerDay, in: 1...12)
                Stepper("\(PlannerCopy.text(.lessonDuration, language: appLanguage)): \(lessonDurationMinutes) min", value: $lessonDurationMinutes, in: 15...240, step: 5)
                Stepper("\(PlannerCopy.text(.breakDuration, language: appLanguage)): \(breakDurationMinutes) min", value: $breakDurationMinutes, in: 0...120, step: 5)
                Toggle(PlannerCopy.text(.skipHolidays, language: appLanguage), isOn: $skipHolidays)
            }
            .textFieldStyle(.plain)
            .padding()
            .background(MeowPlannerTheme.fufuCalendarBackground.opacity(0.74), in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(MeowPlannerTheme.blush.opacity(0.18), lineWidth: 1)
            }

            Button {
                createTimetable()
            } label: {
                Text(PlannerCopy.text(.createTimetable, language: appLanguage))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func createTimetable() {
        let timetable = CourseTimetable(
            name: name,
            semesterStartDate: semesterStartDate,
            semesterWeeks: semesterWeeks,
            periodsPerDay: periodsPerDay,
            lessonDurationMinutes: lessonDurationMinutes,
            breakDurationMinutes: breakDurationMinutes,
            skipHolidays: skipHolidays
        )
        modelContext.insert(timetable)
        for period in CourseTimetablePlanner.defaultPeriods(for: timetable) {
            modelContext.insert(period)
        }
    }
}
```

- [ ] **Step 4: Move temporary stub out of RootView**

Delete the temporary `private struct CourseTimetableView` from `Sources/MeowPlannerApp/Views/RootView.swift`.

- [ ] **Step 5: Add temporary shell structs for grid/editor**

At the bottom of `CourseTimetableView.swift`, add temporary shells that Task 4 and Task 5 replace:

```swift
private struct CourseTimetableGridView: View {
    var timetable: CourseTimetable
    var periods: [CoursePeriod]
    var courses: [Course]
    var sessions: [CourseSession]
    @Binding var selectedWeek: Int
    var language: AppLanguage

    var body: some View {
        Text(timetable.name)
    }
}

private struct CourseEditorView: View {
    var timetable: CourseTimetable

    var body: some View {
        Text("Course editor")
            .padding()
    }
}
```

- [ ] **Step 6: Run test to verify GREEN**

Run:

```bash
swift test --filter XcodeWidgetProjectTests/courseTimetableViewExposesSemesterSetupForm
```

Expected: PASS.

---

### Task 4: Weekly Timetable Grid

**Files:**
- Modify: `Sources/MeowPlannerApp/Views/Timetable/CourseTimetableView.swift`
- Modify: `Tests/MeowPlannerCoreTests/XcodeWidgetProjectTests.swift`

- [ ] **Step 1: Write failing weekly grid structure test**

Append to `Tests/MeowPlannerCoreTests/XcodeWidgetProjectTests.swift`:

```swift
@Test("course timetable renders standard weekly class grid")
func courseTimetableRendersStandardWeeklyClassGrid() throws {
    let root = try packageRoot()
    let timetableFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Timetable/CourseTimetableView.swift")
    let source = try String(contentsOf: timetableFile, encoding: .utf8)

    #expect(source.contains("CourseTimetableGridView"))
    #expect(source.contains("weekdayHeader"))
    #expect(source.contains("periodRows"))
    #expect(source.contains("courseBlock"))
    #expect(source.contains("courseBlockHeight"))
    #expect(source.contains("selectedWeek"))
    #expect(source.contains("W\\(selectedWeek)"))
    #expect(source.contains("visibleSessions"))
    #expect(source.contains("isSkippedHoliday"))
    #expect(source.contains("CourseTimetablePlanner.weekNumber"))
    #expect(source.contains("ChineseCalendarInfoProvider.info"))
    #expect(source.contains("skipHolidays"))
}
```

- [ ] **Step 2: Run test to verify RED**

Run:

```bash
swift test --filter XcodeWidgetProjectTests/courseTimetableRendersStandardWeeklyClassGrid
```

Expected: FAIL because grid functions are not implemented.

- [ ] **Step 3: Replace grid shell with weekly grid**

Replace `CourseTimetableGridView` in `CourseTimetableView.swift` with:

```swift
private struct CourseTimetableGridView: View {
    var timetable: CourseTimetable
    var periods: [CoursePeriod]
    var courses: [Course]
    var sessions: [CourseSession]
    @Binding var selectedWeek: Int
    var language: AppLanguage

    private let timeColumnWidth: CGFloat = 72
    private let periodRowHeight: CGFloat = 136
    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    weekdayHeader
                    periodRows
                }
            }
            .background(MeowPlannerTheme.fufuCalendarBackground.opacity(0.72), in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(MeowPlannerTheme.caramel.opacity(0.18), lineWidth: 1)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(timetable.name)
                    .font(.largeTitle.bold())
                    .foregroundStyle(MeowPlannerTheme.cocoa)
                Text("W\(selectedWeek)")
                    .font(.headline)
                    .foregroundStyle(MeowPlannerTheme.caramel)
            }

            Spacer()

            Button { selectedWeek = max(1, selectedWeek - 1) } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.bordered)

            Button { selectedWeek = currentWeek } label: {
                Text("Today")
            }
            .buttonStyle(.bordered)

            Button { selectedWeek = min(timetable.semesterWeeks, selectedWeek + 1) } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.bordered)
        }
        .onAppear {
            selectedWeek = currentWeek
        }
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            Text("W\(selectedWeek)")
                .font(.caption.weight(.bold))
                .foregroundStyle(MeowPlannerTheme.caramel)
                .frame(width: timeColumnWidth, alignment: .leading)
                .padding(.leading, 12)

            ForEach(weekdays, id: \.weekday) { item in
                VStack(spacing: 3) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                    Text(item.date.formatted(.dateTime.day()))
                        .font(.caption)
                    if timetable.skipHolidays {
                        let info = ChineseCalendarInfoProvider.info(for: item.date, calendar: calendar)
                        if info.isFestival {
                            Text(info.displayText)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(MeowPlannerTheme.blush)
                        }
                    }
                }
                .foregroundStyle(MeowPlannerTheme.caramel)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .overlay(alignment: .trailing) {
                    Rectangle()
                        .fill(MeowPlannerTheme.caramel.opacity(0.12))
                        .frame(width: 1)
                }
            }
        }
        .background(MeowPlannerTheme.cream.opacity(0.48))
    }

    private var periodRows: some View {
        ForEach(sortedPeriods, id: \.id) { period in
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(period.index)")
                        .font(.headline.weight(.bold))
                    Text(formatMinutes(period.startMinutesFromMidnight))
                    Text(formatMinutes(period.endMinutesFromMidnight))
                }
                .font(.caption)
                .foregroundStyle(MeowPlannerTheme.caramel)
                .frame(width: timeColumnWidth, height: periodRowHeight, alignment: .center)
                .padding(.leading, 12)

                ForEach(weekdays, id: \.weekday) { weekday in
                    let skippedHoliday = isSkippedHoliday(weekday.date)
                    ZStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.10))
                        if skippedHoliday {
                            Text(ChineseCalendarInfoProvider.info(for: weekday.date, calendar: calendar).displayText)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(MeowPlannerTheme.blush.opacity(0.72))
                        } else {
                            ForEach(visibleSessions(weekday: weekday.weekday, period: period)) { session in
                                if let course = courses.first(where: { $0.id == session.courseID }) {
                                    courseBlock(course: course, session: session)
                                        .frame(height: courseBlockHeight(session))
                                        .zIndex(3)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: periodRowHeight)
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(MeowPlannerTheme.caramel.opacity(0.14))
                            .frame(height: 1)
                    }
                    .overlay(alignment: .trailing) {
                        Rectangle()
                            .fill(MeowPlannerTheme.caramel.opacity(0.10))
                            .frame(width: 1)
                    }
                }
            }
        }
    }

    private func courseBlock(course: Course, session: CourseSession) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(course.name)
                .font(.caption.weight(.bold))
                .lineLimit(2)
            if !course.location.isEmpty {
                Text(course.location)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
            }
        }
        .foregroundStyle(.white)
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(MeowPlannerTheme.color(hex: course.colorHex).opacity(0.88), in: RoundedRectangle(cornerRadius: 7))
        .padding(6)
    }

    private func courseBlockHeight(_ session: CourseSession) -> CGFloat {
        let span = max(1, session.endPeriodIndex - session.startPeriodIndex + 1)
        return periodRowHeight * CGFloat(span) - 12
    }

    private func visibleSessions(weekday: Int, period: CoursePeriod) -> [CourseSession] {
        sessions
            .filter { $0.weekday == weekday }
            .filter { $0.startPeriodIndex == period.index }
            .filter { $0.isVisible(inWeek: selectedWeek) }
            .filter { session in courses.contains { $0.id == session.courseID && $0.timetableID == timetable.id } }
    }

    private func isSkippedHoliday(_ date: Date) -> Bool {
        timetable.skipHolidays && ChineseCalendarInfoProvider.info(for: date, calendar: calendar).isFestival
    }

    private var sortedPeriods: [CoursePeriod] {
        periods.sorted { $0.index < $1.index }
    }

    private var currentWeek: Int {
        CourseTimetablePlanner.weekNumber(for: Date(), timetable: timetable, calendar: calendar)
    }

    private var weekdays: [(weekday: Int, title: String, date: Date)] {
        let start = calendar.date(byAdding: .day, value: (selectedWeek - 1) * 7, to: timetable.semesterStartDate) ?? timetable.semesterStartDate
        let monday = calendar.dateInterval(of: .weekOfYear, for: start)?.start ?? start
        let titles = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: monday) else {
                return nil
            }
            return (weekday: offset + 1, title: titles[offset], date: date)
        }
    }

    private func formatMinutes(_ value: Int) -> String {
        String(format: "%02d:%02d", value / 60, value % 60)
    }
}
```

- [ ] **Step 4: Run test to verify GREEN**

Run:

```bash
swift test --filter XcodeWidgetProjectTests/courseTimetableRendersStandardWeeklyClassGrid
```

Expected: PASS.

---

### Task 5: Course Editor

**Files:**
- Modify: `Sources/MeowPlannerApp/Views/Timetable/CourseTimetableView.swift`
- Modify: `Tests/MeowPlannerCoreTests/XcodeWidgetProjectTests.swift`

- [ ] **Step 1: Write failing course editor structure test**

Append to `Tests/MeowPlannerCoreTests/XcodeWidgetProjectTests.swift`:

```swift
@Test("course editor captures course metadata and sessions")
func courseEditorCapturesCourseMetadataAndSessions() throws {
    let root = try packageRoot()
    let timetableFile = root.appendingPathComponent("Sources/MeowPlannerApp/Views/Timetable/CourseTimetableView.swift")
    let source = try String(contentsOf: timetableFile, encoding: .utf8)

    #expect(source.contains("struct CourseEditorView"))
    #expect(source.contains("selectedWeekdays"))
    #expect(source.contains("startPeriodIndex"))
    #expect(source.contains("endPeriodIndex"))
    #expect(source.contains("startWeek"))
    #expect(source.contains("endWeek"))
    #expect(source.contains("teacherName"))
    #expect(source.contains("location"))
    #expect(source.contains("PlannerCopy.text(.addOtherSessions"))
    #expect(source.contains("modelContext.insert(course)"))
    #expect(source.contains("modelContext.insert(session)"))
}
```

- [ ] **Step 2: Run test to verify RED**

Run:

```bash
swift test --filter XcodeWidgetProjectTests/courseEditorCapturesCourseMetadataAndSessions
```

Expected: FAIL because the shell editor does not expose fields.

- [ ] **Step 3: Replace editor shell with course form**

Replace `CourseEditorView` in `CourseTimetableView.swift`:

```swift
private struct CourseEditorView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var preferences: [PlannerPreference]

    var timetable: CourseTimetable

    @State private var courseName = ""
    @State private var colorHex = PlannerPreference.defaultEventColorHexes[0]
    @State private var selectedWeekdays: Set<Int> = [1]
    @State private var startPeriodIndex = 1
    @State private var endPeriodIndex = 1
    @State private var startWeek = 1
    @State private var endWeek = 16
    @State private var teacherName = ""
    @State private var location = ""

    private var availableColors: [String] {
        preferences.first?.eventColorHexes ?? PlannerPreference.defaultEventColorHexes
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(PlannerCopy.text(.newCourse, language: appLanguage))
                    .font(.title.bold())
                    .foregroundStyle(MeowPlannerTheme.cocoa)
                Spacer()
                Button(PlannerCopy.text(.save, language: appLanguage)) {
                    saveCourse()
                }
                .disabled(courseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedWeekdays.isEmpty)
            }

            VStack(spacing: 0) {
                TextField(PlannerCopy.text(.courseName, language: appLanguage), text: $courseName)
                    .font(.title3.weight(.semibold))
                    .textFieldStyle(.plain)

                colorRow
                weekdayRow
                Stepper("\(PlannerCopy.text(.periodRange, language: appLanguage)): \(startPeriodIndex)-\(endPeriodIndex)", value: $startPeriodIndex, in: 1...timetable.periodsPerDay)
                Stepper("End period: \(endPeriodIndex)", value: $endPeriodIndex, in: startPeriodIndex...timetable.periodsPerDay)
                Stepper("\(PlannerCopy.text(.weekRange, language: appLanguage)): \(startWeek)-\(endWeek)", value: $startWeek, in: 1...timetable.semesterWeeks)
                Stepper("End week: \(endWeek)", value: $endWeek, in: startWeek...timetable.semesterWeeks)
                TextField(PlannerCopy.text(.teacher, language: appLanguage), text: $teacherName)
                    .textFieldStyle(.plain)
                TextField(PlannerCopy.text(.location, language: appLanguage), text: $location)
                    .textFieldStyle(.plain)

                Button {
                    selectedWeekdays.insert(min(7, (selectedWeekdays.max() ?? 0) + 1))
                } label: {
                    Label(PlannerCopy.text(.addOtherSessions, language: appLanguage), systemImage: "plus")
                }
                .buttonStyle(.borderless)
            }
            .padding()
            .background(MeowPlannerTheme.fufuCalendarBackground.opacity(0.74), in: RoundedRectangle(cornerRadius: 14))

            Spacer()
        }
        .padding(24)
        .frame(minWidth: 560, minHeight: 520)
        .background(MeowPlannerTheme.plannerGradient)
        .onAppear {
            endWeek = timetable.semesterWeeks
        }
    }

    private var colorRow: some View {
        HStack(spacing: 10) {
            Text(PlannerCopy.text(.color, language: appLanguage))
                .foregroundStyle(.secondary)
            ForEach(availableColors, id: \.self) { color in
                Circle()
                    .fill(MeowPlannerTheme.color(hex: color))
                    .frame(width: 28, height: 28)
                    .overlay {
                        Circle()
                            .stroke(colorHex == color ? MeowPlannerTheme.cocoa : Color.clear, lineWidth: 3)
                    }
                    .onTapGesture {
                        colorHex = color
                    }
            }
            Spacer()
        }
        .padding(.vertical, 10)
    }

    private var weekdayRow: some View {
        HStack(spacing: 8) {
            ForEach(1...7, id: \.self) { weekday in
                Button {
                    if selectedWeekdays.contains(weekday) {
                        selectedWeekdays.remove(weekday)
                    } else {
                        selectedWeekdays.insert(weekday)
                    }
                } label: {
                    Text(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][weekday - 1])
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(selectedWeekdays.contains(weekday) ? MeowPlannerTheme.caramel : MeowPlannerTheme.warmCream.opacity(0.28), in: Capsule())
                        .foregroundStyle(selectedWeekdays.contains(weekday) ? .white : MeowPlannerTheme.caramel)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 10)
    }

    private func saveCourse() {
        let course = Course(
            timetableID: timetable.id,
            name: courseName,
            colorHex: colorHex,
            teacherName: teacherName,
            location: location
        )
        modelContext.insert(course)

        for weekday in selectedWeekdays.sorted() {
            let session = CourseSession(
                courseID: course.id,
                weekday: weekday,
                startPeriodIndex: startPeriodIndex,
                endPeriodIndex: endPeriodIndex,
                startWeek: startWeek,
                endWeek: endWeek
            )
            modelContext.insert(session)
        }

        dismiss()
    }
}
```

- [ ] **Step 4: Run test to verify GREEN**

Run:

```bash
swift test --filter XcodeWidgetProjectTests/courseEditorCapturesCourseMetadataAndSessions
```

Expected: PASS.

---

### Task 6: Full Verification And Install

**Files:**
- Verify all modified files.

- [ ] **Step 1: Run full test suite**

Run:

```bash
swift test
```

Expected: all tests pass.

- [ ] **Step 2: Build macOS app**

Run:

```bash
./script/build_and_run.sh --build-only
```

Expected: `** BUILD SUCCEEDED **` and `Built /Users/xyue/Documents/MeowPlanner/dist/MeowPlanner.app`.

- [ ] **Step 3: Verify code signature**

Run:

```bash
codesign --verify --deep --strict --verbose=2 dist/MeowPlanner.app
```

Expected:

```text
dist/MeowPlanner.app: valid on disk
dist/MeowPlanner.app: satisfies its Designated Requirement
```

- [ ] **Step 4: Install and launch**

Run:

```bash
osascript -e 'tell application "MeowPlanner" to quit' || true
sleep 1
ditto dist/MeowPlanner.app /Applications/MeowPlanner.app
open /Applications/MeowPlanner.app
sleep 2
pgrep -fl MeowPlanner
```

Expected: one `/Applications/MeowPlanner.app/Contents/MacOS/MeowPlanner` process is listed.

- [ ] **Step 5: Manual acceptance**

In the launched app:

1. Confirm the left sidebar includes `课程表`.
2. Open `课程表`.
3. Create a timetable named `Spring 2026`.
4. Confirm the weekly grid appears with period rows and Monday-Sunday columns.
5. Add a course named `METCS 555`, Thursday, period 1, weeks 1-16, teacher `Guanglan Zhang`, location `COM 217`, color `#F57C6E`.
6. Confirm the course appears as a red block on Thursday period 1.
7. Add another course named `METCS 699`, Wednesday, period 2, location `MCS B33`, color `#71B7ED`.
8. Confirm it appears as a blue block on Wednesday period 2.

---

## Self-Review Notes

- Spec coverage: independent sidebar entry, setup form, generated/custom periods, skip-holidays flag, course color, weekly class time, teacher, location, and course blocks are each covered by a task.
- Type consistency: `CourseTimetable`, `CoursePeriod`, `Course`, `CourseSession`, and `CourseTimetablePlanner` are introduced before UI tasks reference them.
- Scope control: V1 intentionally excludes course reminders, widgets, importing, multiple timetable switchers, and schedule-event syncing.

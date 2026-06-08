# Course Timetable V1 Design

## Goal

Add a standalone `课程表 / Timetable` feature to MeowPlanner with a TimePlanner-style weekly class grid. The feature is separate from normal schedules so course data stays structured around semesters, lesson periods, weeks, teachers, and locations.

## Confirmed Direction

- Main layout: option A, a standard weekly timetable.
- Navigation: add an independent left sidebar/tab entry: `日历 / 日程 / 课程表 / 专注 / 设置`.
- Visual style: keep the existing FuFu warm background, soft caramel grid lines, paw watermarks, rounded colored course blocks, and the right-bottom paw add button.
- V1 scope: one active timetable at a time is acceptable, with editing support for timetable settings and courses.

## Core User Flow

1. User opens `课程表`.
2. If no timetable exists, show a setup form.
3. User creates a timetable with name, semester start date, total weeks, class periods per day, lesson duration, break duration, and skip-holidays preference.
4. The app generates class period times automatically.
5. User can manually edit each period start/end time.
6. User adds a course through the paw add button.
7. The weekly timetable shows course blocks by weekday, period range, and active week range.

## Timetable Setup

Fields:

- `课程表名称 / Timetable name`
- `开学日期 / Semester start date`
- `学期周数 / Semester weeks`
- `每天上课节数 / Periods per day`
- `单节课时长 / Lesson duration`
- `课间休息时长 / Break duration`
- `跳过节假日 / Skip holidays`

Defaults:

- Name: `Spring 2026`
- Semester weeks: `16`
- Periods per day: `6`
- Lesson duration: `90` minutes
- Break duration: `10` minutes
- Skip holidays: enabled by default

Time generation:

- Start from a default first period start time of `09:00`.
- Generate each period by adding lesson duration and break duration.
- Let users customize each period start and end time after generation.

## Course Fields

Each course supports:

- `课程名称 / Course name`
- `颜色 / Color`
- `每周上课时间 / Weekly class days`
- `节次范围 / Period range`
- `起止周 / Week range`
- `老师 / Teacher`
- `上课地点 / Classroom location`
- Additional sessions for the same course, so one course can meet on multiple weekdays or at multiple period ranges.

Course block display:

- Show course name as the primary label.
- Show location if available.
- Show teacher only in the detail/editor view, not inside the compact block unless there is enough space.
- Use the selected course color as the block background.

## Weekly Timetable Screen

Header:

- Timetable name.
- Current week, e.g. `W16`.
- Previous/next week controls.
- A small today/current-week action.

Grid:

- Columns: Monday to Sunday.
- Rows: class periods.
- Left rail: period number plus start/end time.
- Course blocks occupy the matching weekday and period range.
- Blocks can span multiple periods vertically.
- If `skip holidays` is enabled, Chinese public holidays should be visually marked and courses on those days should be hidden or muted. V1 should use existing Chinese calendar/festival logic where possible, and can treat this as a display-level filter.

Empty state:

- Use FuFu empty state.
- Primary action: `创建课程表 / Create timetable`.

Add button:

- Right-bottom floating paw button.
- Opens course editor when a timetable exists.
- Opens timetable setup when no timetable exists.

## Course Editor

The editor follows the existing MeowPlanner modal style:

- Warm panel background.
- Large title field.
- Color row using existing custom color palette behavior.
- Weekday selector: Monday through Sunday chips.
- Period range selector: start period and end period.
- Week range selector: start week and end week.
- Teacher text field.
- Location text field.
- `+ Add other sessions` for multiple weekly meeting sessions.
- Save/cancel buttons.

Validation:

- Course name is required.
- At least one weekday is required.
- Start period must be less than or equal to end period.
- Start week must be less than or equal to end week.
- Week and period values must stay within the timetable configuration.

## Data Model

Add SwiftData models:

- `CourseTimetable`
  - id
  - name
  - semesterStartDate
  - semesterWeeks
  - periodsPerDay
  - lessonDurationMinutes
  - breakDurationMinutes
  - skipHolidays
  - createdAt
  - updatedAt

- `CoursePeriod`
  - id
  - timetableID
  - index
  - startMinutesFromMidnight
  - endMinutesFromMidnight

- `Course`
  - id
  - timetableID
  - name
  - colorHex
  - teacherName
  - location
  - createdAt
  - updatedAt

- `CourseSession`
  - id
  - courseID
  - weekday
  - startPeriodIndex
  - endPeriodIndex
  - startWeek
  - endWeek

Keep model relationships simple in V1 by querying with IDs. This matches the existing app’s pragmatic SwiftData style and reduces relationship migration risk.

## Integration Points

- `AppSection`: add `.timetable`.
- `RootView`: route `.timetable` to a new `CourseTimetableView`.
- `ModelContainerFactory`: include new timetable models in the schema.
- `PlannerCopy` / language support: add Chinese and English labels for timetable screens.
- Tests: add model/default tests, navigation tests, timetable generation tests, and source-level UI structure tests.

## Out Of Scope For V1

- Multiple saved timetables with archive/switcher.
- Importing school calendar files.
- Syncing courses into regular schedule events.
- Conflict detection beyond basic validation.
- Advanced holiday makeup-day rules.
- Course reminders.
- Widget support for timetable.

## Testing Strategy

Unit tests:

- Timetable default period generation.
- Week number calculation from semester start date.
- Course session visibility by selected week.
- Course session validation.
- Skip-holiday display filtering with existing festival metadata.

Structure/source tests:

- Sidebar contains `.timetable`.
- `CourseTimetableView` exists.
- Course editor exposes name, color, weekday, period range, week range, teacher, location, and additional sessions.

Manual acceptance:

- Create a timetable.
- Edit generated class times.
- Add a course on Thursday lesson 1 with teacher and location.
- Add another course on Wednesday lesson 2.
- Switch weeks and confirm courses appear only in their configured week range.
- Toggle skip holidays and confirm holiday days are visually marked and course display responds.

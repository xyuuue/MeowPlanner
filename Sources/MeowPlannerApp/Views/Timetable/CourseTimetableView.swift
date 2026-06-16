import MeowPlannerCore
import SwiftData
import SwiftUI

struct CourseTimetableView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Query(sort: \CourseTimetable.createdAt) private var timetables: [CourseTimetable]
    @Query(sort: \CoursePeriod.index) private var periods: [CoursePeriod]
    @Query(sort: \Course.createdAt) private var courses: [Course]
    @Query private var sessions: [CourseSession]
    @Query private var preferences: [PlannerPreference]

    @State private var selectedWeek = 1
    @State private var selectedTimetableID: UUID?
    @State private var editingCourseID: UUID?
    @State private var showingCourseEditor = false
    @State private var showingTimetableCreator = false
    @State private var showingTimetableSettingsEditor = false

    private var selectedTimetable: CourseTimetable? {
        if let selectedTimetableID,
           let timetable = timetables.first(where: { $0.id == selectedTimetableID }) {
            return timetable
        }
        return timetables.first
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            MeowPlannerTheme.fufuPlannerBackground
                .overlay { MeowPlannerTheme.plannerGradient.opacity(0.86) }
                .overlay { timetableBackgroundMotifs }
                .ignoresSafeArea()

            if let timetable = selectedTimetable {
                CourseTimetableGridView(
                    timetable: timetable,
                    timetables: timetables,
                    periods: periods.filter { $0.timetableID == timetable.id },
                    courses: courses.filter { $0.timetableID == timetable.id },
                    sessions: sessions,
                    selectedWeek: $selectedWeek,
                    selectedTimetableID: $selectedTimetableID,
                    onCreateTimetable: { showingTimetableCreator = true },
                    onEditTimetable: { showingTimetableSettingsEditor = true },
                    onEditCourse: { course in
                        editingCourseID = course.id
                        showingCourseEditor = true
                    },
                    weekStartPreference: weekStartPreference,
                    language: appLanguage
                )
                .padding()
                .onAppear {
                    if selectedTimetableID == nil {
                        selectedTimetableID = timetable.id
                    }
                }
                .onChange(of: timetable.id) { _, _ in
                    selectedWeek = 1
                }

                Button {
                    editingCourseID = nil
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
                    let editingCourse = editingCourseID.flatMap { id in
                        courses.first { $0.id == id }
                    }
                    CourseEditorView(
                        timetable: timetable,
                        course: editingCourse,
                        courseSessions: editingCourse.map { course in
                            sessions.filter { $0.courseID == course.id }
                        } ?? []
                    )
                        .environment(\.appLanguage, appLanguage)
                }
                .sheet(isPresented: $showingTimetableSettingsEditor) {
                    CourseTimetableSetupView(timetable: timetable, onDelete: handleTimetableDeleted)
                        .environment(\.appLanguage, appLanguage)
                }
            } else {
                CourseTimetableSetupView(onSave: { timetableID in
                    selectedTimetableID = timetableID
                }, dismissOnSave: false)
                    .padding()
                    .frame(maxWidth: 720)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .sheet(isPresented: $showingTimetableCreator) {
            CourseTimetableSetupView { timetableID in
                selectedTimetableID = timetableID
            }
            .environment(\.appLanguage, appLanguage)
        }
    }

    private var weekStartPreference: WeekStartPreference {
        preferences.first?.weekStartPreference ?? .sunday
    }

    private func handleTimetableDeleted(_ deletedID: UUID) {
        if selectedTimetableID == deletedID {
            selectedTimetableID = timetables.first { $0.id != deletedID }?.id
        }
        selectedWeek = 1
        showingTimetableSettingsEditor = false
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
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .allowsHitTesting(false)
    }
}

private struct CourseTimetableSetupView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var timetable: CourseTimetable?
    var onSave: ((UUID) -> Void)?
    var onDelete: ((UUID) -> Void)?
    var dismissOnSave = true

    @State private var name = "Spring 2026"
    @State private var semesterStartDate = Date()
    @State private var semesterWeeks = 16
    @State private var periodsPerDay = 6
    @State private var lessonDurationMinutes = 90
    @State private var breakDurationMinutes = 10
    @State private var skipHolidays = true
    @State private var showingDeleteConfirmation = false

    init(
        timetable: CourseTimetable? = nil,
        onSave: ((UUID) -> Void)? = nil,
        onDelete: ((UUID) -> Void)? = nil,
        dismissOnSave: Bool = true
    ) {
        self.timetable = timetable
        self.onSave = onSave
        self.onDelete = onDelete
        self.dismissOnSave = dismissOnSave
        _name = State(initialValue: timetable?.name ?? "Spring 2026")
        _semesterStartDate = State(initialValue: timetable?.semesterStartDate ?? Date())
        _semesterWeeks = State(initialValue: timetable?.semesterWeeks ?? 16)
        _periodsPerDay = State(initialValue: timetable?.periodsPerDay ?? 6)
        _lessonDurationMinutes = State(initialValue: timetable?.lessonDurationMinutes ?? 90)
        _breakDurationMinutes = State(initialValue: timetable?.breakDurationMinutes ?? 10)
        _skipHolidays = State(initialValue: timetable?.skipHolidays ?? true)
    }

    var body: some View {
        ZStack {
            MeowPlannerTheme.fufuPlannerBackground
                .overlay { MeowPlannerTheme.plannerGradient.opacity(0.82) }
                .overlay { timetableBackgroundMotifs }
                .ignoresSafeArea()

            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 18) {
                    timetableSetupHeader

                    timetableFormCard

                    Button {
                        saveTimetable()
                    } label: {
                        Text(PlannerCopy.text(.save, language: appLanguage))
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(MeowPlannerTheme.caramel)

                    if timetable != nil {
                        deleteTimetableButton
                    }
                }
                .padding(30)
                .frame(maxWidth: 920, alignment: .topLeading)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .verticalPageScrollOnly()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .confirmationDialog(deleteTimetableTitle, isPresented: $showingDeleteConfirmation) {
            Button(deleteTimetableTitle, role: .destructive) {
                deleteTimetable()
            }

            Button(PlannerCopy.text(.cancel, language: appLanguage), role: .cancel) {}
        } message: {
            Text(deleteTimetableMessage)
        }
    }

    private var titleText: String {
        timetable == nil
            ? PlannerCopy.text(.createTimetable, language: appLanguage)
            : (appLanguage == .chinese ? "修改课程表" : "Edit timetable")
    }

    private var minuteUnit: String {
        appLanguage == .chinese ? "分钟" : "min"
    }

    private var timetableSetupHeader: some View {
        HStack(alignment: .top, spacing: 14) {
            FuFuAssetImage(size: 72)

            VStack(alignment: .leading, spacing: 5) {
                Text(titleText)
                    .font(.largeTitle.bold())
                    .foregroundStyle(MeowPlannerTheme.cocoa)
                Text(PlannerCopy.text(.timetable, language: appLanguage))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(MeowPlannerTheme.caramel)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var deleteTimetableTitle: String {
        appLanguage == .chinese ? "删除课程表" : "Delete timetable"
    }

    private var deleteTimetableMessage: String {
        appLanguage == .chinese
            ? "这会同时删除该课程表里的课程和上课时间。"
            : "This also deletes courses and sessions in this timetable."
    }

    private var deleteTimetableButton: some View {
        Button(role: .destructive) {
            showingDeleteConfirmation = true
        } label: {
            Label(deleteTimetableTitle, systemImage: "trash")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(MeowPlannerTheme.blush)
    }

    private var timetableFormCard: some View {
        VStack(spacing: 0) {
            TextField(PlannerCopy.text(.timetableName, language: appLanguage), text: $name)
                .padding(.vertical, 10)

            Divider().opacity(0.35)

            TimetableDatePickerRow(
                title: PlannerCopy.text(.semesterStartDate, language: appLanguage),
                selection: $semesterStartDate,
                includesTime: false,
                language: appLanguage
            )

            Divider().opacity(0.35)

            PlannerNumberInputRow(
                title: PlannerCopy.text(.semesterWeeks, language: appLanguage),
                value: $semesterWeeks,
                range: 1...30
            )

            Divider().opacity(0.35)

            PlannerNumberInputRow(
                title: PlannerCopy.text(.periodsPerDay, language: appLanguage),
                value: $periodsPerDay,
                range: 1...12
            )

            Divider().opacity(0.35)

            PlannerNumberInputRow(
                title: PlannerCopy.text(.lessonDuration, language: appLanguage),
                value: $lessonDurationMinutes,
                range: 15...240,
                suffix: minuteUnit
            )

            Divider().opacity(0.35)

            PlannerNumberInputRow(
                title: PlannerCopy.text(.breakDuration, language: appLanguage),
                value: $breakDurationMinutes,
                range: 0...120,
                suffix: minuteUnit
            )

            Divider().opacity(0.35)

            Toggle(PlannerCopy.text(.skipHolidays, language: appLanguage), isOn: $skipHolidays)
                .fufuControlTint()
                .padding(.vertical, 10)
        }
        .textFieldStyle(.plain)
        .padding()
        .background(MeowPlannerTheme.fufuCalendarBackground.opacity(0.74), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(MeowPlannerTheme.blush.opacity(0.18), lineWidth: 1)
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
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .allowsHitTesting(false)
    }

    private func saveTimetable() {
        let savedTimetable: CourseTimetable
        if let timetable {
            timetable.name = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? timetable.name : name
            timetable.semesterStartDate = semesterStartDate
            timetable.semesterWeeks = min(max(semesterWeeks, 1), 30)
            timetable.periodsPerDay = min(max(periodsPerDay, 1), 12)
            timetable.lessonDurationMinutes = min(max(lessonDurationMinutes, 15), 240)
            timetable.breakDurationMinutes = min(max(breakDurationMinutes, 0), 120)
            timetable.skipHolidays = skipHolidays
            timetable.updatedAt = Date()
            savedTimetable = timetable
        } else {
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
            savedTimetable = timetable
        }

        let existingPeriods = try? modelContext.fetch(FetchDescriptor<CoursePeriod>())
        for period in existingPeriods?.filter({ $0.timetableID == savedTimetable.id }) ?? [] {
            modelContext.delete(period)
        }

        for period in CourseTimetablePlanner.defaultPeriods(for: savedTimetable) {
            modelContext.insert(period)
        }
        try? modelContext.save()
        onSave?(savedTimetable.id)
        if dismissOnSave {
            dismiss()
        }
    }

    private func deleteTimetable() {
        guard let timetable else { return }

        let timetableID = timetable.id
        let existingPeriods = (try? modelContext.fetch(FetchDescriptor<CoursePeriod>())) ?? []
        let existingCourses = (try? modelContext.fetch(FetchDescriptor<Course>())) ?? []
        let existingSessions = (try? modelContext.fetch(FetchDescriptor<CourseSession>())) ?? []
        let courseIDs = Set(existingCourses.filter { $0.timetableID == timetableID }.map(\.id))

        for session in existingSessions where courseIDs.contains(session.courseID) {
            modelContext.delete(session)
        }

        for course in existingCourses where course.timetableID == timetableID {
            modelContext.delete(course)
        }

        for period in existingPeriods where period.timetableID == timetableID {
            modelContext.delete(period)
        }

        modelContext.delete(timetable)
        try? modelContext.save()
        onDelete?(timetableID)
        dismiss()
    }
}

private struct CourseTimetableGridView: View {
    var timetable: CourseTimetable
    var timetables: [CourseTimetable]
    var periods: [CoursePeriod]
    var courses: [Course]
    var sessions: [CourseSession]
    @Binding var selectedWeek: Int
    @Binding var selectedTimetableID: UUID?
    var onCreateTimetable: () -> Void
    var onEditTimetable: () -> Void
    var onEditCourse: (Course) -> Void
    var weekStartPreference: WeekStartPreference
    var language: AppLanguage

    @State private var showingWeekPicker = false

    private let timeColumnWidth: CGFloat = 72
    private let periodRowHeight: CGFloat = 136
    private var calendar: Calendar {
        weekStartPreference.configuredCalendar
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 18) {
                header

                ScrollView(.vertical) {
                    ZStack {
                        timetableReferenceBackground
                        timetableWatermarks

                        VStack(spacing: 0) {
                            weekdayHeader
                            periodRows
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .verticalPageScrollOnly()
                .background(MeowPlannerTheme.fufuCalendarBackground.opacity(0.34), in: RoundedRectangle(cornerRadius: 18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(MeowPlannerTheme.caramel.opacity(0.16), lineWidth: 1)
                }
                .background {
                    HorizontalSwipeScrollDetector { horizontal in
                        switchWeek(by: horizontal < 0 ? 1 : -1)
                    }
                }
            }

            if showingWeekPicker {
                Color.black.opacity(0.16)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showingWeekPicker = false
                    }
                    .transition(.opacity)
                    .zIndex(3)

                weekPickerSheet
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(4)
            }
        }
        .animation(.snappy(duration: 0.22), value: showingWeekPicker)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            timetableGridHeaderIdentity

            Spacer()

            timetableToolbarButton(systemImage: "square.and.pencil") {
                onEditTimetable()
            }
        }
        .padding(.horizontal, 4)
    }

    private var timetableGridHeaderIdentity: some View {
        HStack(alignment: .center, spacing: 14) {
            FuFuAssetImage(size: 58)

            VStack(alignment: .leading, spacing: 4) {
                timetableTitleMenu
                weekPickerButton
            }
        }
    }

    private var weekPickerButton: some View {
        Button {
            showingWeekPicker = true
        } label: {
            HStack(spacing: 6) {
                Text(weekTitle(for: selectedWeek))
                    .font(.subheadline.weight(.semibold))
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(MeowPlannerTheme.caramel)
        }
        .buttonStyle(.plain)
    }

    private func timetableToolbarButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title2.weight(.semibold))
                .foregroundStyle(MeowPlannerTheme.caramel)
                .frame(width: 36, height: 36)
                .background(MeowPlannerTheme.warmCream.opacity(0.18), in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private var timetableTitleMenu: some View {
        Menu {
            ForEach(timetables) { option in
                Button {
                    selectedTimetableID = option.id
                    selectedWeek = 1
                } label: {
                    if option.id == timetable.id {
                        Label(option.name, systemImage: "checkmark")
                    } else {
                        Text(option.name)
                    }
                }
            }

            Divider()

            Button {
                onCreateTimetable()
            } label: {
                Label(PlannerCopy.text(.createTimetable, language: language), systemImage: "plus")
            }
        } label: {
            HStack(spacing: 8) {
                Text(timetable.name)
                    .font(.largeTitle.bold())
                Image(systemName: "chevron.down")
                    .font(.headline.weight(.bold))
            }
            .foregroundStyle(MeowPlannerTheme.caramel)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
    }

    private var weekPickerSheet: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(MeowPlannerTheme.caramel.opacity(0.32))
                .frame(width: 42, height: 5)
                .padding(.top, 10)

            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Text(timetable.name)
                        .font(.title2.bold())
                    Image(systemName: "chevron.down")
                        .font(.caption.bold())
                }
                .foregroundStyle(MeowPlannerTheme.cocoa)

                Text(semesterYearText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(MeowPlannerTheme.caramel.opacity(0.72))
            }

            LazyVGrid(columns: weekPickerColumns, spacing: 14) {
                ForEach(1...timetable.semesterWeeks, id: \.self) { week in
                    Button {
                        selectedWeek = week
                        showingWeekPicker = false
                    } label: {
                        VStack(spacing: 4) {
                            Text(weekTitle(for: week))
                                .font(.headline.weight(.semibold))
                            Text(weekDateRangeText(for: week))
                                .font(.caption.weight(.medium))
                        }
                        .foregroundStyle(week == selectedWeek ? .white : MeowPlannerTheme.cocoa)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            week == selectedWeek
                            ? MeowPlannerTheme.caramel
                            : MeowPlannerTheme.warmCream.opacity(0.22),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 22)
        }
        .background(MeowPlannerTheme.fufuCalendarBackground.opacity(0.98), in: RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(MeowPlannerTheme.blush.opacity(0.18), lineWidth: 1)
        }
        .shadow(color: MeowPlannerTheme.coffee.opacity(0.18), radius: 18, y: -4)
    }

    private var weekPickerColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 28), count: 5)
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            sideDateColumn

            ForEach(weekdays, id: \.columnIndex) { item in
                VStack(spacing: 7) {
                    Text(item.title)
                        .font(.title3.weight(.semibold))
                    Text(item.date.formatted(.dateTime.day()))
                        .font(.title2.weight(.medium))

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
                .padding(.vertical, 14)
                .overlay(alignment: .trailing) {
                    Rectangle()
                        .fill(MeowPlannerTheme.caramel.opacity(0.10))
                        .frame(width: 1)
                }
            }
        }
        .background(MeowPlannerTheme.warmCream.opacity(0.10))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(MeowPlannerTheme.caramel.opacity(0.14))
                .frame(height: 1)
        }
    }

    private var sideDateColumn: some View {
        VStack(spacing: 8) {
            Text(monthTitle)
                .font(.title3.weight(.bold))
            Text("W\(selectedWeek)")
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(MeowPlannerTheme.caramel)
        .frame(width: timeColumnWidth)
        .frame(maxHeight: .infinity)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(MeowPlannerTheme.caramel.opacity(0.10))
                .frame(width: 1)
        }
    }

    private var periodRows: some View {
        GeometryReader { proxy in
            let labelWidth = timeColumnWidth
            let dayWidth = max(60, (proxy.size.width - labelWidth) / 7)

            ZStack(alignment: .topLeading) {
                periodGridRows

                ForEach(weekdays, id: \.columnIndex) { weekday in
                    if !isSkippedHoliday(weekday.date) {
                        ForEach(overlaySessions(weekday: weekday.courseWeekday)) { session in
                            if let course = courses.first(where: { $0.id == session.courseID }) {
                                courseBlock(course: course, session: session)
                                    .frame(width: max(44, dayWidth - 12), height: courseBlockHeight(session))
                                    .offset(
                                        x: labelWidth + CGFloat(weekday.columnIndex) * dayWidth + 6,
                                        y: courseBlockOffset(session)
                                    )
                                    .zIndex(3)
                            }
                        }
                    }
                }
            }
            .frame(width: proxy.size.width, height: gridHeight, alignment: .topLeading)
        }
        .frame(height: gridHeight)
    }

    private var periodGridRows: some View {
        VStack(spacing: 0) {
            ForEach(sortedPeriods, id: \.id) { period in
                HStack(spacing: 0) {
                    periodLabel(for: period)

                    ForEach(weekdays, id: \.columnIndex) { weekday in
                        let skippedHoliday = isSkippedHoliday(weekday.date)

                        ZStack {
                            Rectangle()
                                .fill(MeowPlannerTheme.fufuCalendarBackground.opacity(0.08))

                            if skippedHoliday {
                                Text(ChineseCalendarInfoProvider.info(for: weekday.date, calendar: calendar).displayText)
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(MeowPlannerTheme.blush.opacity(0.72))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: periodRowHeight)
                        .overlay(alignment: .top) {
                            Rectangle()
                                .fill(MeowPlannerTheme.caramel.opacity(0.10))
                                .frame(height: 1)
                        }
                        .overlay(alignment: .trailing) {
                            Rectangle()
                                .fill(MeowPlannerTheme.caramel.opacity(0.08))
                                .frame(width: 1)
                        }
                    }
                }
            }
        }
    }

    private func periodLabel(for period: CoursePeriod) -> some View {
        VStack(spacing: 5) {
            Text("\(period.index)")
                .font(.title2.weight(.semibold))
            Text(formatMinutes(period.startMinutesFromMidnight))
            Text(formatMinutes(period.endMinutesFromMidnight))
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(MeowPlannerTheme.caramel)
        .frame(width: timeColumnWidth, height: periodRowHeight, alignment: .center)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(MeowPlannerTheme.caramel.opacity(0.10))
                .frame(height: 1)
        }
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(MeowPlannerTheme.caramel.opacity(0.10))
                .frame(width: 1)
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
        .onTapGesture(count: 2) {
            onEditCourse(course)
        }
    }

    private var timetableReferenceBackground: some View {
        LinearGradient(
            colors: [
                MeowPlannerTheme.fufuCalendarBackground.opacity(0.46),
                MeowPlannerTheme.fufuPlannerBackground.opacity(0.42),
                MeowPlannerTheme.blush.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var timetableWatermarks: some View {
        GeometryReader { proxy in
            ZStack {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 210, weight: .bold))
                    .foregroundStyle(MeowPlannerTheme.fufuPawTint.opacity(0.10))
                    .rotationEffect(.degrees(-12))
                    .position(x: proxy.size.width * 0.20, y: proxy.size.height * 0.42)

                Image(systemName: "pawprint.fill")
                    .font(.system(size: 260, weight: .bold))
                    .foregroundStyle(MeowPlannerTheme.blush.opacity(0.10))
                    .rotationEffect(.degrees(16))
                    .position(x: proxy.size.width * 0.84, y: proxy.size.height * 0.70)

                Image(systemName: "pawprint.fill")
                    .font(.system(size: 150, weight: .bold))
                    .foregroundStyle(MeowPlannerTheme.warmCream.opacity(0.10))
                    .rotationEffect(.degrees(8))
                    .position(x: proxy.size.width * 0.78, y: proxy.size.height * 0.14)
            }
        }
        .allowsHitTesting(false)
    }

    private func courseBlockHeight(_ session: CourseSession) -> CGFloat {
        let startIndex = rowIndex(forPeriodIndex: session.startPeriodIndex)
        let maxSpan = max(1, sortedPeriods.count - startIndex)
        let span = min(max(1, session.endPeriodIndex - session.startPeriodIndex + 1), maxSpan)
        return periodRowHeight * CGFloat(span) - 12
    }

    private func courseBlockOffset(_ session: CourseSession) -> CGFloat {
        CGFloat(rowIndex(forPeriodIndex: session.startPeriodIndex)) * periodRowHeight + 6
    }

    private func visibleSessions(weekday: Int, period: CoursePeriod) -> [CourseSession] {
        sessions
            .filter { $0.weekday == weekday }
            .filter { $0.startPeriodIndex == period.index }
            .filter { $0.isVisible(inWeek: selectedWeek) }
            .filter { session in courses.contains { $0.id == session.courseID && $0.timetableID == timetable.id } }
    }

    private func overlaySessions(weekday: Int) -> [CourseSession] {
        sortedPeriods.flatMap { period in
            visibleSessions(weekday: weekday, period: period)
        }
    }

    private func isSkippedHoliday(_ date: Date) -> Bool {
        timetable.skipHolidays && ChineseCalendarInfoProvider.info(for: date, calendar: calendar).isFestival
    }

    private var sortedPeriods: [CoursePeriod] {
        periods.sorted { $0.index < $1.index }
    }

    private var gridHeight: CGFloat {
        CGFloat(sortedPeriods.count) * periodRowHeight
    }

    private var currentWeek: Int {
        CourseTimetablePlanner.weekNumber(for: Date(), timetable: timetable, calendar: calendar)
    }

    private var semesterYearText: String {
        timetable.semesterStartDate.formatted(.dateTime.year())
    }

    private var monthTitle: String {
        guard let firstDate = weekdays.first?.date else {
            return ""
        }
        return firstDate.formatted(.dateTime.month(.abbreviated))
    }

    private func switchWeek(by offset: Int) {
        selectedWeek = min(max(selectedWeek + offset, 1), timetable.semesterWeeks)
    }

    private func weekDateRangeText(for week: Int) -> String {
        let dates = CourseTimetablePlanner.weekDates(forWeek: week, timetable: timetable, calendar: calendar)
        guard let first = dates.first, let last = dates.last else {
            return ""
        }
        return "\(first.formatted(.dateTime.month(.defaultDigits).day()))~\(last.formatted(.dateTime.month(.defaultDigits).day()))"
    }

    private func weekTitle(for week: Int) -> String {
        language == .chinese ? "第\(week)周" : "Week \(week)"
    }

    private var weekdays: [(columnIndex: Int, courseWeekday: Int, title: String, date: Date)] {
        CourseTimetablePlanner.weekDates(forWeek: selectedWeek, timetable: timetable, calendar: calendar)
            .enumerated()
            .map { offset, date in
                let courseWeekday = courseWeekday(for: date)
                return (
                    columnIndex: offset,
                    courseWeekday: courseWeekday,
                    title: weekdayTitle(for: courseWeekday),
                    date: date
                )
            }
    }

    private func courseWeekday(for date: Date) -> Int {
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 1 ? 7 : weekday - 1
    }

    private func weekdayTitle(for courseWeekday: Int) -> String {
        let titles = language == .chinese ? ["一", "二", "三", "四", "五", "六", "日"] : ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return titles[min(max(courseWeekday, 1), 7) - 1]
    }

    private func formatMinutes(_ value: Int) -> String {
        String(format: "%02d:%02d", value / 60, value % 60)
    }

    private func rowIndex(forPeriodIndex periodIndex: Int) -> Int {
        sortedPeriods.firstIndex { $0.index == periodIndex } ?? 0
    }
}

private struct TimetableDatePickerRow: View {
    var title: String
    @Binding var selection: Date
    var includesTime: Bool
    var language: AppLanguage

    @State private var isExpanded = false
    @State private var displayedMonth = Date()

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 10) {
            Button {
                isExpanded.toggle()
                displayedMonth = monthStart(for: selection)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(MeowPlannerTheme.caramel, in: RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(MeowPlannerTheme.caramel)
                        Text(primaryDateText)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(MeowPlannerTheme.cocoa)
                        Text(secondaryDateText)
                            .font(.caption)
                            .foregroundStyle(MeowPlannerTheme.caramel)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption.bold())
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .foregroundStyle(MeowPlannerTheme.caramel)
                }
                .padding(10)
                .background(MeowPlannerTheme.warmCream.opacity(0.30), in: RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(MeowPlannerTheme.blush.opacity(0.16), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                TimetableInlineDatePickerPanel(
                    selection: $selection,
                    displayedMonth: $displayedMonth,
                    includesTime: includesTime,
                    language: language
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 10)
    }

    private var primaryDateText: String {
        selection.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    private var secondaryDateText: String {
        let info = ChineseCalendarInfoProvider.info(for: selection, calendar: calendar)
        if includesTime {
            return "\(selection.formatted(.dateTime.hour().minute())) · \(info.displayText)"
        }
        return info.displayText
    }

    private func monthStart(for date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }
}

private struct TimetableInlineDatePickerPanel: View {
    @Binding var selection: Date
    @Binding var displayedMonth: Date
    var includesTime: Bool
    var language: AppLanguage

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.headline.bold())
                    .foregroundStyle(MeowPlannerTheme.cocoa)

                Spacer()

                monthNavigationButton(systemImage: "chevron.left", offset: -1)
                monthNavigationButton(systemImage: "chevron.right", offset: 1)
            }

            HStack {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MeowPlannerTheme.caramel)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(inlineCalendarDays, id: \.self) { date in
                    dayButton(for: date)
                }
            }

            if includesTime {
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .foregroundStyle(MeowPlannerTheme.caramel)
                    Text(language == .chinese ? "时间" : "Time")
                        .foregroundStyle(MeowPlannerTheme.cocoa)
                    Spacer()
                    DatePicker("", selection: $selection, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .fufuControlTint()
                }
                .padding(10)
                .background(MeowPlannerTheme.cream.opacity(0.52), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(12)
        .background(MeowPlannerTheme.fufuPlannerBackground, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(MeowPlannerTheme.blush.opacity(0.22), lineWidth: 1)
        }
    }

    private var weekdaySymbols: [String] {
        language == .chinese
            ? ["日", "一", "二", "三", "四", "五", "六"]
            : calendar.shortWeekdaySymbols
    }

    private var inlineCalendarDays: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start)
        else {
            return []
        }

        let start = firstWeek.start
        var days = [Date]()
        for offset in 0..<42 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            days.append(date)
        }
        return days
    }

    private func monthNavigationButton(systemImage: String, offset: Int) -> some View {
        Button {
            displayedMonth = calendar.date(byAdding: .month, value: offset, to: displayedMonth) ?? displayedMonth
        } label: {
            Image(systemName: systemImage)
                .font(.caption.bold())
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.borderless)
    }

    private func dayButton(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selection)
        let isInDisplayedMonth = calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month)

        return Button {
            selectDate(date)
        } label: {
            Text(date.formatted(.dateTime.day()))
                .font(.caption.weight(isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? .white : (isInDisplayedMonth ? MeowPlannerTheme.cocoa : MeowPlannerTheme.cocoa.opacity(0.36)))
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .background(isSelected ? MeowPlannerTheme.caramel : MeowPlannerTheme.warmCream.opacity(0.22), in: RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }

    private func selectDate(_ date: Date) {
        let time = calendar.dateComponents([.hour, .minute, .second], from: selection)
        let day = calendar.dateComponents([.year, .month, .day], from: date)
        var merged = DateComponents()
        merged.year = day.year
        merged.month = day.month
        merged.day = day.day
        merged.hour = time.hour
        merged.minute = time.minute
        merged.second = time.second
        selection = calendar.date(from: merged) ?? date
    }
}

private struct CourseEditorView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var preferences: [PlannerPreference]

    var timetable: CourseTimetable
    var course: Course?
    var courseSessions: [CourseSession]

    @State private var courseName = ""
    @State private var colorHex = PlannerPreference.defaultEventColorHexes[0]
    @State private var selectedWeekdays: Set<Int> = [1]
    @State private var startPeriodIndex = 1
    @State private var endPeriodIndex = 1
    @State private var startWeek = 1
    @State private var endWeek = 16
    @State private var teacherName = ""
    @State private var location = ""

    init(timetable: CourseTimetable, course: Course? = nil, courseSessions: [CourseSession] = []) {
        self.timetable = timetable
        self.course = course
        self.courseSessions = courseSessions

        let firstSession = courseSessions.sorted { lhs, rhs in
            if lhs.weekday == rhs.weekday {
                return lhs.startPeriodIndex < rhs.startPeriodIndex
            }
            return lhs.weekday < rhs.weekday
        }.first

        _courseName = State(initialValue: course?.name ?? "")
        _colorHex = State(initialValue: course?.colorHex ?? PlannerPreference.defaultEventColorHexes[0])
        _selectedWeekdays = State(initialValue: courseSessions.isEmpty ? [1] : Set(courseSessions.map(\.weekday)))
        _startPeriodIndex = State(initialValue: firstSession?.startPeriodIndex ?? 1)
        _endPeriodIndex = State(initialValue: firstSession?.endPeriodIndex ?? 1)
        _startWeek = State(initialValue: firstSession?.startWeek ?? 1)
        _endWeek = State(initialValue: firstSession?.endWeek ?? timetable.semesterWeeks)
        _teacherName = State(initialValue: course?.teacherName ?? "")
        _location = State(initialValue: course?.location ?? "")
    }

    private var availableColors: [String] {
        preferences.first?.eventColorHexes ?? PlannerPreference.defaultEventColorHexes
    }

    var body: some View {
        ZStack {
            MeowPlannerTheme.fufuPlannerBackground
                .overlay { MeowPlannerTheme.plannerGradient.opacity(0.82) }
                .overlay { timetableBackgroundMotifs }
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(editorTitle)
                        .font(.title.bold())
                        .foregroundStyle(MeowPlannerTheme.cocoa)

                    Spacer()

                    Button(PlannerCopy.text(.cancel, language: appLanguage)) {
                        cancelCourseEdit()
                    }
                    .keyboardShortcut(.cancelAction)

                    Button(PlannerCopy.text(.save, language: appLanguage)) {
                        saveCourse()
                    }
                    .disabled(courseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedWeekdays.isEmpty)
                }

                VStack(spacing: 0) {
                    TextField(PlannerCopy.text(.courseName, language: appLanguage), text: $courseName)
                        .font(.title3.weight(.semibold))
                        .textFieldStyle(.plain)
                        .padding(.vertical, 10)

                    Divider().opacity(0.35)

                    colorRow

                    Divider().opacity(0.35)

                    weekdayRow

                    Divider().opacity(0.35)

                    PlannerNumberInputRow(
                        title: PlannerCopy.text(.periodRange, language: appLanguage),
                        value: $startPeriodIndex,
                        range: 1...timetable.periodsPerDay
                    )
                        .onChange(of: startPeriodIndex) { _, newValue in
                            endPeriodIndex = max(endPeriodIndex, newValue)
                        }

                    Divider().opacity(0.35)

                    PlannerNumberInputRow(
                        title: PlannerCopy.text(.endPeriod, language: appLanguage),
                        value: $endPeriodIndex,
                        range: startPeriodIndex...timetable.periodsPerDay
                    )

                    Divider().opacity(0.35)

                    PlannerNumberInputRow(
                        title: PlannerCopy.text(.weekRange, language: appLanguage),
                        value: $startWeek,
                        range: 1...timetable.semesterWeeks
                    )
                        .onChange(of: startWeek) { _, newValue in
                            endWeek = max(endWeek, newValue)
                        }

                    Divider().opacity(0.35)

                    PlannerNumberInputRow(
                        title: PlannerCopy.text(.endWeek, language: appLanguage),
                        value: $endWeek,
                        range: startWeek...timetable.semesterWeeks
                    )

                    Divider().opacity(0.35)

                    TextField(PlannerCopy.text(.teacher, language: appLanguage), text: $teacherName)
                        .textFieldStyle(.plain)
                        .padding(.vertical, 10)

                    Divider().opacity(0.35)

                    TextField(PlannerCopy.text(.location, language: appLanguage), text: $location)
                        .textFieldStyle(.plain)
                        .padding(.vertical, 10)

                    Divider().opacity(0.35)

                    Button {
                        selectedWeekdays.insert(min(7, (selectedWeekdays.max() ?? 0) + 1))
                    } label: {
                        Label(PlannerCopy.text(.addOtherSessions, language: appLanguage), systemImage: "plus")
                    }
                    .fufuControlTint()
                    .buttonStyle(.borderless)
                    .padding(.vertical, 10)
                }
                .padding()
                .background(MeowPlannerTheme.fufuCalendarBackground.opacity(0.74), in: RoundedRectangle(cornerRadius: 14))

                Spacer()
            }
            .padding(24)
        }
        .frame(minWidth: 560, minHeight: 520)
    }

    private var editorTitle: String {
        if course == nil {
            return PlannerCopy.text(.newCourse, language: appLanguage)
        }
        return appLanguage == .chinese ? "编辑课程" : "Edit course"
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
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .allowsHitTesting(false)
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
                    Text(weekdayTitle(weekday))
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

    private func weekdayTitle(_ weekday: Int) -> String {
        let titles = language == .chinese ? ["一", "二", "三", "四", "五", "六", "日"] : ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return titles[weekday - 1]
    }

    private var language: AppLanguage {
        appLanguage
    }

    private func cancelCourseEdit() {
        dismiss()
    }

    private func saveCourse() {
        let trimmedCourseName = courseName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCourseName.isEmpty, !selectedWeekdays.isEmpty else { return }

        let savedCourse: Course
        if let course {
            course.name = trimmedCourseName
            course.colorHex = colorHex
            course.teacherName = teacherName.trimmingCharacters(in: .whitespacesAndNewlines)
            course.location = location.trimmingCharacters(in: .whitespacesAndNewlines)
            course.updatedAt = Date()
            savedCourse = course

            let existingSessions = (try? modelContext.fetch(FetchDescriptor<CourseSession>())) ?? []
            for session in existingSessions where session.courseID == course.id {
                modelContext.delete(session)
            }
        } else {
            let course = Course(
                timetableID: timetable.id,
                name: trimmedCourseName,
                colorHex: colorHex,
                teacherName: teacherName,
                location: location
            )
            modelContext.insert(course)
            savedCourse = course
        }

        for weekday in selectedWeekdays.sorted() {
            let session = CourseSession(
                courseID: savedCourse.id,
                weekday: weekday,
                startPeriodIndex: startPeriodIndex,
                endPeriodIndex: endPeriodIndex,
                startWeek: startWeek,
                endWeek: endWeek
            )
            modelContext.insert(session)
        }

        try? modelContext.save()
        dismiss()
    }
}

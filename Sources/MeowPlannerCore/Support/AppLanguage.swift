import Foundation

public enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case english = "en"
    case chinese = "zh-Hans"

    public static let storageKey = "appLanguage"
    public static let updatedAtStorageKey = "appLanguage.updatedAt"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .english: "English"
        case .chinese: "中文"
        }
    }

    public init(storedValue: String) {
        self = AppLanguage(rawValue: storedValue) ?? .english
    }
}

public enum PlannerTextKey: String, Sendable {
    case calendar
    case focus
    case habits
    case settings
    case scheduleView
    case timeline
    case newSchedule
    case schedule
    case scheduleDisplay
    case allSchedules
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
    case endPeriod
    case endWeek
    case addOtherSessions
    case todo
    case focusWithFuFu
    case focusSubtitle
    case focusTitle
    case defaultFocusBlock
    case start
    case pause
    case resume
    case finish
    case recentFocus
    case editFocusSession
    case completedMinutes
    case noFocusSessions
    case noFocusSessionsMessage
    case habitsSubtitle
    case habit
    case noHabits
    case noHabitsMessage
    case addHabit
    case dayStreak
    case checked
    case checkIn
    case habitName
    case icon
    case paw
    case water
    case book
    case walk
    case newHabit
    case cancel
    case save
    case fufuTimePlanner
    case appSubtitle
    case title
    case allDay
    case date
    case startDate
    case hasEndTime
    case end
    case time
    case multiDayTask
    case deadlineDate
    case reminderBefore
    case reminder
    case noReminder
    case repeatSchedule
    case repeatNone
    case repeatDaily
    case repeatWeekdays
    case repeatWeekly
    case repeatMonthly
    case tag
    case selectTag
    case newTag
    case eventTags
    case color
    case noTag
    case notes
    case editSchedule
    case deleteSchedule
    case clearDay
    case clearDayMessage
    case addSchedule
    case anytime
    case dueDate
    case due
    case newTodo
    case editTodo
    case addTodo
    case deleteTodo
    case allTodos
    case defaultTodoGroup
    case todoGroup
    case newTodoGroup
    case editTodoGroup
    case deleteTodoGroup
    case groupName
    case noTodos
    case noTodosMessage
    case noTodosInGroup
    case noTodosInGroupMessage
    case todoListSubtitle
    case language
    case account
    case signedIn
    case notSignedIn
    case signIn
    case signInExistingAccount
    case createAccount
    case createNewAccount
    case signOut
    case loginButton
    case accountLogin
    case email
    case wechat
    case password
    case currentPassword
    case newPassword
    case confirmNewPassword
    case passwordConfirmationMismatch
    case sendResetLink
    case passwordResetCodeSent
    case passwordResetLinkSent
    case passwordResetComplete
    case forgotPassword
    case changePassword
    case linkAccount
    case linkEmail
    case deleteAccount
    case deleteAccountWarning
    case deleteAccountConfirmationMessage
    case verificationCode
    case sendVerificationCode
    case resetPassword
    case accountIdentifier
    case optionalEmail
    case provider
    case wechatNeedsSetup
    case planning
    case focusSettings
    case personalizationSettings
    case defaultFocus
    case weekStartsOn
    case localReminders
    case menuBarIcon
    case showMenuBarIcon
    case dockIcon
    case showDockIcon
    case defaultAllDaySchedule
    case showCompletedSchedules
    case hideCompletedSchedules
    case completedScheduleStrikethrough
    case showChineseCalendar
    case widgetSettings
    case widgetBackground
    case chooseBackgroundImage
    case bottomNavigation
    case restoreDefault
    case scheduleCollapsedStartHour
    case scheduleCollapsedEndHour
    case timeCollapse
    case collapseTimeRange
    case timeDisplay
    case eventColors
    case newColor
    case addColor
    case editColor
    case deleteColor
    case sync
    case refreshCalendarFromCloud
    case icloudSync
    case icloudDescription
    case scope
    case scopeDescription
    case openMeowPlanner
    case today
    case todaySchedule
    case noSchedules
    case noSchedulesMessage
    case focusTimer
    case quitMeowPlanner
    case focusTimeline
    case focusInsights
    case focusModeCountdown
    case focusModeStopwatch
    case focusTag
    case focusTags
    case uncategorizedFocus
    case newFocusTag
    case editFocusTag
    case totalFocusTime
    case focusCount
    case averageFocus
    case activeDays
    case longestFocus
    case focusDistribution
    case focusTimeShare
    case addFocusRecord
    case gapTime
}

public enum PlannerCopy {
    private static let englishText: [PlannerTextKey: String] = [
        .calendar: "Calendar",
        .focus: "Focus",
        .habits: "Habits",
        .settings: "Settings",
        .scheduleView: "Timeline view",
        .timeline: "Timeline",
        .newSchedule: "New Schedule",
        .schedule: "Agenda",
        .scheduleDisplay: "Schedule display",
        .allSchedules: "All schedules",
        .timetable: "Schedule",
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
        .endPeriod: "End period",
        .endWeek: "End week",
        .addOtherSessions: "Add other sessions",
        .todo: "To-do",
        .focusWithFuFu: "Focus with FuFu",
        .focusSubtitle: "A calm 25-minute timer for one task at a time.",
        .focusTitle: "Focus title",
        .defaultFocusBlock: "FuFu focus block",
        .start: "Start",
        .pause: "Pause",
        .resume: "Resume",
        .finish: "Finish",
        .recentFocus: "Recent focus",
        .editFocusSession: "Edit Focus",
        .completedMinutes: "Completed minutes",
        .noFocusSessions: "No focus sessions yet",
        .noFocusSessionsMessage: "Start one focused block and FuFu will remember it here.",
        .habitsSubtitle: "Small check-ins with a FuFu nudge.",
        .habit: "Habit",
        .noHabits: "No habits yet",
        .noHabitsMessage: "Create one daily ritual and FuFu will track your streak.",
        .addHabit: "Add Habit",
        .dayStreak: "day streak",
        .checked: "Checked",
        .checkIn: "Check in",
        .habitName: "Habit name",
        .icon: "Icon",
        .paw: "Paw",
        .water: "Water",
        .book: "Book",
        .walk: "Walk",
        .newHabit: "New Habit",
        .cancel: "Cancel",
        .save: "Save",
        .fufuTimePlanner: "FuFu's time planner",
        .appSubtitle: "Schedules and focus",
        .title: "Title",
        .allDay: "All-day",
        .date: "Date",
        .startDate: "Start",
        .hasEndTime: "Has end time",
        .end: "End",
        .time: "Time",
        .multiDayTask: "Multi-day task",
        .deadlineDate: "Deadline date",
        .reminderBefore: "Reminder",
        .reminder: "Reminder",
        .noReminder: "No reminder",
        .repeatSchedule: "Repeat",
        .repeatNone: "None",
        .repeatDaily: "Every day",
        .repeatWeekdays: "Every weekday",
        .repeatWeekly: "Every week",
        .repeatMonthly: "Every month",
        .tag: "Tag",
        .selectTag: "Select tag",
        .newTag: "New tag",
        .eventTags: "Schedule tags",
        .color: "Color",
        .noTag: "No tag",
        .notes: "Notes",
        .editSchedule: "Edit Schedule",
        .deleteSchedule: "Delete Schedule",
        .clearDay: "A clear FuFu day",
        .clearDayMessage: "Add a schedule or todo when you are ready.",
        .addSchedule: "Add Schedule",
        .anytime: "Anytime",
        .dueDate: "Due date",
        .due: "Due",
        .newTodo: "New Todo",
        .editTodo: "Edit Todo",
        .addTodo: "Add Todo",
        .deleteTodo: "Delete Todo",
        .allTodos: "All",
        .defaultTodoGroup: "Default",
        .todoGroup: "Group",
        .newTodoGroup: "New Group",
        .editTodoGroup: "Edit Group",
        .deleteTodoGroup: "Delete Group",
        .groupName: "Group name",
        .noTodos: "No todos yet",
        .noTodosMessage: "Create a task and FuFu will keep it here.",
        .noTodosInGroup: "No todos in this group",
        .noTodosInGroupMessage: "Add a task to this group when you are ready.",
        .todoListSubtitle: "Grouped tasks and gentle deadlines",
        .language: "Language",
        .account: "Account",
        .signedIn: "Signed in",
        .notSignedIn: "Not signed in",
        .signIn: "Sign In",
        .signInExistingAccount: "Sign In",
        .createAccount: "Create Account",
        .createNewAccount: "Create New Account",
        .signOut: "Sign Out",
        .loginButton: "Log In",
        .accountLogin: "Account",
        .email: "Email",
        .wechat: "WeChat",
        .password: "Password",
        .currentPassword: "Current Password",
        .newPassword: "New Password",
        .confirmNewPassword: "Confirm New Password",
        .passwordConfirmationMismatch: "The two passwords do not match.",
        .sendResetLink: "Send Link",
        .passwordResetCodeSent: "A reset code has been sent to your email.",
        .passwordResetLinkSent: "Check your email link. If you do not see it in inbox, check spam.",
        .passwordResetComplete: "Password updated. Sign in with the new password.",
        .forgotPassword: "Forgot Password",
        .changePassword: "Change Password",
        .linkAccount: "Link Account",
        .linkEmail: "Link Email",
        .deleteAccount: "Delete Account",
        .deleteAccountWarning: "Deleting your account will permanently remove your cloud planner data and cannot be undone.",
        .deleteAccountConfirmationMessage: "Confirm account deletion? Deleted accounts cannot be recovered.",
        .verificationCode: "Verification Code",
        .sendVerificationCode: "Send Code",
        .resetPassword: "Reset Password",
        .accountIdentifier: "Account",
        .optionalEmail: "Email (Optional)",
        .provider: "Provider",
        .wechatNeedsSetup: "Needs platform setup",
        .planning: "Planning",
        .focusSettings: "Focus",
        .personalizationSettings: "Personalization",
        .defaultFocus: "Default focus",
        .weekStartsOn: "Week starts on",
        .localReminders: "Local reminders",
        .menuBarIcon: "Menu bar icon",
        .showMenuBarIcon: "Show icon in menu bar",
        .dockIcon: "Dock icon",
        .showDockIcon: "Show icon in Dock",
        .defaultAllDaySchedule: "New schedules default to all-day",
        .showCompletedSchedules: "Show completed schedules",
        .hideCompletedSchedules: "Hide completed schedules",
        .completedScheduleStrikethrough: "Strikethrough completed schedules",
        .showChineseCalendar: "Show Chinese lunar calendar and festivals",
        .widgetSettings: "Widget settings",
        .widgetBackground: "Widget background",
        .chooseBackgroundImage: "Choose background image",
        .bottomNavigation: "Bottom navigation",
        .restoreDefault: "Restore default",
        .scheduleCollapsedStartHour: "Collapsed start",
        .scheduleCollapsedEndHour: "Collapsed end",
        .timeCollapse: "Time collapse",
        .collapseTimeRange: "Collapse time range",
        .timeDisplay: "Time display",
        .eventColors: "Colors",
        .newColor: "New color",
        .addColor: "Add color",
        .editColor: "Edit color",
        .deleteColor: "Delete color",
        .sync: "Sync",
        .refreshCalendarFromCloud: "Sync latest cloud content",
        .icloudSync: "Cloud account sync",
        .icloudDescription: "Signed-in account schedules, todos, habits, focus sessions, preferences, and timetables sync through Firebase Firestore.",
        .scope: "Scope",
        .scopeDescription: "System calendar sync, Google/Outlook sync, diary, countdown days, AI parsing, and a full widget suite are intentionally out of scope for this first version.",
        .openMeowPlanner: "Open MeowPlanner",
        .today: "Today",
        .todaySchedule: "Today Schedule",
        .noSchedules: "No schedules",
        .noSchedulesMessage: "FuFu has no plans for this date yet.",
        .focusTimer: "Focus Timer",
        .quitMeowPlanner: "Quit MeowPlanner",
        .focusTimeline: "Timeline",
        .focusInsights: "Insights",
        .focusModeCountdown: "Countdown",
        .focusModeStopwatch: "Timer",
        .focusTag: "Focus tag",
        .focusTags: "Focus tags",
        .uncategorizedFocus: "Uncategorized",
        .newFocusTag: "New Focus Tag",
        .editFocusTag: "Edit Focus Tag",
        .totalFocusTime: "Focus time",
        .focusCount: "Sessions",
        .averageFocus: "Average",
        .activeDays: "Active days",
        .longestFocus: "Longest focus",
        .focusDistribution: "Focus distribution",
        .focusTimeShare: "Focus time share",
        .addFocusRecord: "Add focus record",
        .gapTime: "Gap"
    ]

    private static let chineseText: [PlannerTextKey: String] = [
        .calendar: "月历",
        .focus: "专注",
        .habits: "习惯",
        .settings: "设置",
        .scheduleView: "时间轴视图",
        .timeline: "时间轴",
        .newSchedule: "新建日程",
        .schedule: "日程",
        .scheduleDisplay: "日程显示",
        .allSchedules: "全部",
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
        .endPeriod: "结束节次",
        .endWeek: "结束周",
        .addOtherSessions: "添加其他上课时间",
        .todo: "待办",
        .focusWithFuFu: "和 FuFu 一起专注",
        .focusSubtitle: "一次只做一件事的 25 分钟安静计时器。",
        .focusTitle: "专注标题",
        .defaultFocusBlock: "FuFu 专注时段",
        .start: "开始",
        .pause: "暂停",
        .resume: "继续",
        .finish: "完成",
        .recentFocus: "最近专注",
        .editFocusSession: "编辑专注",
        .completedMinutes: "完成分钟数",
        .noFocusSessions: "还没有专注记录",
        .noFocusSessionsMessage: "开始一次专注，FuFu 会把记录放在这里。",
        .habitsSubtitle: "用 FuFu 的轻提醒完成小打卡。",
        .habit: "习惯",
        .noHabits: "还没有习惯",
        .noHabitsMessage: "创建一个每日习惯，FuFu 会记录你的连续打卡。",
        .addHabit: "添加习惯",
        .dayStreak: "天连续",
        .checked: "已打卡",
        .checkIn: "打卡",
        .habitName: "习惯名称",
        .icon: "图标",
        .paw: "爪印",
        .water: "喝水",
        .book: "阅读",
        .walk: "散步",
        .newHabit: "新建习惯",
        .cancel: "取消",
        .save: "保存",
        .fufuTimePlanner: "FuFu 的喵系时间规划器",
        .appSubtitle: "日程和专注",
        .title: "标题",
        .allDay: "全天计划",
        .date: "日期",
        .startDate: "开始",
        .hasEndTime: "有结束时间",
        .end: "结束",
        .time: "时间",
        .multiDayTask: "多天任务",
        .deadlineDate: "截止日期",
        .reminderBefore: "提醒",
        .reminder: "提醒",
        .noReminder: "无提醒",
        .repeatSchedule: "重复",
        .repeatNone: "不重复",
        .repeatDaily: "每天",
        .repeatWeekdays: "每个工作日",
        .repeatWeekly: "每周同一天",
        .repeatMonthly: "每月同一天",
        .tag: "标签",
        .selectTag: "选择标签",
        .newTag: "新建标签",
        .eventTags: "日程标签",
        .color: "颜色",
        .noTag: "无标签",
        .notes: "备注",
        .editSchedule: "编辑日程",
        .deleteSchedule: "删除日程",
        .clearDay: "FuFu 今天很清爽",
        .clearDayMessage: "准备好后添加一个日程或待办。",
        .addSchedule: "添加日程",
        .anytime: "任意时间",
        .dueDate: "截止日期",
        .due: "截止",
        .newTodo: "新建待办",
        .editTodo: "编辑待办",
        .addTodo: "添加待办",
        .deleteTodo: "删除待办",
        .allTodos: "全部",
        .defaultTodoGroup: "默认",
        .todoGroup: "分组",
        .newTodoGroup: "新建组",
        .editTodoGroup: "编辑组",
        .deleteTodoGroup: "删除组",
        .groupName: "组名称",
        .noTodos: "还没有待办",
        .noTodosMessage: "创建一个待办，FuFu 会帮你放在这里。",
        .noTodosInGroup: "这个组还没有待办",
        .noTodosInGroupMessage: "准备好后在这个组里添加待办。",
        .todoListSubtitle: "分组待办和温柔截止日期",
        .language: "语言",
        .account: "账号",
        .signedIn: "已登录",
        .notSignedIn: "未登录",
        .signIn: "登录",
        .signInExistingAccount: "登录已有账号",
        .createAccount: "注册账号",
        .createNewAccount: "新建账号",
        .signOut: "退出登录",
        .loginButton: "登录",
        .accountLogin: "账号",
        .email: "邮箱",
        .wechat: "微信",
        .password: "密码",
        .currentPassword: "当前密码",
        .newPassword: "新密码",
        .confirmNewPassword: "再次输入新密码",
        .passwordConfirmationMismatch: "两次输入的密码不一样",
        .sendResetLink: "发送链接",
        .passwordResetCodeSent: "验证码已发送到你的邮箱。",
        .passwordResetLinkSent: "查看邮箱链接，如果在 inbox 里面没有找到，请查看 spam",
        .passwordResetComplete: "密码已更新，请使用新密码登录。",
        .forgotPassword: "忘记密码",
        .changePassword: "更改密码",
        .linkAccount: "关联账号",
        .linkEmail: "绑定邮箱",
        .deleteAccount: "删除账号",
        .deleteAccountWarning: "删除账号会永久删除你的云端规划数据，且无法撤销。",
        .deleteAccountConfirmationMessage: "是否确认删除账号，删除账号不可找回",
        .verificationCode: "验证码",
        .sendVerificationCode: "发送验证码",
        .resetPassword: "重设密码",
        .accountIdentifier: "账号",
        .optionalEmail: "邮箱（可选）",
        .provider: "登录方式",
        .wechatNeedsSetup: "需要开放平台配置",
        .planning: "规划",
        .focusSettings: "专注",
        .personalizationSettings: "个性化设置",
        .defaultFocus: "默认专注",
        .weekStartsOn: "每周开始于",
        .localReminders: "本地提醒",
        .menuBarIcon: "菜单栏图标",
        .showMenuBarIcon: "在菜单栏中显示图标",
        .dockIcon: "Dock 图标",
        .showDockIcon: "在 Dock 中显示图标",
        .defaultAllDaySchedule: "新日程默认全天计划",
        .showCompletedSchedules: "显示已完成",
        .hideCompletedSchedules: "完成后隐藏",
        .completedScheduleStrikethrough: "完成后显示删除线",
        .showChineseCalendar: "显示中国农历和节日",
        .widgetSettings: "小组件设置",
        .widgetBackground: "小组件背景",
        .chooseBackgroundImage: "选择背景图片",
        .bottomNavigation: "底部导航",
        .restoreDefault: "恢复默认",
        .scheduleCollapsedStartHour: "折叠开始",
        .scheduleCollapsedEndHour: "折叠结束",
        .timeCollapse: "时间折叠",
        .collapseTimeRange: "折叠时间范围",
        .timeDisplay: "时间显示",
        .eventColors: "颜色",
        .newColor: "新颜色",
        .addColor: "添加颜色",
        .editColor: "编辑颜色",
        .deleteColor: "删除颜色",
        .sync: "同步",
        .refreshCalendarFromCloud: "同步最新云端内容",
        .icloudSync: "云端账号同步",
        .icloudDescription: "已登录账号的日程、待办、习惯、专注记录、偏好设置和课程表会通过 Firebase Firestore 同步。",
        .scope: "范围",
        .scopeDescription: "系统日历同步、Google/Outlook 同步、日记、倒数日、AI 解析和完整小组件套件不包含在第一版范围内。",
        .openMeowPlanner: "打开 MeowPlanner",
        .today: "今日",
        .todaySchedule: "今日日程",
        .noSchedules: "没有日程",
        .noSchedulesMessage: "FuFu 这一天还没有安排。",
        .focusTimer: "专注计时",
        .quitMeowPlanner: "退出 MeowPlanner",
        .focusTimeline: "时间轴",
        .focusInsights: "数据洞察",
        .focusModeCountdown: "倒计时",
        .focusModeStopwatch: "计时",
        .focusTag: "专注标签",
        .focusTags: "专注标签",
        .uncategorizedFocus: "未分类",
        .newFocusTag: "新建专注标签",
        .editFocusTag: "编辑专注标签",
        .totalFocusTime: "专注时间",
        .focusCount: "专注次数",
        .averageFocus: "平均时长",
        .activeDays: "活跃天数",
        .longestFocus: "最长专注",
        .focusDistribution: "专注时间分布",
        .focusTimeShare: "专注时间占比",
        .addFocusRecord: "添加专注记录",
        .gapTime: "间隔"
    ]

    public static func text(_ key: PlannerTextKey, language: AppLanguage) -> String {
        switch language {
        case .english:
            englishText[key] ?? key.rawValue
        case .chinese:
            chineseText[key] ?? englishText[key] ?? key.rawValue
        }
    }

    public static func daySummary(scheduleCount: Int, todoCount: Int, language: AppLanguage) -> String {
        switch language {
        case .english:
            "\(scheduleCount) schedules · \(todoCount) todos"
        case .chinese:
            "\(scheduleCount) 个日程 · \(todoCount) 个待办"
        }
    }

    public static func scheduleSummary(scheduleCount: Int, language: AppLanguage) -> String {
        switch language {
        case .english:
            "\(scheduleCount) schedules"
        case .chinese:
            "\(scheduleCount) 个日程"
        }
    }

    public static func minutes(_ count: Int, language: AppLanguage) -> String {
        switch language {
        case .english: "\(count) min"
        case .chinese: "\(count) 分钟"
        }
    }

    public static func minutesUnit(language: AppLanguage) -> String {
        switch language {
        case .english: "min"
        case .chinese: "分钟"
        }
    }

    public static func reminder(minutes: Int, language: AppLanguage) -> String {
        switch language {
        case .english: "Reminder \(minutes) min before"
        case .chinese: "提前 \(minutes) 分钟提醒"
        }
    }

    public static func streak(days: Int, language: AppLanguage) -> String {
        switch language {
        case .english: "\(days) day streak"
        case .chinese: "连续 \(days) 天"
        }
    }
}

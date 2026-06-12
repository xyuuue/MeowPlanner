import Foundation
import Testing
@testable import MeowPlannerCore

@Suite("App language")
struct AppLanguageTests {
    @Test("language display names are available in English and Chinese")
    func languageDisplayNamesAreAvailable() {
        #expect(AppLanguage.english.displayName == "English")
        #expect(AppLanguage.chinese.displayName == "中文")
        #expect(AppLanguage.storageKey == "appLanguage")
    }

    @Test("planner copy resolves core navigation labels")
    func plannerCopyResolvesCoreNavigationLabels() {
        #expect(PlannerCopy.text(.calendar, language: .english) == "Calendar")
        #expect(PlannerCopy.text(.calendar, language: .chinese) == "月历")
        #expect(PlannerCopy.text(.timetable, language: .english) == "Schedule")
        #expect(PlannerCopy.text(.schedule, language: .english) == "Agenda")
        #expect(PlannerCopy.text(.schedule, language: .chinese) == "日程")
        #expect(PlannerCopy.text(.scheduleDisplay, language: .english) == "Schedule display")
        #expect(PlannerCopy.text(.scheduleDisplay, language: .chinese) == "日程显示")
        #expect(PlannerCopy.text(.scheduleView, language: .english) == "Timeline view")
        #expect(PlannerCopy.text(.scheduleView, language: .chinese) == "时间轴视图")
        #expect(PlannerCopy.text(.allSchedules, language: .english) == "All schedules")
        #expect(PlannerCopy.text(.allSchedules, language: .chinese) == "全部")
        #expect(PlannerCopy.text(.dockIcon, language: .english) == "Dock icon")
        #expect(PlannerCopy.text(.dockIcon, language: .chinese) == "Dock 图标")
        #expect(PlannerCopy.text(.showDockIcon, language: .english) == "Show icon in Dock")
        #expect(PlannerCopy.text(.showDockIcon, language: .chinese) == "在 Dock 中显示图标")
        #expect(PlannerCopy.text(.todo, language: .english) == "To-do")
        #expect(PlannerCopy.text(.settings, language: .english) == "Settings")
        #expect(PlannerCopy.text(.settings, language: .chinese) == "设置")
    }

    @Test("planner copy resolves account labels")
    func plannerCopyResolvesAccountLabels() {
        #expect(PlannerCopy.text(.account, language: .english) == "Account")
        #expect(PlannerCopy.text(.account, language: .chinese) == "账号")
        #expect(PlannerCopy.text(.email, language: .english) == "Email")
        #expect(PlannerCopy.text(.email, language: .chinese) == "邮箱")
        #expect(PlannerCopy.text(.phoneComingSoon, language: .english) == "Coming soon")
        #expect(PlannerCopy.text(.wechatNeedsSetup, language: .chinese) == "需要开放平台配置")
    }

    @Test("English product copy contains no Chinese text")
    func englishProductCopyContainsNoChineseText() {
        #expect(PlannerCopy.text(.fufuTimePlanner, language: .english) == "FuFu's time planner")
        #expect(!PlannerCopy.text(.fufuTimePlanner, language: .english).contains("喵"))
        #expect(PlannerCopy.text(.fufuTimePlanner, language: .chinese) == "FuFu 的喵系时间规划器")
    }

    @Test("planner copy formats counts and focus durations")
    func plannerCopyFormatsCountsAndFocusDurations() {
        #expect(PlannerCopy.daySummary(scheduleCount: 2, todoCount: 3, language: .english) == "2 schedules · 3 todos")
        #expect(PlannerCopy.daySummary(scheduleCount: 2, todoCount: 3, language: .chinese) == "2 个日程 · 3 个待办")
        #expect(PlannerCopy.minutes(25, language: .english) == "25 min")
        #expect(PlannerCopy.minutes(25, language: .chinese) == "25 分钟")
    }

    @Test("all-day event summary follows selected language")
    func allDayEventSummaryFollowsSelectedLanguage() throws {
        let event = PlannerEvent(
            title: "Portfolio day",
            startDate: Date(timeIntervalSince1970: 0),
            isAllDay: true
        )

        #expect(event.timeSummary(language: .english) == "All-day")
        #expect(event.timeSummary(language: .chinese) == "全天计划")
    }
}

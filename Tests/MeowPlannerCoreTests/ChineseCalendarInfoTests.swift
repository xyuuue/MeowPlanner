import Foundation
import Testing
@testable import MeowPlannerCore

@Suite("Chinese calendar info")
struct ChineseCalendarInfoTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }()

    @Test("lunar festivals resolve from Chinese calendar dates")
    func lunarFestivalsResolveFromChineseCalendarDates() throws {
        #expect(ChineseCalendarInfoProvider.info(for: try dateOnly("2026-02-17"), calendar: calendar).lunarText == "正月初一")
        #expect(ChineseCalendarInfoProvider.info(for: try dateOnly("2026-02-17"), calendar: calendar).festivalName == "春节")
        #expect(ChineseCalendarInfoProvider.info(for: try dateOnly("2026-03-03"), calendar: calendar).festivalName == "元宵节")
        #expect(ChineseCalendarInfoProvider.info(for: try dateOnly("2026-06-19"), calendar: calendar).festivalName == "端午节")
        #expect(ChineseCalendarInfoProvider.info(for: try dateOnly("2026-09-25"), calendar: calendar).festivalName == "中秋节")
        #expect(ChineseCalendarInfoProvider.info(for: try dateOnly("2026-10-18"), calendar: calendar).festivalName == "重阳节")
    }

    @Test("lunar new year's eve resolves from final lunar month day")
    func lunarNewYearsEveResolvesFromFinalLunarMonthDay() throws {
        let info = ChineseCalendarInfoProvider.info(for: try dateOnly("2026-02-16"), calendar: calendar)

        #expect(info.lunarText == "廿九")
        #expect(info.festivalName == "除夕")
        #expect(info.displayText == "除夕")
    }

    @Test("fixed gregorian festivals and qingming resolve")
    func fixedGregorianFestivalsAndQingmingResolve() throws {
        #expect(ChineseCalendarInfoProvider.info(for: try dateOnly("2026-01-01"), calendar: calendar).festivalName == "元旦")
        #expect(ChineseCalendarInfoProvider.info(for: try dateOnly("2026-04-05"), calendar: calendar).festivalName == "清明")
        #expect(ChineseCalendarInfoProvider.info(for: try dateOnly("2026-05-01"), calendar: calendar).festivalName == "劳动节")
        #expect(ChineseCalendarInfoProvider.info(for: try dateOnly("2026-10-01"), calendar: calendar).festivalName == "国庆节")
    }

    @Test("floating gregorian observances resolve only for display info")
    func floatingGregorianObservancesResolveOnlyForDisplayInfo() throws {
        let fathersDay = try dateOnly("2026-06-21")
        let mothersDay = try dateOnly("2026-05-10")
        let ordinarySunday = try dateOnly("2026-06-14")

        #expect(ChineseCalendarInfoProvider.info(for: fathersDay, calendar: calendar).festivalName == nil)
        #expect(ChineseCalendarInfoProvider.displayInfo(for: fathersDay, calendar: calendar, includesFloatingGregorianObservances: true).festivalName == "父亲节")
        #expect(ChineseCalendarInfoProvider.displayInfo(for: mothersDay, calendar: calendar, includesFloatingGregorianObservances: true).festivalName == "母亲节")
        #expect(ChineseCalendarInfoProvider.displayInfo(for: ordinarySunday, calendar: calendar, includesFloatingGregorianObservances: true).festivalName == nil)
    }

    @Test("floating gregorian observances do not replace core festivals")
    func floatingGregorianObservancesDoNotReplaceCoreFestivals() throws {
        let info = ChineseCalendarInfoProvider.displayInfo(
            for: try dateOnly("2026-06-19"),
            calendar: calendar,
            includesFloatingGregorianObservances: true
        )

        #expect(info.festivalName == "端午节")
    }

    @Test("plain lunar day uses compact day label")
    func plainLunarDayUsesCompactDayLabel() throws {
        let info = ChineseCalendarInfoProvider.info(for: try dateOnly("2026-06-02"), calendar: calendar)

        #expect(info.festivalName == nil)
        #expect(!info.lunarText.isEmpty)
        #expect(info.displayText == info.lunarText)
    }

    private func dateOnly(_ value: String) throws -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return try #require(formatter.date(from: value))
    }
}

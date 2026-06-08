import Foundation

public struct ChineseCalendarDayInfo: Sendable, Equatable {
    public let lunarText: String
    public let festivalName: String?

    public init(lunarText: String, festivalName: String? = nil) {
        self.lunarText = lunarText
        self.festivalName = festivalName
    }

    public var displayText: String {
        festivalName ?? lunarText
    }

    public var isFestival: Bool {
        festivalName != nil
    }
}

public enum ChineseCalendarInfoProvider {
    public static func info(for date: Date, calendar: Calendar = .current) -> ChineseCalendarDayInfo {
        let normalizedDate = midday(for: date, calendar: calendar)
        var chineseCalendar = Calendar(identifier: .chinese)
        chineseCalendar.timeZone = calendar.timeZone

        let lunarComponents = chineseCalendar.dateComponents([.month, .day, .isLeapMonth], from: normalizedDate)
        let lunarMonth = lunarComponents.month ?? 1
        let lunarDay = lunarComponents.day ?? 1
        let isLeapMonth = lunarComponents.isLeapMonth ?? false
        let lunarText = lunarText(month: lunarMonth, day: lunarDay, isLeapMonth: isLeapMonth)
        let daysInLunarMonth = chineseCalendar.range(of: .day, in: .month, for: normalizedDate)?.count ?? 30

        return ChineseCalendarDayInfo(
            lunarText: lunarText,
            festivalName: lunarFestival(month: lunarMonth, day: lunarDay, isLeapMonth: isLeapMonth, daysInMonth: daysInLunarMonth)
                ?? qingmingFestival(for: normalizedDate, calendar: calendar)
                ?? gregorianFestival(for: normalizedDate, calendar: calendar)
        )
    }

    private static func midday(for date: Date, calendar: Calendar) -> Date {
        let startOfDay = calendar.startOfDay(for: date)
        return calendar.date(bySettingHour: 12, minute: 0, second: 0, of: startOfDay) ?? startOfDay
    }

    private static func lunarFestival(
        month: Int,
        day: Int,
        isLeapMonth: Bool,
        daysInMonth: Int
    ) -> String? {
        guard !isLeapMonth else {
            return nil
        }

        if month == 12, day == daysInMonth {
            return "除夕"
        }

        return switch (month, day) {
        case (1, 1): "春节"
        case (1, 15): "元宵节"
        case (2, 2): "龙抬头"
        case (5, 5): "端午节"
        case (7, 7): "七夕"
        case (8, 15): "中秋节"
        case (9, 9): "重阳节"
        case (12, 8): "腊八节"
        case (12, 23): "小年"
        default: nil
        }
    }

    private static func gregorianFestival(for date: Date, calendar: Calendar) -> String? {
        let components = calendar.dateComponents([.month, .day], from: date)
        return switch (components.month, components.day) {
        case (1, 1): "元旦"
        case (2, 14): "情人节"
        case (3, 8): "妇女节"
        case (5, 1): "劳动节"
        case (6, 1): "儿童节"
        case (9, 10): "教师节"
        case (10, 1): "国庆节"
        case (12, 24): "平安夜"
        case (12, 25): "圣诞节"
        default: nil
        }
    }

    private static func qingmingFestival(for date: Date, calendar: Calendar) -> String? {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year,
              components.month == 4,
              components.day == qingmingDay(for: year) else {
            return nil
        }
        return "清明"
    }

    private static func qingmingDay(for year: Int) -> Int {
        let yearInCentury = year % 100
        let centuryConstant = year >= 2000 ? 4.81 : 5.59
        return Int(Double(yearInCentury) * 0.2422 + centuryConstant) - Int(Double(yearInCentury - 1) / 4.0)
    }

    private static func lunarText(month: Int, day: Int, isLeapMonth: Bool) -> String {
        let monthText = lunarMonthText(month, isLeapMonth: isLeapMonth)
        return day == 1 ? "\(monthText)初一" : lunarDayText(day)
    }

    private static func lunarMonthText(_ month: Int, isLeapMonth: Bool) -> String {
        let names = [
            "正月",
            "二月",
            "三月",
            "四月",
            "五月",
            "六月",
            "七月",
            "八月",
            "九月",
            "十月",
            "冬月",
            "腊月"
        ]
        let value = names.indices.contains(month - 1) ? names[month - 1] : "\(month)月"
        return isLeapMonth ? "闰\(value)" : value
    }

    private static func lunarDayText(_ day: Int) -> String {
        let names = [
            "初一",
            "初二",
            "初三",
            "初四",
            "初五",
            "初六",
            "初七",
            "初八",
            "初九",
            "初十",
            "十一",
            "十二",
            "十三",
            "十四",
            "十五",
            "十六",
            "十七",
            "十八",
            "十九",
            "二十",
            "廿一",
            "廿二",
            "廿三",
            "廿四",
            "廿五",
            "廿六",
            "廿七",
            "廿八",
            "廿九",
            "三十"
        ]
        return names.indices.contains(day - 1) ? names[day - 1] : "\(day)"
    }
}

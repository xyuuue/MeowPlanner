# Chinese Calendar Festivals Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show Chinese lunar dates and common Chinese/public festivals in MeowPlanner calendar surfaces.

**Architecture:** Add a small core calendar service that derives lunar day labels and common festival names from Foundation's Chinese calendar plus fixed Gregorian dates. Store the derived info on `MonthPlannerDay` so the app month grid and widget month grid share the same data.

**Tech Stack:** Swift, Foundation `Calendar(identifier: .chinese)`, SwiftUI, Swift Testing.

---

### Task 1: Chinese Calendar Core

**Files:**
- Create: `Sources/MeowPlannerCore/Services/ChineseCalendarInfoProvider.swift`
- Test: `Tests/MeowPlannerCoreTests/ChineseCalendarInfoTests.swift`

- [ ] Write failing tests for lunar labels, Spring Festival, Dragon Boat Festival, Mid-Autumn Festival, Lunar New Year's Eve, and fixed Gregorian holidays.
- [ ] Implement `ChineseCalendarDayInfo` and `ChineseCalendarInfoProvider.info(for:calendar:)`.
- [ ] Run `swift test` and verify the new tests pass.

### Task 2: Month Grid Data

**Files:**
- Modify: `Sources/MeowPlannerCore/Support/MonthPlannerGridBuilder.swift`
- Test: `Tests/MeowPlannerCoreTests/MonthPlannerGridTests.swift`

- [ ] Add failing tests that each `MonthPlannerDay` includes Chinese calendar info.
- [ ] Add `chineseCalendarInfo` to `MonthPlannerDay` and populate it from the builder.
- [ ] Run `swift test`.

### Task 3: App And Widget Rendering

**Files:**
- Modify: `Sources/MeowPlannerApp/Views/Calendar/MonthGridView.swift`
- Modify: `Sources/MeowPlannerApp/Views/Calendar/DayAgendaView.swift`
- Modify: `Sources/MeowPlannerApp/Views/RootView.swift`
- Modify: `Sources/MeowPlannerWidget/MeowPlannerTodayWidget.swift`
- Test: `Tests/MeowPlannerCoreTests/XcodeWidgetProjectTests.swift`

- [ ] Add failing source checks for visible Chinese calendar labels in app and widget surfaces.
- [ ] Render festival names with stronger styling and normal lunar labels with subtle FuFu caramel styling.
- [ ] Run `swift test`, Xcode build, packaged app build, signature verification, and reinstall the app.

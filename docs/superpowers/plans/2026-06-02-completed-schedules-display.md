# Completed Schedules Display Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add settings to show or hide completed schedules and draw a strikethrough on completed schedule titles.

**Architecture:** Store the display preferences on `PlannerPreference`, expose them in `SettingsView`, and read them from the calendar and schedule timeline surfaces. Filtering happens before rendering; strikethrough stays a view concern.

**Tech Stack:** SwiftData models, SwiftUI views, Swift Testing source-structure tests.

---

### Task 1: Preference Defaults

**Files:**
- Modify: `Sources/MeowPlannerCore/Models/PlannerPreference.swift`
- Test: `Tests/MeowPlannerCoreTests/PlannerRulesTests.swift`

- [ ] Add failing default assertions for `showCompletedSchedules` and `completedSchedulesUseStrikethrough`.
- [ ] Add the two Boolean model fields with default `true`.
- [ ] Add init parameters and assign them.
- [ ] Run `swift test`.

### Task 2: Settings Surface

**Files:**
- Modify: `Sources/MeowPlannerCore/Support/AppLanguage.swift`
- Modify: `Sources/MeowPlannerApp/Views/Settings/SettingsView.swift`
- Test: `Tests/MeowPlannerCoreTests/XcodeWidgetProjectTests.swift`

- [ ] Add failing source checks for the settings toggles and localized keys.
- [ ] Add copy keys for "Show completed" and "Strikethrough completed schedules".
- [ ] Load and persist the two setting states in `SettingsView`.
- [ ] Run `swift test`.

### Task 3: Calendar And Schedule Rendering

**Files:**
- Modify: `Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift`
- Modify: `Sources/MeowPlannerApp/Views/Calendar/DayAgendaView.swift`
- Modify: `Sources/MeowPlannerApp/Views/Calendar/MonthGridView.swift`
- Modify: `Sources/MeowPlannerApp/Views/RootView.swift`
- Test: `Tests/MeowPlannerCoreTests/XcodeWidgetProjectTests.swift`

- [ ] Add failing source checks for completed schedule filtering and strikethrough.
- [ ] Filter completed schedules when `showCompletedSchedules` is off.
- [ ] Apply schedule strikethrough when `completedSchedulesUseStrikethrough` is on.
- [ ] Run `swift test`, Xcode build, packaged app build, signature verification, and reinstall the app.

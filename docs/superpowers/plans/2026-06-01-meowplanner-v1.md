# MeowPlanner v1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first usable MeowPlanner scaffold: a FuFu-themed SwiftUI planner for iPhone and Mac with schedules, todos, focus sessions, habits, iCloud-ready SwiftData models, local reminders, and a Today widget source.

**Architecture:** Keep domain behavior in `MeowPlannerCore`, SwiftUI app views in `MeowPlannerApp`, and widget code in `MeowPlannerWidget`. The repository is package-first so core tests can run immediately, while the app and widget source remain Xcode-ready for signing and App Store packaging.

**Tech Stack:** Swift 6.3, SwiftUI, SwiftData, WidgetKit, UserNotifications, XCTest, iOS 17+, macOS 14+.

---

### Task 1: Package, Core Tests, and Project Contract

**Files:**
- Create: `Package.swift`
- Create: `Tests/MeowPlannerCoreTests/PlannerRulesTests.swift`
- Create: `.gitignore`
- Create: `.codex/environments/environment.toml`
- Create: `script/build_and_run.sh`

- [ ] **Step 1: Write failing tests for repeat rules, reminders, habits, focus, completion, and SwiftData defaults**
- [ ] **Step 2: Run `swift test` and verify core symbols are missing**
- [ ] **Step 3: Add the package manifest and command scripts**
- [ ] **Step 4: Keep tests failing until core implementation is added**

### Task 2: Core Models and Services

**Files:**
- Create: `Sources/MeowPlannerCore/Models/PlannerEvent.swift`
- Create: `Sources/MeowPlannerCore/Models/TodoItem.swift`
- Create: `Sources/MeowPlannerCore/Models/Habit.swift`
- Create: `Sources/MeowPlannerCore/Models/HabitCheckIn.swift`
- Create: `Sources/MeowPlannerCore/Models/FocusSession.swift`
- Create: `Sources/MeowPlannerCore/Models/PlannerPreference.swift`
- Create: `Sources/MeowPlannerCore/Services/RepeatRule.swift`
- Create: `Sources/MeowPlannerCore/Services/HabitStreakCalculator.swift`
- Create: `Sources/MeowPlannerCore/Services/FocusTimerState.swift`
- Create: `Sources/MeowPlannerCore/Services/ReminderPlanner.swift`
- Create: `Sources/MeowPlannerCore/Stores/ModelContainerFactory.swift`

- [ ] **Step 1: Implement only the model and service behavior covered by tests**
- [ ] **Step 2: Run `swift test` and verify tests pass**
- [ ] **Step 3: Refactor names and boundaries without changing behavior**

### Task 3: SwiftUI App Surfaces

**Files:**
- Create: `Sources/MeowPlannerApp/App/MeowPlannerApp.swift`
- Create: `Sources/MeowPlannerApp/Views/RootView.swift`
- Create: `Sources/MeowPlannerApp/Views/Calendar/CalendarHomeView.swift`
- Create: `Sources/MeowPlannerApp/Views/Calendar/MonthGridView.swift`
- Create: `Sources/MeowPlannerApp/Views/Calendar/DayAgendaView.swift`
- Create: `Sources/MeowPlannerApp/Views/Focus/FocusView.swift`
- Create: `Sources/MeowPlannerApp/Views/Habits/HabitsView.swift`
- Create: `Sources/MeowPlannerApp/Views/Settings/SettingsView.swift`
- Create: `Sources/MeowPlannerApp/Views/Components/FuFuEmptyStateView.swift`
- Create: `Sources/MeowPlannerApp/Support/MeowPlannerTheme.swift`
- Create: `Sources/MeowPlannerApp/Support/AppNavigation.swift`

- [ ] **Step 1: Build iPhone tab navigation and Mac sidebar navigation**
- [ ] **Step 2: Add month calendar plus selected-day action list**
- [ ] **Step 3: Add focus, habits, and settings placeholder-complete flows backed by shared models**
- [ ] **Step 4: Run `swift build` for the app target on macOS**

### Task 4: Notifications, Widget, Assets, and Entitlements

**Files:**
- Create: `Sources/MeowPlannerCore/Services/NotificationScheduler.swift`
- Create: `Sources/MeowPlannerWidget/MeowPlannerTodayWidget.swift`
- Create: `Resources/FuFu/fufu-idle.png`
- Create: `Resources/FuFu/spritesheet.webp`
- Create: `Resources/FuFu/pet.json`
- Create: `Config/MeowPlanner.entitlements`
- Create: `Config/MeowPlannerWidget.entitlements`

- [ ] **Step 1: Add local notification scheduling wrapper**
- [ ] **Step 2: Add Today widget source with FuFu themed summary**
- [ ] **Step 3: Copy FuFu assets from SlackerBuddy**
- [ ] **Step 4: Run tests and build checks again**

### Task 5: Documentation and Verification

**Files:**
- Create: `README.md`

- [ ] **Step 1: Document app scope, build commands, and v1 exclusions**
- [ ] **Step 2: Run `swift test`**
- [ ] **Step 3: Run `swift build --product MeowPlanner`**
- [ ] **Step 4: Run `git status --short` and report changed files**

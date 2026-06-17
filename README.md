# MeowPlanner

MeowPlanner is a FuFu-themed planner scaffold for iPhone and Mac. It is inspired by TimePlanner's core planning surface, but v1 is intentionally narrower: schedules, todos, focus sessions, habits, iCloud-ready SwiftData models, local reminders, and a Today widget source.

## Product Identity

- Formal name: `MeowPlanner`
- Chinese subtitle: `FuFu 的喵系时间规划器`
- English subtitle: `A FuFu app for schedules, focus, and habits`
- Bundle default: `com.yuelingqiu.MeowPlanner`
- CloudKit container: `iCloud.com.yuelingqiu.MeowPlanner`
- App icon source: `Resources/AppIcon/AppIcon.png`

## Build

Run core tests:

```bash
swift test
```

Build the macOS SwiftUI executable target:

```bash
swift build --product MeowPlanner
```

Build and launch the macOS `.app` bundle. When `MeowPlanner.xcodeproj` is present, this path uses Xcode so the generated app includes the WidgetKit extension:

```bash
./script/build_and_run.sh
```

The generated app bundle is written to:

```text
dist/MeowPlanner.app
```

Verify the app bundle launches:

```bash
./script/build_and_run.sh --verify
```

Firebase email authentication requires `Config/GoogleService-Info.plist` and the Email/Password sign-in provider enabled in the Firebase console. For a developer-signed build with Firebase Auth keychain persistence, pass your Team ID:

```bash
DEVELOPMENT_TEAM=YOURTEAMID ./script/build_and_run.sh --signed --verify
```

## WidgetKit Widgets

The native Xcode project includes shared WidgetKit source for macOS and iPhone:

- `MeowPlanner` app target
- `MeowPlannerCore` shared framework target
- `MeowPlannerWidgetExtension` WidgetKit extension target
- `MeowPlanner-iOS` iPhone app target
- `MeowPlannerWidgetExtension-iOS` iPhone WidgetKit extension target

CLI builds use ad-hoc signing so the macOS app can launch locally from `dist/MeowPlanner.app`. To make the widget appear reliably in macOS's Add Widget gallery, open `MeowPlanner.xcodeproj` in Xcode, select your Development Team for both the app and widget targets, then run the `MeowPlanner` scheme once from Xcode.

For iPhone widgets, open `MeowPlanner.xcodeproj`, select a Development Team for `MeowPlanner-iOS`, `MeowPlannerCore-iOS`, and `MeowPlannerWidgetExtension-iOS`, then build the `MeowPlanner-iOS` scheme for an iPhone simulator or device.

## Scope

Included in v1:

- Month calendar plus selected-day schedules and todos
- Event and todo creation, completion, and deletion
- Focus timer and local focus session history
- Habit creation and daily check-ins with streak display
- SwiftData models with CloudKit-ready private database configuration
- Account settings with Firebase-backed email account registration and login
- Local notification scheduling wrapper
- WidgetKit Today widget extension source with macOS and iPhone app embedding
- FuFu visual theme using SlackerBuddy/PastePaw assets

Out of scope for v1:

- System Calendar, Google Calendar, or Outlook sync
- Cloud data sync, phone login, and WeChat login
- Diary, countdown days, analytics dashboards, and AI schedule parsing
- A full widget suite or active FuFu pet coach behavior

## Notes

This repository still keeps SwiftPM support for fast model tests, but the macOS app bundle and widget extension are now driven by `MeowPlanner.xcodeproj`.

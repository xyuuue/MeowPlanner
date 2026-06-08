# MeowPlanner Website Design

## Goal

Design a single-page MeowPlanner website that fits the existing FuFu app family while giving MeowPlanner its own planner and calendar identity. The site should look related to PastePaw and SlackerBuddy, but not copy either page exactly.

The current approved delivery is design-only. Implementation can begin after this spec is reviewed and approved. Deployment to Vercel must wait for explicit user approval after local implementation and verification.

## Reference Sites

- PastePaw: `https://pastepaw.vercel.app/`
- SlackerBuddy: `https://slackerbuddy.vercel.app/`

Observed family patterns to preserve:

- Simple static landing page structure.
- FuFu is visible in the hero or supporting cards.
- Bilingual English and Chinese language switch.
- Product-specific headline and direct CTA.
- Feature section after the hero.
- Download or install flow section.
- Local or privacy note where relevant.
- "Want more FuFu apps?" cross-link section.
- Portfolio link.

## Approved Direction

Use option C, `Hybrid Planner`, with extra FuFu and calendar density.

The page should combine:

- PastePaw's warm cream, coffee, caramel, rounded navigation, download flow, and local-first tone.
- SlackerBuddy's airy first viewport, softer pink and blue accents, and stronger FuFu personality.
- MeowPlanner-specific calendar/product visuals: month grid, date chips, selected day, class week marker, to-do rail, focus card, habit/streak cues, and Today widget mention.

The site should feel like a FuFu family member whose job is planning time.

## Product Positioning

Formal product name:

- `MeowPlanner`

Primary English positioning:

- `A FuFu calendar planner for classes, focus, and tiny habits`

Alternative longer line for hero or metadata:

- `FuFu's planner for schedules, classes, focus, and habits`

Chinese positioning:

- `FuFu 的喵系时间规划器`

Short product explanation:

- English: `MeowPlanner turns the month grid into a soft command center: schedules, to-dos, timetable weeks, focus blocks, and habit streaks all stay visible with FuFu nearby.`
- Chinese: `MeowPlanner 把月历变成一个温柔的 FuFu 规划中心：日程、待办、课程周、专注块和习惯打卡都可以放在同一个时间视图里。`

## Download State

Use the mixed download direction.

Current state:

- The page should show `Download coming soon`.
- DMG and SHA-256 actions should be visually present but disabled.
- The download section should explain that the DMG will open after packaging is ready.
- Do not link to a fake or missing DMG.

Future-ready state:

- Reserve the future paths `downloads/MeowPlanner.dmg` and `downloads/MeowPlanner.dmg.sha256`.
- The same section should be easy to activate after packaging.

Download section headline:

- English: `DMG coming soon on FuFu's release calendar`
- Chinese: `FuFu 的发布日历即将开放 DMG 下载`

Install flow steps:

1. Download day: save `MeowPlanner.dmg` when the release opens.
2. Install: open the DMG and drag MeowPlanner into Applications.
3. Open once: Control-click MeowPlanner and choose Open if macOS asks.
4. Plan with FuFu: open the calendar, pick today, and let FuFu sit beside the plan.

## Page Structure

### 1. Header

Header should be a sticky, rounded, translucent navigation bar like PastePaw, with a lighter hybrid palette.

Content:

- Brand mark with MeowPlanner icon or a small calendar/paw mark.
- Brand text: `MeowPlanner`.
- Navigation items: `Features`, `Calendar`, `Download`, `More FuFu Apps`, `Privacy`.
- Language switch: `EN / 中文`.
- CTA button: `Coming soon`.

The CTA must not trigger a missing download while DMG packaging is not ready.

### 2. Hero

Hero should be the strongest product signal on the page.

Layout:

- Left side: headline, product explanation, primary disabled coming-soon CTA, secondary feature/calendar CTA.
- Right side: rich MeowPlanner product mockup.
- Supporting FuFu speech card near the mockup.

Hero visual requirements:

- Use warm cream background with soft pink and blue accents.
- Include paw texture or subtle paw marks, but not noisy decoration.
- Include a calendar mockup with weekday row, date cells, selected date, colored schedule blocks, and a `W16` or class-week marker.
- Include FuFu as a visible companion near the calendar.
- Include at least one FuFu message, for example: `FuFu says: Tuesday has room for one tiny focus block.`

Approved hero copy:

- English H1: `A FuFu calendar planner for classes, focus, and tiny habits`
- English body: `MeowPlanner turns the month grid into a soft command center: schedules, to-dos, timetable weeks, focus blocks, and habit streaks all stay visible with FuFu nearby.`
- Primary CTA: `Download coming soon`
- Secondary CTA: `Explore calendar`

Chinese copy:

- H1: `FuFu 的喵系日历规划器`
- Body: `MeowPlanner 把月历变成一个温柔的 FuFu 规划中心：日程、待办、课程周、专注块和习惯打卡都可以放在同一个时间视图里。`
- Primary CTA: `下载即将开放`
- Secondary CTA: `查看日历功能`

### 3. Feature Section

Feature section should include more FuFu and calendar elements than a normal card grid. Cards may use small labels like `paw`, `cal`, `W16`, and `FuFu`, plus date chips and mini calendar motifs.

Feature items:

- Calendar + agenda: month grid, selected-day schedules, Chinese calendar details, completed schedule display, and FuFu daily note.
- To-dos by group: daily tasks and grouped to-do lists beside the calendar.
- Course timetable: weekly class grid with semester weeks, course colors, teachers, rooms, and holiday-aware display.
- Focus + habits: FuFu-themed focus blocks, recent focus history, habit check-ins, and streak tracking.
- Today widget source: WidgetKit Today widget source for quick schedule summaries.
- Local-first planning: SwiftData models are CloudKit-ready, but v1 should stay focused on the user's own Mac planner workflow.

Suggested section headline:

- English: `More calendar, more FuFu`
- Chinese: `更多日历感，也更多 FuFu`

### 4. Workflow Strip

Keep the 4-step workflow, but make it visually calendar-based:

1. Pick today.
2. See classes.
3. Focus once.
4. Check habits.

Each step should be shown as a compact rounded panel with different soft backgrounds. Include a small calendar or paw marker in each panel if implementation space allows.

### 5. Download Section

Use a dark coffee panel for contrast, similar in seriousness to install sections on the reference sites, but with a calendar release-card concept.

Required state:

- Disabled DMG button.
- Disabled SHA-256 button.
- Small release calendar card for `MeowPlanner.dmg`.
- Install flow remains visible.

Do not imply the app is downloadable until packaging is complete.

### 6. Privacy / Local-First Section

Headline:

- English: `Your calendar stays on your Mac`
- Chinese: `你的日历留在自己的 Mac 上`

Message:

- MeowPlanner is designed around local schedules, to-dos, focus history, habits, and timetable data.
- SwiftData models are CloudKit-ready.
- The public page must not promise account sync, Google Calendar sync, Outlook sync, or system Calendar sync in v1.

### 7. More FuFu Apps

Keep the cross-app family section.

Cards:

- PastePaw: `FuFu clipboard helper for macOS`, link to `https://pastepaw.vercel.app/`
- SlackerBuddy: `FuFu desktop pet for mindful breaks`, link to `https://slackerbuddy.vercel.app/`
- Portfolio: `The project home behind the FuFu series`, link to `https://xyuuue.github.io/yueling-qiu/`

This section should make MeowPlanner feel like the planning member of the FuFu family.

### 8. Footer

Footer should be simple and warm.

Footer line:

- English: `MeowPlanner · FuFu's calendar planner for schedules, classes, focus, and habits`
- Chinese: `MeowPlanner · FuFu 的喵系时间规划器`

Include small links to Features, Download, PastePaw, SlackerBuddy, and Portfolio.

## Visual System

Palette:

- Cream page background: `#fff6e8`, `#fffaf0`, `#fffafc`
- Coffee text: `#2d1e18`
- Muted brown: `#765c4e`
- Caramel accent: `#b87942`
- Soft calendar blue: `#d9e8ee`
- Soft blush: `#f7c4ba`
- Soft lavender: `#d8c9e8`
- Soft green: `#dce8d8`

Typography:

- Use Apple system rounded where possible: `ui-rounded`, `SF Pro Rounded`, `Nunito`, `PingFang SC`, system fallbacks.
- Hero H1 should be large and friendly, but not oversized enough to crowd the calendar mockup.
- Body text should stay readable and not rely on tiny decorative labels.

Components:

- Rounded sticky nav, around 20 to 22 px radius.
- Pill CTAs.
- Calendar cards with 12 to 18 px radius.
- Feature cards with 14 to 18 px radius.
- Dark download panel with disabled buttons.
- Cross-app cards that use actual app icons when available.

FuFu and calendar details:

- Use the real MeowPlanner app icon from `Resources/AppIcon/AppIcon.png`.
- Use the real FuFu idle image from `Resources/FuFu/fufu-idle.png`.
- Add paw markers, date chips, selected-day ring, weekday labels, and class week labels.
- Keep FuFu and paw elements tasteful, not cluttered.

## Implementation Boundaries

Do:

- Build a static website in the MeowPlanner repo.
- Reuse existing MeowPlanner icon and FuFu assets.
- Include bilingual content and language switching.
- Keep download buttons disabled until a real DMG exists.
- Verify locally in a browser before asking for deployment approval.

Do not:

- Deploy to Vercel without explicit user approval.
- Promise current DMG availability.
- Promise account sync or third-party calendar sync.
- Replace the site with a generic marketing page.
- Copy PastePaw or SlackerBuddy exactly.

## Acceptance Criteria

- The page visibly matches the FuFu app family while clearly reading as MeowPlanner.
- First viewport includes a strong calendar/planner preview, not only a mascot or app icon.
- FuFu is present in the hero and at least one supporting section.
- Calendar elements appear in the hero, feature section, workflow, and download/release state.
- Download state is honest: coming soon, disabled buttons, install flow reserved.
- English and Chinese copy both exist.
- More FuFu apps section links PastePaw, SlackerBuddy, and the portfolio.
- Vercel deployment is not performed until the user approves it after local implementation review.

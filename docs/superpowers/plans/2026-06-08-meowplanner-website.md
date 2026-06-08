# MeowPlanner Website Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Vercel-ready static MeowPlanner website that matches the approved FuFu family design spec, keeps download CTAs disabled until a real DMG exists, and verifies correctly in a local browser.

**Architecture:** Create a small static site under `website/` with focused `index.html`, `styles.css`, and `script.js` files. Reuse existing app assets by copying MeowPlanner and FuFu images into `website/assets/`; add root `vercel.json` rewrites so the site can later deploy from the repository root without moving the app source. No Vercel deployment happens in this plan.

**Tech Stack:** Static HTML, CSS, vanilla JavaScript, existing PNG/WebP assets, local `python3 -m http.server` for verification, Browser/IAB for visual QA.

---

## File Structure

- Create: `website/index.html`
  - Owns the full single-page semantic document, section order, bilingual text keys, disabled coming-soon download state, and links to PastePaw, SlackerBuddy, and the portfolio.
- Create: `website/styles.css`
  - Owns the approved palette, responsive layout, calendar mockup, FuFu/card styling, disabled CTA treatment, and mobile behavior.
- Create: `website/script.js`
  - Owns English/Chinese translation switching, persisted language preference, `html[lang]`, translated attributes, and guarded disabled download buttons.
- Create: `website/assets/meowplanner-icon.png`
  - Copied from `Resources/AppIcon/AppIcon.png`.
- Create: `website/assets/fufu-idle.png`
  - Copied from `Resources/FuFu/fufu-idle.png`.
- Create: `website/downloads/.gitkeep`
  - Preserves the future DMG directory without adding fake downloads.
- Create: `vercel.json`
  - Routes `/`, `/assets/:path*`, and `/downloads/:path*` into the static `website/` directory for future Vercel deployment.
- Create: `.vercelignore`
  - Prevents future Vercel uploads from including Swift build products, local app bundles, preview scratch files, and caches.
- Modify: `.gitignore`
  - Add `.superpowers/` and `.vercel/` so local brainstorming previews and Vercel metadata stay out of commits.

## Task 1: Static Site Directories and Assets

**Files:**
- Create: `website/assets/meowplanner-icon.png`
- Create: `website/assets/fufu-idle.png`
- Create: `website/downloads/.gitkeep`
- Modify: `.gitignore`

- [ ] **Step 1: Verify the source assets exist**

Run:

```bash
test -f Resources/AppIcon/AppIcon.png
test -f Resources/FuFu/fufu-idle.png
```

Expected: both commands exit with status `0`.

- [ ] **Step 2: Create the static site directories**

Run:

```bash
mkdir -p website/assets website/downloads
```

Expected: `website/assets` and `website/downloads` exist.

- [ ] **Step 3: Copy the MeowPlanner and FuFu assets**

Run:

```bash
cp Resources/AppIcon/AppIcon.png website/assets/meowplanner-icon.png
cp Resources/FuFu/fufu-idle.png website/assets/fufu-idle.png
```

Expected: copied files exist under `website/assets/`.

- [ ] **Step 4: Preserve the future downloads directory without fake DMG files**

Create `website/downloads/.gitkeep` as an empty file.

Run:

```bash
touch website/downloads/.gitkeep
find website/downloads -maxdepth 1 -type f -print
```

Expected output includes only `website/downloads/.gitkeep`; no `MeowPlanner.dmg` or SHA file exists yet.

- [ ] **Step 5: Add local preview metadata to `.gitignore`**

Modify `.gitignore` so it includes these lines:

```gitignore
.vercel/
.superpowers/
```

Do not add `website/downloads/*.dmg` or `website/downloads/*.sha256` to `.gitignore`; those files should be trackable when the real release is ready.

- [ ] **Step 6: Verify asset state**

Run:

```bash
test -s website/assets/meowplanner-icon.png
test -s website/assets/fufu-idle.png
test -f website/downloads/.gitkeep
rg -n "^\\.superpowers/|^\\.vercel/" .gitignore
```

Expected: both images are non-empty, `.gitkeep` exists, and `.gitignore` contains `.superpowers/` plus `.vercel/`.

- [ ] **Step 7: Commit asset scaffolding**

Run:

```bash
git add .gitignore website/assets/meowplanner-icon.png website/assets/fufu-idle.png website/downloads/.gitkeep
git commit -m "Add MeowPlanner website assets"
```

Expected: commit succeeds and includes only the listed files.

## Task 2: Vercel-Ready Static Routing

**Files:**
- Create: `vercel.json`
- Create: `.vercelignore`

- [ ] **Step 1: Write `vercel.json`**

Create `vercel.json` with exactly this content:

```json
{
  "rewrites": [
    { "source": "/", "destination": "/website/index.html" },
    { "source": "/assets/:path*", "destination": "/website/assets/:path*" },
    { "source": "/downloads/:path*", "destination": "/website/downloads/:path*" }
  ]
}
```

- [ ] **Step 2: Write `.vercelignore`**

Create `.vercelignore` with exactly this content:

```gitignore
.DS_Store
.build/
.codex/
.git/
.superpowers/
.swiftpm/
.vercel/
DerivedData/
build/
dist/
meowplanner_asset_pack_no_blue/
*.xcuserstate
xcuserdata/
```

- [ ] **Step 3: Validate JSON syntax and expected rewrites**

Run:

```bash
python3 - <<'PY'
import json
from pathlib import Path
data = json.loads(Path("vercel.json").read_text())
rewrites = data.get("rewrites", [])
expected = {
    ("/", "/website/index.html"),
    ("/assets/:path*", "/website/assets/:path*"),
    ("/downloads/:path*", "/website/downloads/:path*"),
}
actual = {(item["source"], item["destination"]) for item in rewrites}
assert actual == expected, actual
print("vercel rewrites ok")
PY
```

Expected output:

```text
vercel rewrites ok
```

- [ ] **Step 4: Commit routing setup**

Run:

```bash
git add vercel.json .vercelignore
git commit -m "Add MeowPlanner website routing"
```

Expected: commit succeeds and no deployment command is run.

## Task 3: HTML Content and Page Structure

**Files:**
- Create: `website/index.html`

- [ ] **Step 1: Verify the page does not exist yet**

Run:

```bash
test ! -f website/index.html
```

Expected: command exits with status `0` before this task creates the file.

- [ ] **Step 2: Create `website/index.html`**

Create `website/index.html` with this structure and exact section ids. The page text must be bilingual through `data-i18n` keys, and download buttons must be disabled using `aria-disabled="true"` plus `data-disabled-download`.

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title data-i18n="metaTitle">MeowPlanner - FuFu's Calendar Planner</title>
    <meta
      name="description"
      content="MeowPlanner is a FuFu calendar planner for classes, focus, habits, schedules, and to-dos."
      data-i18n-content="metaDescription"
    />
    <link rel="icon" type="image/png" href="/assets/meowplanner-icon.png" />
    <link rel="apple-touch-icon" href="/assets/meowplanner-icon.png" />
    <link rel="stylesheet" href="./styles.css" />
  </head>
  <body>
    <header class="site-header">
      <a class="brand" href="#top" aria-label="MeowPlanner home" data-i18n-aria="brandAria">
        <img src="./assets/meowplanner-icon.png" alt="" />
        <span>MeowPlanner</span>
      </a>
      <nav aria-label="Primary navigation" data-i18n-aria="navAria">
        <a href="#features" data-i18n="navFeatures">Features</a>
        <a href="#calendar" data-i18n="navCalendar">Calendar</a>
        <a href="#download" data-i18n="navDownload">Download</a>
        <a href="#more-apps" data-i18n="navMoreApps">More FuFu Apps</a>
        <a href="#privacy" data-i18n="navPrivacy">Privacy</a>
      </nav>
      <div class="header-actions">
        <div class="language-switcher" aria-label="Language">
          <button type="button" data-language-option="en" aria-pressed="true">EN</button>
          <button type="button" data-language-option="zh" aria-pressed="false">中文</button>
        </div>
        <a class="nav-cta is-disabled" href="#download" aria-disabled="true" data-disabled-download data-i18n="navCta">Coming soon</a>
      </div>
    </header>

    <main id="top">
      <section class="hero" aria-labelledby="hero-title">
        <div class="hero-copy">
          <p class="soft-label">
            <span class="mini-paw">•</span>
            <span data-i18n="softLabel">FuFu keeps the calendar cozy</span>
          </p>
          <h1 id="hero-title" data-i18n="heroTitle">A FuFu calendar planner for classes, focus, and tiny habits</h1>
          <p class="hero-text" data-i18n="heroText">
            MeowPlanner turns the month grid into a soft command center: schedules, to-dos, timetable weeks, focus blocks, and habit streaks all stay visible with FuFu nearby.
          </p>
          <div class="hero-actions">
            <a class="primary-button is-disabled" href="#download" aria-disabled="true" data-disabled-download data-i18n="primaryCta">Download coming soon</a>
            <a class="secondary-button" href="#calendar" data-i18n="secondaryCta">Explore calendar</a>
          </div>
          <p class="availability-note" data-i18n="availabilityNote">The final download flow will be enabled after the DMG is ready.</p>
        </div>

        <div class="hero-product" id="calendar" aria-label="MeowPlanner calendar preview" data-i18n-aria="calendarPreviewAria">
          <div class="calendar-preview">
            <div class="calendar-preview-header">
              <div>
                <strong data-i18n="calendarMonth">June 2026</strong>
                <span data-i18n="calendarWeek">Week 23 - FuFu plan view</span>
              </div>
              <div class="calendar-status">
                <span data-i18n="calendarStatus">3 schedules</span>
                <img src="./assets/fufu-idle.png" alt="FuFu" />
              </div>
            </div>
            <div class="weekday-row" aria-hidden="true">
              <span>Sun</span><span>Mon</span><span>Tue</span><span>Wed</span><span>Thu</span><span>Fri</span><span>Sat</span>
            </div>
            <div class="month-grid" aria-hidden="true">
              <span class="outside">31</span><span>1</span><span class="selected">2<small>paw</small></span><span>3</span><span class="busy blush">4</span><span>5</span><span>6</span>
              <span>7</span><span class="busy lavender">8</span><span>9</span><span>10</span><span class="busy gold">11</span><span>12</span><span>13</span>
              <span>14</span><span>15</span><span class="busy peach">16</span><span>17</span><span>18</span><span class="busy green">19</span><span>20</span>
            </div>
            <div class="calendar-cards">
              <article>
                <strong data-i18n="focusCardTitle">FuFu focus</strong>
                <span data-i18n="focusCardText">25 min block at 2:00 PM</span>
              </article>
              <article>
                <strong data-i18n="classCardTitle">Class week</strong>
                <span data-i18n="classCardText">W16 timetable visible</span>
              </article>
            </div>
          </div>
          <div class="fufu-bubble">
            <img src="./assets/fufu-idle.png" alt="" />
            <p><strong data-i18n="fufuBubbleTitle">FuFu says:</strong> <span data-i18n="fufuBubbleText">Tuesday has room for one tiny focus block.</span></p>
          </div>
        </div>
      </section>

      <section id="features" class="section features-section" aria-labelledby="features-title">
        <div class="section-heading">
          <p class="soft-label" data-i18n="featuresLabel">More calendar, more FuFu</p>
          <h2 id="features-title" data-i18n="featuresTitle">Plan the day without leaving FuFu's world</h2>
          <p data-i18n="featuresText">MeowPlanner combines the planning surfaces already in the app: calendar, agenda, to-dos, timetable, focus, habits, and a Today widget source.</p>
        </div>
        <div class="feature-grid">
          <article><span>cal</span><h3 data-i18n="featureCalendarTitle">Calendar + agenda</h3><p data-i18n="featureCalendarText">Month grid with date colors, selected-day schedules, Chinese calendar details, completed schedule display, and FuFu's daily note.</p></article>
          <article><span>paw</span><h3 data-i18n="featureTodoTitle">To-dos by group</h3><p data-i18n="featureTodoText">Daily tasks and grouped to-do lists beside the calendar, so planning feels like a daily page.</p></article>
          <article><span>W16</span><h3 data-i18n="featureTimetableTitle">Course timetable</h3><p data-i18n="featureTimetableText">Weekly class grid with semester weeks, course colors, teachers, rooms, and holiday-aware display.</p></article>
          <article><span>cat</span><h3 data-i18n="featureFocusTitle">Focus + habits</h3><p data-i18n="featureFocusText">FuFu focus blocks, recent focus history, habit check-ins, streaks, and tiny encouragement.</p></article>
          <article><span>wid</span><h3 data-i18n="featureWidgetTitle">Today widget source</h3><p data-i18n="featureWidgetText">WidgetKit Today widget source for quick schedule summaries.</p></article>
          <article><span>Mac</span><h3 data-i18n="featureLocalTitle">Local-first planning</h3><p data-i18n="featureLocalText">SwiftData models are CloudKit-ready, while v1 stays focused on your own Mac planner workflow.</p></article>
        </div>
      </section>

      <section class="section workflow-section" aria-labelledby="workflow-title">
        <div class="section-heading compact">
          <h2 id="workflow-title" data-i18n="workflowTitle">A day in four small moves</h2>
        </div>
        <div class="workflow-grid">
          <article><span>1</span><h3 data-i18n="workflowOneTitle">Pick today</h3><p data-i18n="workflowOneText">Start from the month grid and selected-day agenda.</p></article>
          <article><span>2</span><h3 data-i18n="workflowTwoTitle">See classes</h3><p data-i18n="workflowTwoText">Use the timetable to keep course weeks visible.</p></article>
          <article><span>3</span><h3 data-i18n="workflowThreeTitle">Focus once</h3><p data-i18n="workflowThreeText">Run one calm FuFu focus block.</p></article>
          <article><span>4</span><h3 data-i18n="workflowFourTitle">Check habits</h3><p data-i18n="workflowFourText">Close the day with tiny streaks.</p></article>
        </div>
      </section>

      <section id="download" class="section download-section" aria-labelledby="download-title">
        <div class="download-panel">
          <div class="download-copy">
            <p class="soft-label" data-i18n="downloadLabel">下载流程 / Download flow</p>
            <h2 id="download-title" data-i18n="downloadTitle">DMG coming soon on FuFu's release calendar</h2>
            <p data-i18n="downloadText">A small release-calendar card keeps the disabled download state honest until packaging is complete.</p>
            <div class="release-card">
              <span>soon</span>
              <div><strong>MeowPlanner.dmg</strong><p data-i18n="releaseCardText">FuFu will unlock this button after packaging.</p></div>
            </div>
            <div class="download-actions">
              <a class="primary-button is-disabled" href="#download" aria-disabled="true" data-disabled-download data-i18n="downloadButton">DMG coming soon</a>
              <a class="secondary-button dark is-disabled" href="#download" aria-disabled="true" data-disabled-download data-i18n="checksumButton">SHA-256 pending</a>
            </div>
          </div>
          <ol class="download-steps" aria-label="Download flow" data-i18n-aria="downloadStepsAria">
            <li><span>1</span><div><strong data-i18n="stepOneTitle">Download day</strong><p data-i18n="stepOneText">Save MeowPlanner.dmg when the release opens.</p></div></li>
            <li><span>2</span><div><strong data-i18n="stepTwoTitle">Install</strong><p data-i18n="stepTwoText">Open the DMG and drag MeowPlanner into Applications.</p></div></li>
            <li><span>3</span><div><strong data-i18n="stepThreeTitle">Open once</strong><p data-i18n="stepThreeText">Control-click MeowPlanner and choose Open if macOS asks.</p></div></li>
            <li><span>4</span><div><strong data-i18n="stepFourTitle">Plan with FuFu</strong><p data-i18n="stepFourText">Open the calendar, pick today, and let FuFu sit beside the plan.</p></div></li>
          </ol>
        </div>
      </section>

      <section id="privacy" class="section privacy-section" aria-labelledby="privacy-title">
        <div class="section-heading">
          <p class="soft-label" data-i18n="privacyLabel">Local-first planning</p>
          <h2 id="privacy-title" data-i18n="privacyTitle">Your calendar stays on your Mac</h2>
          <p data-i18n="privacyText">MeowPlanner is designed around local schedules, to-dos, focus history, habits, and timetable data. SwiftData models are CloudKit-ready, but v1 does not promise account sync or third-party calendar sync.</p>
        </div>
      </section>

      <section id="more-apps" class="section more-apps-section" aria-labelledby="more-apps-title">
        <div class="section-heading">
          <p class="soft-label" data-i18n="moreAppsLabel">Want more FuFu apps?</p>
          <h2 id="more-apps-title" data-i18n="moreAppsTitle">FuFu can help in more tiny Mac tools</h2>
        </div>
        <div class="app-links">
          <a href="https://pastepaw.vercel.app/" target="_blank" rel="noreferrer"><span>clip</span><strong>PastePaw</strong><small data-i18n="pastepawText">FuFu clipboard helper for macOS.</small></a>
          <a href="https://slackerbuddy.vercel.app/" target="_blank" rel="noreferrer"><span>cat</span><strong>SlackerBuddy</strong><small data-i18n="slackerText">FuFu desktop pet for mindful breaks.</small></a>
          <a href="https://xyuuue.github.io/yueling-qiu/" target="_blank" rel="noreferrer"><span>YQ</span><strong data-i18n="portfolioTitle">Portfolio</strong><small data-i18n="portfolioText">The project home behind the FuFu series.</small></a>
        </div>
      </section>
    </main>

    <footer>
      <img src="./assets/meowplanner-icon.png" alt="" />
      <span data-i18n="footerText">MeowPlanner · FuFu's calendar planner for schedules, classes, focus, and habits</span>
    </footer>

    <script src="./script.js"></script>
  </body>
</html>
```

- [ ] **Step 3: Validate required section ids and disabled download state**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
html = Path("website/index.html").read_text()
for marker in ['id="features"', 'id="calendar"', 'id="download"', 'id="privacy"', 'id="more-apps"']:
    assert marker in html, marker
assert 'data-disabled-download' in html
assert 'downloads/MeowPlanner.dmg' not in html
assert 'downloads/MeowPlanner.dmg.sha256' not in html
assert 'https://pastepaw.vercel.app/' in html
assert 'https://slackerbuddy.vercel.app/' in html
assert 'https://xyuuue.github.io/yueling-qiu/' in html
print("html structure ok")
PY
```

Expected output:

```text
html structure ok
```

- [ ] **Step 4: Commit HTML structure**

Run:

```bash
git add website/index.html
git commit -m "Add MeowPlanner website content"
```

Expected: commit succeeds.

## Task 4: Visual CSS and Responsive Layout

**Files:**
- Create: `website/styles.css`

- [ ] **Step 1: Verify stylesheet is referenced but missing**

Run:

```bash
rg -n 'href="./styles.css"' website/index.html
test ! -f website/styles.css
```

Expected: first command finds the stylesheet reference, second command exits `0`.

- [ ] **Step 2: Create `website/styles.css`**

Create CSS that implements these concrete rules:

```css
:root {
  color-scheme: light;
  --cream: #fff6e8;
  --paper: #fffaf0;
  --white: #fffafc;
  --coffee: #2d1e18;
  --muted: #765c4e;
  --caramel: #b87942;
  --line: rgba(77, 45, 25, 0.14);
  --blue: #d9e8ee;
  --blush: #f7c4ba;
  --lavender: #d8c9e8;
  --green: #dce8d8;
  --gold: #f1d3a5;
  --peach: #f6ddd0;
  --shadow: 0 22px 70px rgba(70, 39, 18, 0.14);
}

* { box-sizing: border-box; }
html { scroll-behavior: smooth; }
body {
  margin: 0;
  font-family: ui-rounded, "SF Pro Rounded", "Nunito", "PingFang SC", system-ui, sans-serif;
  color: var(--coffee);
  background:
    radial-gradient(circle at 84% 12%, rgba(73, 174, 232, 0.16), transparent 28%),
    radial-gradient(circle at 12% 78%, rgba(255, 143, 161, 0.13), transparent 24%),
    linear-gradient(135deg, var(--cream) 0%, var(--white) 48%, #f4f8ff 100%);
}
a { color: inherit; text-decoration: none; }
img { max-width: 100%; display: block; }

.site-header {
  position: sticky;
  top: 0;
  z-index: 10;
  width: min(1160px, calc(100% - 32px));
  margin: 18px auto 0;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
  padding: 10px 12px;
  border: 1px solid var(--line);
  border-radius: 22px;
  background: rgba(255, 255, 255, 0.76);
  box-shadow: 0 14px 34px rgba(68, 52, 72, 0.10);
  backdrop-filter: blur(18px);
}
.brand, .header-actions, nav, .hero-actions, .download-actions { display: flex; align-items: center; }
.brand { gap: 10px; font-size: 20px; font-weight: 950; }
.brand img { width: 36px; height: 36px; border-radius: 12px; }
nav { gap: 18px; color: var(--muted); font-size: 14px; font-weight: 850; }
.header-actions { gap: 10px; }
.language-switcher {
  display: inline-flex;
  gap: 4px;
  padding: 4px;
  border: 1px solid var(--line);
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.8);
}
.language-switcher button {
  min-width: 56px;
  min-height: 34px;
  border: 0;
  border-radius: 999px;
  background: transparent;
  color: var(--muted);
  font: inherit;
  font-size: 14px;
  font-weight: 950;
  cursor: pointer;
}
.language-switcher button[aria-pressed="true"] { color: #fff; background: var(--coffee); }

main { width: min(1160px, calc(100% - 32px)); margin: 0 auto; }
.hero {
  min-height: calc(100vh - 92px);
  display: grid;
  grid-template-columns: 0.92fr 1.08fr;
  align-items: center;
  gap: clamp(28px, 5vw, 56px);
  padding: 58px 0 76px;
}
.soft-label { margin: 0 0 14px; color: var(--caramel); font-size: 17px; font-weight: 950; }
.mini-paw {
  display: inline-grid;
  place-items: center;
  width: 28px;
  height: 28px;
  margin-right: 8px;
  border: 1px solid var(--line);
  border-radius: 50%;
  background: #fff;
  color: var(--caramel);
}
h1, h2, h3, p { margin-top: 0; }
h1 {
  margin-bottom: 18px;
  font-size: clamp(48px, 6.4vw, 78px);
  line-height: 0.96;
  letter-spacing: 0;
}
.hero-text { max-width: 660px; color: var(--muted); font-size: 20px; line-height: 1.6; font-weight: 650; }
.hero-actions, .download-actions { gap: 12px; flex-wrap: wrap; margin-top: 26px; }
.primary-button, .secondary-button, .nav-cta {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-height: 48px;
  border-radius: 999px;
  padding: 0 20px;
  font-weight: 950;
}
.primary-button, .nav-cta { color: #fffaf0; background: var(--coffee); box-shadow: 0 14px 30px rgba(45, 30, 24, 0.20); }
.secondary-button { border: 1px solid var(--line); background: rgba(255, 255, 255, 0.72); }
.is-disabled { cursor: not-allowed; opacity: 0.76; }
.availability-note { margin-top: 16px; color: #8c6b58; font-size: 14px; }

.hero-product { position: relative; padding-bottom: 34px; }
.calendar-preview {
  border: 1px solid rgba(77, 45, 25, 0.18);
  border-radius: 30px;
  background: rgba(255, 250, 240, 0.82);
  box-shadow: var(--shadow);
  padding: 18px;
}
.calendar-preview-header { display: flex; justify-content: space-between; gap: 18px; margin-bottom: 14px; }
.calendar-preview-header strong { display: block; font-size: 21px; }
.calendar-preview-header span { display: block; color: var(--caramel); font-size: 13px; font-weight: 850; }
.calendar-status { display: flex; align-items: center; gap: 8px; }
.calendar-status span { border-radius: 999px; background: var(--blush); color: var(--coffee); padding: 7px 10px; }
.calendar-status img, .fufu-bubble img { width: 44px; image-rendering: pixelated; }
.weekday-row, .month-grid { display: grid; grid-template-columns: repeat(7, minmax(0, 1fr)); gap: 6px; }
.weekday-row { margin-bottom: 8px; color: var(--caramel); font-size: 11px; font-weight: 950; text-align: center; }
.month-grid span {
  min-height: 46px;
  border-radius: 12px;
  background: #fff8ee;
  padding: 6px;
  font-weight: 850;
}
.month-grid small { display: block; font-size: 10px; color: var(--muted); }
.month-grid .outside { background: #f0dfc5; color: #8c6b58; }
.month-grid .selected { background: var(--blue); border: 2px solid #7aa8b9; }
.month-grid .blush { background: var(--blush); }
.month-grid .lavender { background: var(--lavender); }
.month-grid .gold { background: var(--gold); }
.month-grid .peach { background: var(--peach); }
.month-grid .green { background: var(--green); }
.calendar-cards { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 10px; margin-top: 15px; }
.calendar-cards article { border-radius: 15px; background: #fff; padding: 12px; color: var(--muted); }
.calendar-cards strong { display: block; color: var(--coffee); margin-bottom: 4px; }
.fufu-bubble {
  position: absolute;
  right: -10px;
  bottom: 0;
  display: flex;
  align-items: center;
  gap: 10px;
  max-width: 300px;
  border: 1px solid var(--line);
  border-radius: 22px;
  background: #fffaf0;
  padding: 13px 15px;
  box-shadow: 0 18px 44px rgba(70, 39, 18, 0.14);
}
.fufu-bubble p { margin: 0; color: var(--muted); line-height: 1.4; }
.fufu-bubble strong { color: var(--coffee); }

.section { padding: 72px 0; }
.section-heading { max-width: 720px; margin-bottom: 28px; }
.section-heading.compact { max-width: none; }
h2 { font-size: clamp(34px, 4.2vw, 52px); line-height: 1.04; letter-spacing: 0; }
.section-heading p:not(.soft-label) { color: var(--muted); font-size: 18px; line-height: 1.6; }
.feature-grid { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 14px; }
.feature-grid article, .workflow-grid article, .app-links a {
  position: relative;
  border: 1px solid var(--line);
  border-radius: 18px;
  background: rgba(255, 255, 255, 0.78);
  padding: 18px;
  box-shadow: 0 12px 32px rgba(70, 39, 18, 0.07);
}
.feature-grid article > span {
  position: absolute;
  right: 16px;
  top: 14px;
  color: var(--caramel);
  font-weight: 950;
}
.feature-grid h3, .workflow-grid h3 { margin-bottom: 8px; font-size: 20px; }
.feature-grid p, .workflow-grid p, .app-links small { margin: 0; color: var(--muted); line-height: 1.55; }
.workflow-grid { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 14px; }
.workflow-grid article:nth-child(1) { background: #fff6e8; }
.workflow-grid article:nth-child(2) { background: #f4f8ff; }
.workflow-grid article:nth-child(3) { background: #fff1f2; }
.workflow-grid article:nth-child(4) { background: #f3f8ef; }
.workflow-grid article > span {
  display: grid;
  place-items: center;
  width: 36px;
  height: 36px;
  margin-bottom: 12px;
  border-radius: 50%;
  background: var(--coffee);
  color: #fffaf0;
  font-weight: 950;
}

.download-panel {
  display: grid;
  grid-template-columns: 0.9fr 1.1fr;
  gap: 28px;
  align-items: start;
  border-radius: 28px;
  padding: clamp(24px, 4vw, 42px);
  color: #fffaf0;
  background: linear-gradient(135deg, #2d1e18, #4d2d19);
  box-shadow: var(--shadow);
}
.download-panel .soft-label { color: #f4c99c; }
.download-panel p { color: #ead8ca; line-height: 1.58; }
.secondary-button.dark { border-color: rgba(255, 250, 240, 0.28); color: #ead8ca; background: transparent; }
.release-card {
  display: flex;
  gap: 12px;
  align-items: center;
  margin: 18px 0;
  border: 1px solid rgba(255, 250, 240, 0.18);
  border-radius: 18px;
  background: rgba(255, 250, 240, 0.10);
  padding: 14px;
}
.release-card > span, .download-steps > li > span {
  display: grid;
  place-items: center;
  width: 58px;
  height: 58px;
  border-radius: 15px;
  background: #fffaf0;
  color: var(--coffee);
  font-weight: 950;
}
.release-card p { margin: 5px 0 0; }
.download-steps { list-style: none; margin: 0; padding: 0; display: grid; gap: 12px; }
.download-steps li {
  display: grid;
  grid-template-columns: 38px 1fr;
  gap: 14px;
  border: 1px solid rgba(255, 250, 240, 0.14);
  border-radius: 16px;
  background: rgba(255, 250, 240, 0.10);
  padding: 14px;
}
.download-steps > li > span { width: 34px; height: 34px; border-radius: 50%; }
.download-steps p { margin: 6px 0 0; }

.privacy-section { border-top: 1px solid var(--line); border-bottom: 1px solid var(--line); }
.app-links { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 14px; }
.app-links a { display: grid; gap: 8px; min-height: 170px; }
.app-links a > span {
  display: grid;
  place-items: center;
  width: 54px;
  height: 54px;
  border-radius: 16px;
  background: #fff6e8;
  color: var(--coffee);
  font-weight: 950;
}
footer {
  width: min(1160px, calc(100% - 32px));
  margin: 0 auto 28px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  border-radius: 22px;
  padding: 18px;
  color: #fffaf0;
  background: var(--coffee);
}
footer img { width: 42px; height: 42px; border-radius: 12px; }

@media (max-width: 920px) {
  .site-header { align-items: stretch; flex-direction: column; }
  nav { flex-wrap: wrap; justify-content: center; }
  .header-actions { justify-content: center; }
  .hero, .download-panel { grid-template-columns: 1fr; }
  .hero { min-height: auto; padding-top: 44px; }
  .feature-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
  .workflow-grid, .app-links { grid-template-columns: 1fr 1fr; }
  .fufu-bubble { position: static; margin: 14px 0 0 auto; }
}

@media (max-width: 640px) {
  main, .site-header, footer { width: min(100% - 20px, 1160px); }
  h1 { font-size: 42px; }
  .hero-text { font-size: 17px; }
  .feature-grid, .workflow-grid, .app-links, .calendar-cards { grid-template-columns: 1fr; }
  .weekday-row, .month-grid { gap: 4px; }
  .month-grid span { min-height: 40px; padding: 5px; font-size: 13px; }
  .download-panel { border-radius: 22px; }
}
```

- [ ] **Step 3: Verify core CSS selectors exist**

Run:

```bash
for selector in ".site-header" ".hero" ".calendar-preview" ".feature-grid" ".workflow-grid" ".download-panel" ".app-links"; do
  rg -n --fixed-strings "$selector" website/styles.css >/dev/null
done
python3 - <<'PY'
from pathlib import Path
css = Path("website/styles.css").read_text()
for color in ["#fff6e8", "#2d1e18", "#b87942", "#d9e8ee", "#f7c4ba"]:
    assert color in css, color
assert "@media (max-width: 640px)" in css
print("css selectors ok")
PY
```

Expected output:

```text
css selectors ok
```

- [ ] **Step 4: Commit CSS**

Run:

```bash
git add website/styles.css
git commit -m "Style MeowPlanner website"
```

Expected: commit succeeds.

## Task 5: Language Switching and Disabled Downloads

**Files:**
- Create: `website/script.js`

- [ ] **Step 1: Verify script is referenced but missing**

Run:

```bash
rg -n 'src="./script.js"' website/index.html
test ! -f website/script.js
```

Expected: first command finds the script reference, second command exits `0`.

- [ ] **Step 2: Create `website/script.js`**

Create `website/script.js` with this implementation pattern:

```javascript
const translations = {
  en: {
    metaTitle: "MeowPlanner - FuFu's Calendar Planner",
    metaDescription: "MeowPlanner is a FuFu calendar planner for classes, focus, habits, schedules, and to-dos.",
    brandAria: "MeowPlanner home",
    navAria: "Primary navigation",
    navFeatures: "Features",
    navCalendar: "Calendar",
    navDownload: "Download",
    navMoreApps: "More FuFu Apps",
    navPrivacy: "Privacy",
    navCta: "Coming soon",
    softLabel: "FuFu keeps the calendar cozy",
    heroTitle: "A FuFu calendar planner for classes, focus, and tiny habits",
    heroText: "MeowPlanner turns the month grid into a soft command center: schedules, to-dos, timetable weeks, focus blocks, and habit streaks all stay visible with FuFu nearby.",
    primaryCta: "Download coming soon",
    secondaryCta: "Explore calendar",
    availabilityNote: "The final download flow will be enabled after the DMG is ready.",
    calendarPreviewAria: "MeowPlanner calendar preview",
    calendarMonth: "June 2026",
    calendarWeek: "Week 23 - FuFu plan view",
    calendarStatus: "3 schedules",
    focusCardTitle: "FuFu focus",
    focusCardText: "25 min block at 2:00 PM",
    classCardTitle: "Class week",
    classCardText: "W16 timetable visible",
    fufuBubbleTitle: "FuFu says:",
    fufuBubbleText: "Tuesday has room for one tiny focus block.",
    featuresLabel: "More calendar, more FuFu",
    featuresTitle: "Plan the day without leaving FuFu's world",
    featuresText: "MeowPlanner combines the planning surfaces already in the app: calendar, agenda, to-dos, timetable, focus, habits, and a Today widget source.",
    featureCalendarTitle: "Calendar + agenda",
    featureCalendarText: "Month grid with date colors, selected-day schedules, Chinese calendar details, completed schedule display, and FuFu's daily note.",
    featureTodoTitle: "To-dos by group",
    featureTodoText: "Daily tasks and grouped to-do lists beside the calendar, so planning feels like a daily page.",
    featureTimetableTitle: "Course timetable",
    featureTimetableText: "Weekly class grid with semester weeks, course colors, teachers, rooms, and holiday-aware display.",
    featureFocusTitle: "Focus + habits",
    featureFocusText: "FuFu focus blocks, recent focus history, habit check-ins, streaks, and tiny encouragement.",
    featureWidgetTitle: "Today widget source",
    featureWidgetText: "WidgetKit Today widget source for quick schedule summaries.",
    featureLocalTitle: "Local-first planning",
    featureLocalText: "SwiftData models are CloudKit-ready, while v1 stays focused on your own Mac planner workflow.",
    workflowTitle: "A day in four small moves",
    workflowOneTitle: "Pick today",
    workflowOneText: "Start from the month grid and selected-day agenda.",
    workflowTwoTitle: "See classes",
    workflowTwoText: "Use the timetable to keep course weeks visible.",
    workflowThreeTitle: "Focus once",
    workflowThreeText: "Run one calm FuFu focus block.",
    workflowFourTitle: "Check habits",
    workflowFourText: "Close the day with tiny streaks.",
    downloadLabel: "下载流程 / Download flow",
    downloadTitle: "DMG coming soon on FuFu's release calendar",
    downloadText: "A small release-calendar card keeps the disabled download state honest until packaging is complete.",
    releaseCardText: "FuFu will unlock this button after packaging.",
    downloadButton: "DMG coming soon",
    checksumButton: "SHA-256 pending",
    downloadStepsAria: "Download flow",
    stepOneTitle: "Download day",
    stepOneText: "Save MeowPlanner.dmg when the release opens.",
    stepTwoTitle: "Install",
    stepTwoText: "Open the DMG and drag MeowPlanner into Applications.",
    stepThreeTitle: "Open once",
    stepThreeText: "Control-click MeowPlanner and choose Open if macOS asks.",
    stepFourTitle: "Plan with FuFu",
    stepFourText: "Open the calendar, pick today, and let FuFu sit beside the plan.",
    privacyLabel: "Local-first planning",
    privacyTitle: "Your calendar stays on your Mac",
    privacyText: "MeowPlanner is designed around local schedules, to-dos, focus history, habits, and timetable data. SwiftData models are CloudKit-ready, but v1 does not promise account sync or third-party calendar sync.",
    moreAppsLabel: "Want more FuFu apps?",
    moreAppsTitle: "FuFu can help in more tiny Mac tools",
    pastepawText: "FuFu clipboard helper for macOS.",
    slackerText: "FuFu desktop pet for mindful breaks.",
    portfolioTitle: "Portfolio",
    portfolioText: "The project home behind the FuFu series.",
    footerText: "MeowPlanner · FuFu's calendar planner for schedules, classes, focus, and habits"
  },
  zh: {
    metaTitle: "MeowPlanner - FuFu 的喵系时间规划器",
    metaDescription: "MeowPlanner 是一款 FuFu 喵系日历规划器，用来管理课程、专注、习惯、日程和待办。",
    brandAria: "MeowPlanner 首页",
    navAria: "主导航",
    navFeatures: "功能",
    navCalendar: "日历",
    navDownload: "下载",
    navMoreApps: "更多 FuFu 应用",
    navPrivacy: "隐私",
    navCta: "即将开放",
    softLabel: "FuFu 让日历变得更温柔",
    heroTitle: "FuFu 的喵系日历规划器",
    heroText: "MeowPlanner 把月历变成一个温柔的 FuFu 规划中心：日程、待办、课程周、专注块和习惯打卡都可以放在同一个时间视图里。",
    primaryCta: "下载即将开放",
    secondaryCta: "查看日历功能",
    availabilityNote: "DMG 准备完成后，这里的下载流程会正式开放。",
    calendarPreviewAria: "MeowPlanner 日历预览",
    calendarMonth: "2026 年 6 月",
    calendarWeek: "第 23 周 - FuFu 规划视图",
    calendarStatus: "3 个日程",
    focusCardTitle: "FuFu 专注",
    focusCardText: "下午 2:00 的 25 分钟专注块",
    classCardTitle: "课程周",
    classCardText: "第 16 周课程表可见",
    fufuBubbleTitle: "FuFu 说：",
    fufuBubbleText: "周二还可以放一个小小的专注块。",
    featuresLabel: "更多日历感，也更多 FuFu",
    featuresTitle: "在 FuFu 的世界里安排一天",
    featuresText: "MeowPlanner 集合了应用里的核心规划界面：日历、日程、待办、课程表、专注、习惯和 Today widget 来源。",
    featureCalendarTitle: "日历 + 日程",
    featureCalendarText: "带日期颜色的月历、选中日期日程、中国农历信息、已完成日程显示和 FuFu 每日提示。",
    featureTodoTitle: "分组待办",
    featureTodoText: "日常任务和分组待办放在日历旁边，让规划更像一页每日计划。",
    featureTimetableTitle: "课程表",
    featureTimetableText: "按学期周显示的课程网格，支持课程颜色、老师、地点和节假日显示。",
    featureFocusTitle: "专注 + 习惯",
    featureFocusText: "FuFu 专注块、最近专注记录、习惯打卡、连续天数和轻量鼓励。",
    featureWidgetTitle: "Today widget 来源",
    featureWidgetText: "WidgetKit Today widget 来源，用来快速查看日程摘要。",
    featureLocalTitle: "本地优先规划",
    featureLocalText: "SwiftData 模型已为 CloudKit 做好准备，但 v1 先专注你自己的 Mac 规划流程。",
    workflowTitle: "一天只需要四个小动作",
    workflowOneTitle: "选中今天",
    workflowOneText: "从月历和选中日期日程开始。",
    workflowTwoTitle: "查看课程",
    workflowTwoText: "用课程表保持课程周清晰可见。",
    workflowThreeTitle: "专注一次",
    workflowThreeText: "开启一个安静的 FuFu 专注块。",
    workflowFourTitle: "打卡习惯",
    workflowFourText: "用小小的连续记录结束一天。",
    downloadLabel: "下载流程 / Download flow",
    downloadTitle: "FuFu 的发布日历即将开放 DMG 下载",
    downloadText: "发布日历卡片会保留下载位置，同时在打包完成前保持诚实的即将开放状态。",
    releaseCardText: "打包完成后，FuFu 会解锁这个按钮。",
    downloadButton: "DMG 即将开放",
    checksumButton: "SHA-256 待生成",
    downloadStepsAria: "下载流程",
    stepOneTitle: "下载日",
    stepOneText: "发布开放后保存 MeowPlanner.dmg。",
    stepTwoTitle: "安装",
    stepTwoText: "打开 DMG，把 MeowPlanner 拖进 Applications。",
    stepThreeTitle: "首次打开",
    stepThreeText: "如果 macOS 提示开发者信息，按住 Control 点击 MeowPlanner 并选择打开。",
    stepFourTitle: "和 FuFu 一起规划",
    stepFourText: "打开日历，选中今天，让 FuFu 坐在计划旁边。",
    privacyLabel: "本地优先规划",
    privacyTitle: "你的日历留在自己的 Mac 上",
    privacyText: "MeowPlanner 围绕本地日程、待办、专注记录、习惯和课程表数据设计。SwiftData 模型已为 CloudKit 做好准备，但 v1 不承诺账号同步或第三方日历同步。",
    moreAppsLabel: "想看看更多 FuFu 应用？",
    moreAppsTitle: "FuFu 也可以陪你使用更多小工具",
    pastepawText: "FuFu 的 macOS 剪贴板助手。",
    slackerText: "提醒休息和喝水的 FuFu 桌面宠物。",
    portfolioTitle: "作品集",
    portfolioText: "FuFu 系列背后的项目主页。",
    footerText: "MeowPlanner · FuFu 的喵系时间规划器"
  }
};

const storageKey = "meowplannerLanguage";

function applyLanguage(language) {
  const dictionary = translations[language] || translations.en;
  document.documentElement.lang = language === "zh" ? "zh-Hans" : "en";
  document.querySelectorAll("[data-i18n]").forEach((element) => {
    const key = element.dataset.i18n;
    if (dictionary[key]) element.textContent = dictionary[key];
  });
  document.querySelectorAll("[data-i18n-content]").forEach((element) => {
    const key = element.dataset.i18nContent;
    if (dictionary[key]) element.setAttribute("content", dictionary[key]);
  });
  document.querySelectorAll("[data-i18n-aria]").forEach((element) => {
    const key = element.dataset.i18nAria;
    if (dictionary[key]) element.setAttribute("aria-label", dictionary[key]);
  });
  document.querySelectorAll("[data-language-option]").forEach((button) => {
    button.setAttribute("aria-pressed", String(button.dataset.languageOption === language));
  });
  localStorage.setItem(storageKey, language);
}

document.querySelectorAll("[data-language-option]").forEach((button) => {
  button.addEventListener("click", () => applyLanguage(button.dataset.languageOption));
});

document.querySelectorAll("[data-disabled-download]").forEach((link) => {
  link.addEventListener("click", (event) => {
    event.preventDefault();
    document.querySelector("#download")?.scrollIntoView({ behavior: "smooth" });
  });
});

const initialLanguage = localStorage.getItem(storageKey) || "en";
applyLanguage(initialLanguage);
```

- [ ] **Step 3: Validate JavaScript syntax**

Run:

```bash
node --check website/script.js
```

Expected output contains no syntax errors.

- [ ] **Step 4: Validate Chinese and English keys exist**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
js = Path("website/script.js").read_text()
for key in ["heroTitle", "downloadTitle", "privacyTitle", "footerText"]:
    assert key in js, key
assert "FuFu 的喵系日历规划器" in js
assert "A FuFu calendar planner for classes, focus, and tiny habits" in js
print("translations ok")
PY
```

Expected output:

```text
translations ok
```

- [ ] **Step 5: Commit script**

Run:

```bash
git add website/script.js
git commit -m "Add MeowPlanner website language switcher"
```

Expected: commit succeeds.

## Task 6: Local Browser Verification and Polish

**Files:**
- Modify as needed: `website/index.html`
- Modify as needed: `website/styles.css`
- Modify as needed: `website/script.js`

- [ ] **Step 1: Run static checks**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
html = Path("website/index.html").read_text()
css = Path("website/styles.css").read_text()
js = Path("website/script.js").read_text()
assert 'href="/assets/meowplanner-icon.png"' in html
assert 'src="./assets/fufu-idle.png"' in html
assert "data-disabled-download" in html
assert "downloads/MeowPlanner.dmg" not in html
assert ".calendar-preview" in css
assert "Download coming soon" in js
print("static website checks ok")
PY
node --check website/script.js
```

Expected output includes:

```text
static website checks ok
```

- [ ] **Step 2: Start a local static server**

Run:

```bash
python3 -m http.server 4173 --directory website
```

Expected: server starts and serves `http://localhost:4173/`. Keep this process running until visual verification is complete.

- [ ] **Step 3: Verify desktop layout in Browser/IAB**

Open:

```text
http://localhost:4173/
```

Expected desktop checks:

- Header is sticky, rounded, and not covering hero text.
- Hero shows MeowPlanner name, large calendar headline, FuFu image, calendar mockup, selected date, colored date cells, focus card, class week card, and FuFu speech bubble.
- Download buttons are visually disabled and scroll to the download section instead of opening a missing file.
- Feature cards include calendar and FuFu markers.
- More FuFu apps links go to PastePaw, SlackerBuddy, and portfolio.

- [ ] **Step 4: Verify Chinese language state**

In Browser/IAB, click `中文`.

Expected checks:

- `html` language becomes `zh-Hans`.
- Hero headline becomes `FuFu 的喵系日历规划器`.
- Primary CTA becomes `下载即将开放`.
- Privacy headline becomes `你的日历留在自己的 Mac 上`.
- Download state remains disabled.

- [ ] **Step 5: Verify mobile layout**

Use a mobile-sized viewport around `390x844`.

Expected checks:

- Header wraps without horizontal overflow.
- Hero text fits without clipping.
- Calendar mockup remains readable and does not overlap FuFu bubble.
- Feature, workflow, and app-link cards collapse to one column or two columns as specified.
- No horizontal scroll appears.

- [ ] **Step 6: Fix any visual issues found**

If verification finds clipping, overlap, unreadable text, or disabled download behavior problems, edit only the affected selectors or markup. After each fix, rerun:

```bash
node --check website/script.js
python3 - <<'PY'
from pathlib import Path
html = Path("website/index.html").read_text()
css = Path("website/styles.css").read_text()
assert "downloads/MeowPlanner.dmg" not in html
assert "@media (max-width: 640px)" in css
print("post-fix checks ok")
PY
```

Expected output:

```text
post-fix checks ok
```

- [ ] **Step 7: Commit verified polish**

Run:

```bash
git status --short website vercel.json .vercelignore .gitignore
git add website/index.html website/styles.css website/script.js
git commit -m "Polish MeowPlanner website"
```

Only commit if there are polish changes after Tasks 3 to 5. If there are no changes, skip this commit.

## Task 7: Final Handoff Without Deployment

**Files:**
- Read: `docs/superpowers/specs/2026-06-08-meowplanner-website-design.md`
- Read: `website/index.html`
- Read: `website/styles.css`
- Read: `website/script.js`

- [ ] **Step 1: Confirm spec acceptance coverage**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
html = Path("website/index.html").read_text()
checks = {
    "FuFu present": "fufu-idle.png" in html,
    "calendar present": "calendar-preview" in html,
    "download disabled": "data-disabled-download" in html,
    "no fake dmg": "downloads/MeowPlanner.dmg" not in html,
    "pastepaw link": "https://pastepaw.vercel.app/" in html,
    "slacker link": "https://slackerbuddy.vercel.app/" in html,
    "portfolio link": "https://xyuuue.github.io/yueling-qiu/" in html,
}
missing = [name for name, ok in checks.items() if not ok]
assert not missing, missing
print("spec coverage ok")
PY
```

Expected output:

```text
spec coverage ok
```

- [ ] **Step 2: Confirm deployment was not run**

Run:

```bash
git status --short
```

Expected: no `.vercel/` metadata is staged, and no final response claims a Vercel deployment.

- [ ] **Step 3: Final response**

Report:

- The website files created.
- The local URL used for verification.
- Desktop and mobile visual checks completed.
- Language switch verified.
- Download remains coming-soon and disabled.
- Vercel deployment has not been performed and still requires explicit user approval.

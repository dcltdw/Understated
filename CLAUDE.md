# CLAUDE.md

Guidance for working in this repo. See [README.md](README.md) for the
user-facing description.

## What this is

**Understated** is a Garmin Connect IQ analog watch face written in Monkey C,
targeting the Forerunner 55 (`fr55`), `minApiLevel 3.4.0`.

## Build / verify

Monkey C is type-checked at compile time, so compiling is the cheapest
verification. `monkeyc` needs a Java runtime on `PATH`:

```sh
export JAVA_HOME=/usr/local/opt/openjdk/libexec/openjdk.jdk/Contents/Home
export PATH="$JAVA_HOME/bin:$PATH"
SDK=~/Library/Application\ Support/Garmin/ConnectIQ/Sdks/<your-sdk>
"$SDK/bin/monkeyc" -f monkey.jungle -o /tmp/check.prg \
    -y /path/to/developer_key -d fr55 -w
```

A clean build prints `BUILD SUCCESSFUL`. The launcher-icon-size warning
(24x24 vs 35x35) is pre-existing and harmless. There is no CI and no test
suite; behavior beyond "it compiles" must be checked in the simulator/device.

## Architecture

| File | Responsibility |
|---|---|
| `source/understatedApp.mc` | `AppBase` lifecycle; builds the view; reloads settings and re-resolves the theme on `onSettingsChanged`. |
| `source/understatedView.mc` | All rendering: theme resolution, the programmatic dial (`drawBackground`), the four data fields (`drawDataFields`) with their icons (`drawIcon`/`drawWeather`), the hands, and the battery gauge. |
| `source/understatedSettings.mc` | `UnderstatedSettings` — reads `colorTheme`, `secondHand`, and the four data-field slots from `Application.Properties` (configured from the phone via the Connect IQ app-settings form). No on-device menu. |
| `resources/` | Strings, the launcher icon, and `settings/` (the phone settings form `settings.xml` + property defaults `properties.xml`). No layout resource and no background bitmaps: the whole face is drawn manually in `onUpdate`, and `onLayout` deliberately does not call `setLayout` (loading a layout was dead weight, and invoking the layout symbol at the install-time auto-launch was implicated in a first-launch crash on some devices). |
| `resources-<lang>/` | One folder per language every targeted device supports (35 of them), each holding only `strings/strings.xml` with `AppName` = "Understated" (a brand name, identical in all languages), and the matching `<iq:language>` entries in the manifest. The app loads no resources at runtime, so the only string the OS ever resolves is `AppName`; CIQ's fallback to the default `eng` resource is buggy on real hardware for undeclared device languages (it can crash loading the resource — the suspected non-English-locale failure mode), so every device language gets an explicit `AppName` rather than relying on that fallback. Declaring a language without its folder crashes, so the two always move together. |

## Theme scheme

`colorTheme` is a single stored integer (`Application.Properties`, key
`"colorTheme"`):

- **0–6** → a fixed color (see table).
- **7 ("Multi")** → rotate the color by day of week.

`check_for_day_advance(force, _now)` resolves the setting to a concrete
`target_theme` in 0–6 (a raw `7` never reaches the render switch) and sets the
theme's colors (`background_color`, `numerals_color`, hands/date/battery
colors), only re-running the switch when the resolved theme changes (cached in
`last_theme`). Invalid values recover to Blue (0) and are persisted.

The dial itself is drawn programmatically in `drawBackground`: a full-screen
fill plus 12 upright Roman numerals placed around the circle (no bitmaps), so
it scales to any screen size or shape. Earlier versions used per-theme 208×208
PNGs; those were removed because a resident full-screen bitmap is large for the
fr55 watch-face memory budget (it caused intermittent out-of-memory crashes).

| Theme | Color | Day (Multi) |
|---|---|---|
| 0 | Blue | Mon |
| 1 | Green | Tue |
| 2 | Purple | Wed |
| 3 | Red | Thu |
| 4 | Yellow | Sun |
| 5 | Black/Gold | Sat |
| 6 | Black/Silver | Fri |
| 7 | Multi (rotates) | — |

## Data fields

Up to four data fields are drawn inboard of the numerals at 12/3/6/9
(`drawDataFields`). Each slot has four `Application.Properties` keys —
`s{12,3,6,9}{Show,Fmt,Col,Size}` — for content, format, color, and size:

- **Show** — off, or one of ~18 metrics (date, body battery, heart rate,
  steps, …, weather temperature/condition). SensorHistory-backed metrics (body
  battery, stress, Pulse Ox, elevation, pressure, temperature) read the newest
  non-null sample via `newestData` (a small `:period` window, walking past null
  slots so a gap doesn't show `--`).
- **Fmt** — value, label + value, icon + value, or icon only.
- **Col** — fixed colors plus three per-theme tiers: `Accent`, `Muted`, and
  `Second hand` (resolved in `resolveColor`).
- **Size** — Tiny / Small / Medium / Large.

Icons are drawn programmatically (`drawIcon`); the weather-condition icon is
condition-aware (`drawWeather` / `weatherCategory`: sun, partly cloudy, rain,
snow, …). The 3 and 9 o'clock slots right/left-justify to hug their numeral and
grow inward; fields are nudged onto the numeral's centerline. `SensorHistory`
needs the manifest permission of the same name.

## Battery-as-hour-hand

In `drawHands`, the hour hand is split: the segment from the hub outward
covering the *discharged* fraction of the battery is drawn in
`battery_discharged_color`; the remaining (charged) segment is drawn in
`hands_color`. So a full battery shows a full-color hour hand, and the accent
color grows as the battery drains.

## Multi-device, power modes, and second hand

The manifest targets ~78 watch-face-capable MIP + AMOLED devices (Instinct
excluded). Because the dial is programmatic, the same code scales to every
size/shape/color-depth.

Power modes are tracked with `isLowPower` (set in `onEnterSleep`/`onExitSleep`)
and `burnInProtect` (cached from `getDeviceSettings().requiresBurnInProtection`):

- **High power** (awake): `onUpdate` runs ~1/sec, so the full dial draws plus a
  second hand (`drawSecondHand`, in the per-theme second-hand color), gated by
  `!isLowPower && mySettings.showSecondHand()`. The second hand is a user
  setting (Properties key `secondHand`: Auto/On/Off); Auto resolves by device
  class — on at >=104KB watch-face memory (capable), off below (fr55 96KB)
  where the 1/sec redraw is sluggish.
- **Low power, MIP** (`burnInProtect == false`): full dial, no second hand
  (`onUpdate` is ~1/min, so a second hand would freeze).
- **Low power, AMOLED** (`burnInProtect == true`): `drawLowPower` renders a
  burn-in-safe frame — black background, thin hands, small date, shifted a
  couple pixels each minute.

`onPartialUpdate` stays a no-op (its absence caused a low-power crash on fr55);
all real drawing happens in `onUpdate`.

Build for all targets / sweep with SDK 9.1.0 (`-d <device>` per manifest entry;
the `.iq` export `-e` builds every product at once).

## AI-collaboration conventions

This repo follows a subset of
`~/Github/annotated-maps/docs/AI-COLLABORATION-CONVENTIONS.md` (the master
record — edit that doc, not this replica, when a rule changes). Adopted here:

- **Rule 1** — size each ticket to one PR.
- **Rule 2 / 3** — every issue lives on the Understated project board; move
  status Todo → In Progress (PR opens) → Done (PR merges).
- **Rule 4** — PR bodies include `Files changed`, `Work breakdown`,
  `Test expectations` (only when failures are expected), and
  `Operational impact` (rebuild/reinstall/storage-migration notes for a watch
  face). In `Files changed`, annotate each entry's status — `(new)` /
  `(deleted)` / (modified) — so additions and deletions are visible at a
  glance, not just modifications.
- **Rule 5** — stamp commits with the current AI model in `Co-Authored-By:`.
- **Rule 6** — scan each diff for secrets before pushing.
- **Rule 8** — this file is a thin replica pointing back to the master doc.

Skipped (not applicable at this scale): CI-extension (no CI), test-expectations
tables by default, midpoint audits, and burst mode.

### Project board

- Board: https://github.com/users/dcltdw/projects/3 (`PVT_kwHOAAdfes4BZh9C`)
- Status field `PVTSSF_lAHOAAdfes4BZh9CzhUf9Q8`:
  Todo `f75ad846`, In Progress `47fc9ee4`, Done `98236657`

Re-derive if these drift:

```sh
gh api graphql -f query='{ user(login:"dcltdw"){ projectV2(number:3){ id
  field(name:"Status"){ ... on ProjectV2SingleSelectField { id options { id name } } } } } }'
```

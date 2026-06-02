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
| `source/understatedApp.mc` | `AppBase` lifecycle; builds the view and settings menu; re-resolves the theme on `onSettingsChanged`. |
| `source/understatedView.mc` | All rendering: theme resolution + background, date, hands, and the battery gauge. |
| `source/understatedSettings.mc` | `UnderstatedSettings` (persists `colorTheme` to `Application.Storage`) plus the on-device `Menu2` and its delegate. |
| `resources/` | Background PNGs, strings, drawables, and an intentionally-empty `WatchFace` layout (date/hands are drawn manually). |

## Theme scheme

`colorTheme` is a single stored integer (`Application.Storage`, key
`"colorTheme"`):

- **0–6** → a fixed color (see table).
- **7 ("Multi")** → rotate the color by day of week.

`check_for_day_advance(force, _now)` resolves the setting to a concrete
`target_theme` in 0–6 (a raw `7` never reaches the render switch), reloads the
background only when the resolved theme changes (cached in `last_theme`), and
returns `true` only on an actual change. Invalid values recover to Blue (0) and
are persisted.

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

## Battery-as-hour-hand

In `drawHands`, the hour hand is split: the segment from the hub outward
covering the *discharged* fraction of the battery is drawn in
`battery_discharged_color`; the remaining (charged) segment is drawn in
`hands_color`. So a full battery shows a full-color hour hand, and the accent
color grows as the battery drains.

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
  face).
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

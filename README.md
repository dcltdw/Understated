# Understated

A minimal analog watch face for Garmin Connect IQ. The hour hand doubles as a
battery gauge, over one of seven solid color backgrounds.

## Features

- **Analog time** — hour and minute hands (minute resolution; no second hand).
- **Battery-as-hour-hand** — the "discharged" portion of the hour hand is drawn
  in a separate accent color, so the hand fills back up as the watch charges.
- **Date** — day-of-month, drawn to the right of center.
- **Color themes** — pick a fixed color, or "Multi" to rotate the color by day
  of week. See [CLAUDE.md](CLAUDE.md) for the theme/day mapping.

## Supported device

Targets the Garmin **Forerunner 55 (`fr55`)**. The backgrounds are raster PNGs
sized for that device; other devices are not currently configured.

## Build

Requires the Connect IQ SDK and a Java runtime, plus a developer key.

```sh
# Java (one-time): a JDK must be on PATH for monkeyc
export JAVA_HOME=/usr/local/opt/openjdk/libexec/openjdk.jdk/Contents/Home
export PATH="$JAVA_HOME/bin:$PATH"

SDK=~/Library/Application\ Support/Garmin/ConnectIQ/Sdks/<your-sdk>
"$SDK/bin/monkeyc" -f monkey.jungle -o bin/Understated.prg \
    -y /path/to/developer_key -d fr55 -w
```

In VS Code, use the Monkey C extension's **Run App** / **Run Tests** launch
configurations instead.

## Install (sideload over USB)

Connect the watch by USB; it mounts as a volume named `GARMIN`. Copy the built
`.prg` into the device apps folder (on the Forerunner 55 this is uppercase
`APPS`):

```sh
cp bin/Understated.prg /Volumes/GARMIN/GARMIN/APPS/
```

Eject the volume and unplug; the watch installs the app on disconnect. Then on
the watch, long-press **UP** → **Watch Face** → select **Understated**.

## Settings

Press the menu/select on the watch to open **Settings → Color** and cycle
through: Blue, Green, Purple, Red, Yellow, Black/Gold, Black/Silver, Multi.

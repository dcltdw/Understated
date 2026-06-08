# Store assets

Assets for the Connect IQ store listing.

## Listing text

- `description.txt` — the store description (~1330 chars; the store cap is 4000).
- `changelog.txt` — release notes / "What's New".

## Hero image (`hero.png`)

The store banner — **1440×720** (the size the store requires for the hero
image). Dark banner with the app name and three themes (blue/purple/red) at
10:10.

## Screenshots

Two sets, one image per color theme (`1-blue` … `7-black_silver`):

### `screenshots/sim/` — true simulator captures (use these for the store)

Real Connect IQ simulator renders on the **Venu 3** (round AMOLED) with the
**actual Garmin font**, captured via window-region `screencapture` and cropped
to the watch face, normalized to **454×454** (Venu 3 native). They show time
**10:10**, battery ~65% (the discharged part of the hour hand is the accent
color), the date, and the second hand (the capable-device default; fr55 and
other constrained devices default it off).

### `screenshots/*.png` — vector renders (reference / fallback)

Generated from the exact dial geometry/colors via `gen_screens.py` →
`rsvg-convert` (454×454, `.svg` source alongside). The numeral font is
Helvetica (a stand-in for `FONT_TINY`); colors are the AMOLED/full-color
values. Kept as a resolution-independent reference.

### Capturing more sim screenshots

Load the app in the simulator and either use **File → Save Screen Shot** (clean
native PNG), or capture the sim window region with `screencapture`. Change the
color via **Settings → Color**, or force `colorTheme` in
`UnderstatedSettings.loadLocal` for a scripted batch. The sim must be on an
awake, capturable display (Screen Recording permission required for
`screencapture`).

### Regenerate the renders

```sh
python3 gen_screens.py
cd screenshots && for f in *.svg; do rsvg-convert -w 454 -h 454 "$f" -o "${f%.svg}.png"; done
```

## App package (`.iq`)

The multi-device store package is built to **`bin/Understated.iq`** (~1.2 MB,
126 device variants across all 78 targeted watches). It's git-ignored (build
artifact); rebuild from `main` with:

```sh
SDK=~/Library/Application\ Support/Garmin/ConnectIQ/Sdks/<sdk>
"$SDK/bin/monkeyc" -f monkey.jungle -o bin/Understated.iq -y <developer_key> -e -r -w
```

Upload `bin/Understated.iq` to the Connect IQ developer portal, with the
screenshots above.

> Minor: the build warns that the 35×35 launcher icon is upscaled on a few
> devices that want 40×40. It's an SVG so it scales cleanly; supplying a 40×40
> (or larger) launcher icon would silence the warning.

# Store assets

Assets for the Connect IQ store listing.

## Listing text

- `description.txt` — the store description (~1330 chars; the store cap is 4000).
- `changelog.txt` — release notes / "What's New".

## Hero image (`hero.png`)

The store banner — **1440×720** (the size the store requires for the hero
image). Dark banner with the app name over three simulator faces telling the
configurability story: a bare dial (Black/Silver), the date only (Blue), and
all four data fields (Green). Source captures are in `screenshots/hero/`.

## Promo animation (`promo.gif`)

A ~21s looping demo (360×360) that cycles the seven themes (~3s each) with
crossfades, each showing a different field layout — bare, date-only, two and
four fields, the Muted/Accent/Second-hand color tiers, icon and icon-only
formats, and a weather condition icon. For the store/social, not the watch.
Rebuild by re-capturing per-theme stills and reassembling with ImageMagick.

## Screenshots

One image per color theme (`1-blue` … `7-black_silver`), plus `sim-8-custom`
(the Custom theme: black background, red numerals, varied other colors).

### `screenshots/sim/` — true simulator captures (use these for the store)

Real Connect IQ simulator renders on the **Venu 3** (round AMOLED) with the
**actual Garmin font**, captured via window-region `screencapture` and cropped
to the watch face, normalized to **454×454** (Venu 3 native). They show time
**10:10**, battery ~65% (the discharged part of the hour hand is the accent
color), the date, and the second hand (the capable-device default; fr55 and
other constrained devices default it off).

### Capturing more sim screenshots

Load the app in the simulator and either use **File → Save Screen Shot** (clean
native PNG), or capture the sim window region with `screencapture`. Change the
color via **Settings → Color**, or force `colorTheme` in
`UnderstatedSettings.loadLocal` for a scripted batch. The sim must be on an
awake, capturable display (Screen Recording permission required for
`screencapture`).

### Optional vector renders (not committed)

`gen_screens.py` → `rsvg-convert` can generate resolution-independent SVG/PNG
mockups of the dial into `screenshots/` (Helvetica stands in for `FONT_TINY`).
These aren't committed — the simulator captures above are what ship — so make
them only if you want a quick vector reference:

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

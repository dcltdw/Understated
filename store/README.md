# Store assets

Assets for the Connect IQ store listing.

## Screenshots (`screenshots/`)

One image per color theme (`1-blue` … `7-black_silver`), 454×454 PNG
(AMOLED-class resolution), plus the `.svg` source for each.

They show: time 10:10, battery ~65% (the discharged part of the hour hand is
the accent color), date "12", and the second hand (the capable-device default;
the fr55 and other constrained devices default it off).

### ⚠️ These are faithful *renders*, not simulator captures

Generated with `gen_screens.py` → `rsvg-convert`, using the exact geometry and
colors from `source/understatedView.mc`. Two caveats vs. a real device:

- The numeral font is **Helvetica** (a stand-in for Garmin's `FONT_TINY`
  sans-serif) — very close, but not pixel-identical.
- Colors are the AMOLED/full-color values; on the fr55's 8-color MIP panel the
  thin accent (battery/second hand) quantizes slightly.

They were rendered instead of captured because the simulator screenshot path
needs macOS Screen Recording permission, which a headless tool can't grant.

**To produce pixel-true captures** (recommended before final upload): run the
app in the Connect IQ simulator and use **File → Save Screen Shot** (saves the
device screen at native resolution, no Screen Recording permission needed).
Change the color in **Settings → Color** for each theme. Pick a device per
display class (e.g. `venu3` AMOLED, `fr965`, and `fr55` MIP).

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

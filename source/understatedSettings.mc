import Toybox.Lang;
import Toybox.System;
import Toybox.Application;

// Settings are configured from the phone (Garmin Connect app) via the
// Connect IQ app-settings form (resources/settings/settings.xml) and stored in
// Application.Properties. There is no on-device settings menu.
//
// Slot arrays are indexed 0=12 o'clock, 1=3 o'clock, 2=6 o'clock, 3=9 o'clock.
class UnderstatedSettings {
    var colorTheme = 0 as Number;
    var secondHand = 0 as Number;          // 0 Auto, 1 On, 2 Off
    var slotShow as Array<Number> = [0, 1, 0, 0];  // content id per slot
    var slotFmt  as Array<Number> = [0, 0, 0, 0];  // 0 Value, 1 Label+value, 2 Icon+value
    var slotCol  as Array<Number> = [0, 0, 0, 0];  // color id
    var slotSize as Array<Number> = [1, 1, 1, 1];  // 0 Tiny, 1 Small, 2 Medium, 3 Large

    // Custom theme (colorTheme 8): user-entered RRGGBB hex parsed to color ints.
    var customBg       = 0x000000 as Number;
    var customNumerals = 0xFFFFFF as Number;
    var customHour     = 0xFFFFFF as Number;   // charged hour hand
    var customBattery  = 0xFF8800 as Number;   // discharged hour-hand sliver
    var customMinute   = 0xFFFFFF as Number;
    var customSecond   = 0xFF0000 as Number;
    var customSlot as Array<Number> = [0xFFFFFF, 0xFFFFFF, 0xFFFFFF, 0xFFFFFF]; // 12/3/6/9

    function initialize() {
        loadLocal();
    }

    // Read a numeric property, falling back to a default when unset.
    function prop(key as String, def as Number) as Number {
        var v = Application.Properties.getValue(key);
        return (v == null) ? def : v;
    }

    // Parse an "RRGGBB" hex string (tolerates a leading # and lower/upper case)
    // to a 0xRRGGBB color int; returns def on null/empty/malformed input.
    function parseHex(v, def as Number) as Number {
        if (v == null) { return def; }
        var s = v.toString().toUpper();
        if (s.length() > 0 and s.substring(0, 1).equals("#")) {
            s = s.substring(1, s.length());
        }
        if (s.length() != 6) { return def; }
        var hexd = "0123456789ABCDEF";
        var val = 0;
        for (var i = 0; i < 6; i += 1) {
            var idx = hexd.find(s.substring(i, i + 1));
            if (idx == null) { return def; }
            val = val * 16 + idx;
        }
        return val;
    }

    function loadLocal() as Void {
        colorTheme = prop("colorTheme", 0);
        secondHand = prop("secondHand", 0);
        slotShow = [prop("s12Show", 0), prop("s3Show", 1), prop("s6Show", 0), prop("s9Show", 0)];
        slotFmt  = [prop("s12Fmt", 0),  prop("s3Fmt", 0),  prop("s6Fmt", 0),  prop("s9Fmt", 0)];
        slotCol  = [prop("s12Col", 0),  prop("s3Col", 0),  prop("s6Col", 0),  prop("s9Col", 0)];
        slotSize = [prop("s12Size", 1), prop("s3Size", 1), prop("s6Size", 1), prop("s9Size", 1)];
        var P = Application.Properties;
        customBg       = parseHex(P.getValue("customBg"),       0x000000);
        customNumerals = parseHex(P.getValue("customNumerals"), 0xFFFFFF);
        customHour     = parseHex(P.getValue("customHour"),     0xFFFFFF);
        customBattery  = parseHex(P.getValue("customBattery"),  0xFF8800);
        customMinute   = parseHex(P.getValue("customMinute"),   0xFFFFFF);
        customSecond   = parseHex(P.getValue("customSecond"),   0xFF0000);
        customSlot = [
            parseHex(P.getValue("customS12"), 0xFFFFFF),
            parseHex(P.getValue("customS3"),  0xFFFFFF),
            parseHex(P.getValue("customS6"),  0xFFFFFF),
            parseHex(P.getValue("customS9"),  0xFFFFFF)
        ];
    }

    // Resolve the second-hand setting; Auto defaults on for capable devices and
    // off on constrained ones (fr55), where a 1/sec redraw is sluggish.
    function showSecondHand() as Boolean {
        if (secondHand == 1) { return true; }
        if (secondHand == 2) { return false; }
        return System.getSystemStats().totalMemory >= (104 * 1024);
    }
}

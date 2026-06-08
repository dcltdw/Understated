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
    var slotShow = [0, 1, 0, 0];           // content id per slot
    var slotFmt  = [0, 0, 0, 0];           // 0 Value, 1 Label+value, 2 Icon+value
    var slotCol  = [0, 0, 0, 0];           // color id
    var slotSize = [1, 1, 1, 1];           // 0 Tiny, 1 Small, 2 Medium, 3 Large

    function initialize() {
        loadLocal();
    }

    // Read a numeric property, falling back to a default when unset.
    function prop(key as String, def as Number) as Number {
        var v = Application.Properties.getValue(key);
        return (v == null) ? def : v;
    }

    function loadLocal() as Void {
        colorTheme = prop("colorTheme", 0);
        secondHand = prop("secondHand", 0);
        slotShow = [prop("s12Show", 0), prop("s3Show", 1), prop("s6Show", 0), prop("s9Show", 0)];
        slotFmt  = [prop("s12Fmt", 0),  prop("s3Fmt", 0),  prop("s6Fmt", 0),  prop("s9Fmt", 0)];
        slotCol  = [prop("s12Col", 0),  prop("s3Col", 0),  prop("s6Col", 0),  prop("s9Col", 0)];
        slotSize = [prop("s12Size", 1), prop("s3Size", 1), prop("s6Size", 1), prop("s9Size", 1)];
    }

    // Resolve the second-hand setting; Auto defaults on for capable devices and
    // off on constrained ones (fr55), where a 1/sec redraw is sluggish.
    function showSecondHand() as Boolean {
        if (secondHand == 1) { return true; }
        if (secondHand == 2) { return false; }
        return System.getSystemStats().totalMemory >= (104 * 1024);
    }
}

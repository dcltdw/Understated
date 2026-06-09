import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Math;
import Toybox.ActivityMonitor;
import Toybox.Activity;
import Toybox.SensorHistory;
import Toybox.Weather;


class UnderstatedView extends WatchUi.View {
    // Upright Roman numerals, index i -> the (i+1) o'clock mark.
    private const NUMERALS = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"];

    var mySettings;
    var last_theme = -1;
    var background_color;
    var numerals_color;
    var date_color;
    var hands_color;
    var battery_discharged_color; // battery sliver on the hour hand
    var muted_color;              // per-theme low-contrast data-field color
    var accent_color;             // per-theme bold data-field color
    var secondhand_color;         // per-theme highest-contrast color (second hand + data fields)
    var isLowPower = false;       // true while the watch is in low-power (sleep) mode
    var burnInProtect = false;    // device requires AMOLED burn-in protection

    // Resolves the active theme from the user's setting and sets the matching
    // colors, but only when the theme actually changes. colorTheme 0-6 pins
    // a fixed color; colorTheme 7 ("Multi") rotates the color by day of week.
    // Returns true when the rendered theme changed.
    function check_for_day_advance(force as Boolean, _now as $.Toybox.Time.Gregorian.Info) as Boolean {
        var target_theme;
        if (mySettings.colorTheme == 7) {
            // Multi: rotate the color by day of week.
            switch (_now.day_of_week) {
                case "Sun": target_theme = 4; break;
                case "Mon": target_theme = 0; break;
                case "Tue": target_theme = 1; break;
                case "Wed": target_theme = 2; break;
                case "Thu": target_theme = 3; break;
                case "Fri": target_theme = 6; break;
                case "Sat": target_theme = 5; break;
                default:    target_theme = 0; break;
            }
        } else {
            // Fixed color chosen in Settings.
            target_theme = mySettings.colorTheme;
        }

        // Nothing changed since the last render: keep the cached background.
        if (!force and target_theme == last_theme) {
            return false;
        }

        // fr55 has an 8-color palette: black, blue, green, cyan, red, magenta,
        // yellow, white. Use palette-exact literals so colors don't quantize to
        // a surprising neighbor (e.g. Graphics.COLOR_BLUE = 0x00AAFF rounds to
        // cyan). No purple in the palette, so Purple uses magenta.
        switch (target_theme) {
            case 0: // Blue
                background_color = 0x0000FF;
                numerals_color = 0x00FFFF; // cyan numerals, white date
                date_color = Graphics.COLOR_WHITE;
                hands_color = Graphics.COLOR_WHITE;
                battery_discharged_color = Graphics.COLOR_ORANGE;
                muted_color = 0x7E84C8;
                accent_color = 0xB6BCEC;
                secondhand_color = 0xDCDFFA;
                break;
            case 1: // Green
                background_color = 0x008000; // darker green on full-color; fr55 quantizes to its palette green
                numerals_color = 0xFFFF00; // yellow numerals (cyan unreadable on green), white date
                date_color = Graphics.COLOR_WHITE;
                hands_color = Graphics.COLOR_WHITE;
                battery_discharged_color = Graphics.COLOR_DK_BLUE;
                muted_color = 0x6FB088;
                accent_color = 0xACDCC0;
                secondhand_color = 0xD6F0E0;
                break;
            case 2: // Purple
                background_color = 0x800080; // muted purple on full-color; fr55 quantizes to magenta
                numerals_color = 0x00FFFF; // cyan numerals, white date
                date_color = Graphics.COLOR_WHITE;
                hands_color = Graphics.COLOR_WHITE;
                battery_discharged_color = Graphics.COLOR_BLUE;
                muted_color = 0xB07EB0;
                accent_color = 0xD8B4D8;
                secondhand_color = 0xECDAEC;
                break;
            case 3: // Red
                background_color = 0xFF0000;
                numerals_color = 0xFFFF00;
                date_color = Graphics.COLOR_WHITE;
                hands_color = Graphics.COLOR_WHITE;
                battery_discharged_color = Graphics.COLOR_GREEN;
                muted_color = 0xE08C8C;
                accent_color = 0xF8C4C4;
                secondhand_color = 0xFFE0E0;
                break;
            case 4: // Yellow (burnished gold)
                background_color = 0xC8A415; // burnished gold on full-color; fr55 quantizes to yellow
                numerals_color = 0x000000;
                date_color = Graphics.COLOR_BLACK;
                hands_color = Graphics.COLOR_BLACK;
                battery_discharged_color = Graphics.COLOR_RED;
                muted_color = 0x6E5A12;
                accent_color = 0x3C3008;
                secondhand_color = 0x201A04;
                break;
            case 5: // Black/Gold (gold -> yellow)
                background_color = 0x000000;
                numerals_color = 0xFFFF00;
                date_color = Graphics.COLOR_WHITE;
                hands_color = Graphics.COLOR_WHITE;
                battery_discharged_color = Graphics.COLOR_PINK;
                muted_color = 0x7A6526;
                accent_color = 0xB89A3A;
                secondhand_color = 0xE8CF6A;
                break;
            case 6: // Black/Silver
                background_color = 0x000000;
                numerals_color = 0xC0C0C0; // silver-grey numerals on full-color; fr55 quantizes to white
                date_color = Graphics.COLOR_WHITE;
                hands_color = Graphics.COLOR_WHITE;
                battery_discharged_color = Graphics.COLOR_ORANGE;
                muted_color = 0x6E7176;
                accent_color = 0xAEB2B8;
                secondhand_color = 0xDEE2E8;
                break;
            default: // invalid colorTheme: recover to Blue
                System.println("error in View!  target_theme = " + target_theme);
                mySettings.colorTheme = 0;
                target_theme = 0;
                background_color = 0x0000FF;
                numerals_color = 0xFFFFFF;
                date_color = Graphics.COLOR_WHITE;
                hands_color = Graphics.COLOR_WHITE;
                battery_discharged_color = Graphics.COLOR_ORANGE;
                muted_color = 0x7E84C8;
                accent_color = 0xB6BCEC;
                secondhand_color = 0xDCDFFA;
        }
        last_theme = target_theme;

        return true;
    }

    function initialize() {
        View.initialize();
        mySettings = new UnderstatedSettings();
        burnInProtect = (System.getDeviceSettings().requiresBurnInProtection == true);
        var _now = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        check_for_day_advance(true, _now);
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        mySettings.loadLocal();
        var _now = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        check_for_day_advance(true, _now);
        return;
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);

        var _now = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        check_for_day_advance(false, _now);

        if (isLowPower and burnInProtect) {
            // AMOLED always-on: burn-in-safe minimal render.
            drawLowPower(dc, _now);
            return;
        }

        drawBackground(dc);
        drawDataFields(dc, _now);
        drawHands(dc, _now.hour, _now.min);

        // Second hand only while awake. In high power onUpdate runs ~1/sec so it
        // ticks; in low power onUpdate is ~1/min (it would freeze) and AMOLED uses
        // the burn-in-safe path above, so it's intentionally omitted there.
        if (!isLowPower and mySettings.showSecondHand()) {
            drawSecondHand(dc, _now.sec);
        }
    }

    // Some devices/firmware (incl. fr55) invoke onPartialUpdate during
    // low-power updates; omitting it was implicated in a low-power crash.
    // This face is minute-resolution, so there's nothing to draw between
    // minutes -- the once-per-minute onUpdate does the full redraw.
    function onPartialUpdate(dc as Dc) as Void {
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
        return;
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
        isLowPower = false;
        WatchUi.requestUpdate();
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
        isLowPower = true;
        WatchUi.requestUpdate();
    }

    // Draws the dial programmatically: a solid fill plus 12 upright Roman
    // numerals. No bitmaps, so it scales to any screen size or shape.
    function drawBackground(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();

        // Fill the whole face with the theme background color.
        dc.setColor(numerals_color, background_color);
        dc.clear();

        var cx = width / 2;
        var cy = height / 2;
        var size = (width < height) ? width : height;
        var r = size * 0.40;

        dc.setColor(numerals_color, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < 12; i += 1) {
            var angle = (i + 1) * 30 * Math.PI / 180; // numeral i+1 at its clock position
            var x = cx + r * Math.sin(angle);
            var y = cy - r * Math.cos(angle);
            dc.drawText(x, y, Graphics.FONT_TINY, NUMERALS[i],
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    // AMOLED always-on (burn-in protection): a mostly-black screen with only a
    // few lit pixels (thin hands + small date), nudged a couple pixels on a slow
    // cycle so nothing stays static. Used only when the device requires it.
    function drawLowPower(dc as Dc, _now as $.Toybox.Time.Gregorian.Info) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var shiftX = (_now.min % 3) - 1;
        var shiftY = ((_now.min / 3) % 3) - 1;
        var ox = width / 2 + shiftX;
        var oy = height / 2 + shiftY;

        var hour = _now.hour;
        var minute = _now.min;
        if (hour > 12) {
            hour -= 12;
        }
        var adjusted_hour = hour + minute.toFloat() / 60;
        var minTheta = (15 - minute) * 6 * Math.PI / 180;
        var hourTheta = (3 - adjusted_hour) * 30 * Math.PI / 180;
        var minLen = width * 0.38;
        var hourLen = width * 0.23;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawLine(ox, oy, ox + Math.cos(minTheta) * minLen, oy - Math.sin(minTheta) * minLen);
        dc.drawLine(ox, oy, ox + Math.cos(hourTheta) * hourLen, oy - Math.sin(hourTheta) * hourLen);

        dc.drawText(width * 0.81 + shiftX, height * 0.43 + shiftY, Graphics.FONT_XTINY,
            Lang.format("$1$", [_now.day]), Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Thin second hand in the theme accent color, slightly longer than the
    // minute hand. Drawn only in high power (see onUpdate).
    function drawSecondHand(dc as Dc, sec as Number) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var theta = (15 - sec) * 6 * Math.PI / 180;
        var len = width * 0.42;
        var secW = Math.round(width / 208.0).toNumber();
        if (secW < 1) { secW = 1; }
        dc.setColor(secondhand_color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(secW);
        dc.drawLine(width / 2, height / 2,
            width / 2 + Math.cos(theta) * len, height / 2 - Math.sin(theta) * len);
    }

    // Data fields at 12/3/6/9, inboard of the numerals and vertically centered
    // on the same radial axis, so a value lines up with its numeral. Content,
    // format, color, and size come from settings. Slot order: 12, 3, 6, 9.
    function drawDataFields(dc as Dc, _now as $.Toybox.Time.Gregorian.Info) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var cx = width / 2;
        var cy = height / 2;
        var size = (width < height) ? width : height;
        var r = size * 0.30;
        var px = [cx, cx + r, cx, cx - r];
        var py = [cy - r, cy, cy + r, cy];

        // Inner edges of the 3 and 9 o'clock numerals (numerals sit at 0.40),
        // less a small gap. The 3 o'clock slot is right-justified to this edge
        // and the 9 o'clock slot left-justified to its edge, so both hug their
        // numeral and any extra width grows inward (toward center) rather than
        // crowding the numeral. The gap matches a centered value's breathing room.
        var numR = size * 0.40;
        var gap = size * 0.055;
        var rightLimit = (cx + numR) - dc.getTextWidthInPixels(NUMERALS[2], Graphics.FONT_TINY) / 2.0 - gap;
        var leftLimit  = (cx - numR) + dc.getTextWidthInPixels(NUMERALS[8], Graphics.FONT_TINY) / 2.0 + gap;
        var tinyH = dc.getFontHeight(Graphics.FONT_TINY);

        for (var i = 0; i < 4; i += 1) {
            var show = mySettings.slotShow[i];
            if (show == 0) { continue; }
            var val = getValueString(show, _now);
            if (val == null) { val = "--"; }
            var color = resolveColor(mySettings.slotCol[i]);
            var font = resolveFont(mySettings.slotSize[i]);
            var fmt = mySettings.slotFmt[i];

            var fh = dc.getFontHeight(font);
            var ih = fh * 0.8;
            var igap = ih * 0.35;

            // Resolve the drawn text and the field's total pixel width.
            var text = val;
            var w;
            if (fmt == 2) {                      // Icon + value
                w = ih + igap + dc.getTextWidthInPixels(val, font);
            } else {
                if (fmt == 1) {                  // Label + value
                    var lbl = getLabelString(show);
                    if (lbl != null) { text = lbl + " " + val; }
                }
                w = dc.getTextWidthInPixels(text, font);
            }

            // Left edge of the field by slot: 12/6 centered, 3 right-justified
            // (hugs III), 9 left-justified (hugs IX).
            var startX;
            if (i == 1)      { startX = rightLimit - w; }
            else if (i == 3) { startX = leftLimit; }
            else             { startX = px[i] - w / 2.0; }

            // VCENTER aligns the font cell, so a font taller than the FONT_TINY
            // numerals leaves its glyphs sitting high; nudge down to put the
            // field's glyphs on the numeral's centerline (zero for FONT_TINY).
            var oy = py[i] + (fh - tinyH) / 2.0;

            if (fmt == 2) {
                drawIcon(dc, show, startX + ih / 2.0, oy, ih, color);
                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                dc.drawText(startX + ih + igap, oy, font, val,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            } else {
                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                dc.drawText(startX, oy, font, text,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }
    }

    // Minimalist programmatic icon glyphs, height h, centered at (cx,cy), in
    // the given color (so they scale and colorize per slot).
    function drawIcon(dc as Dc, show as Number, cx, cy, h, color as Number) as Void {
        var half = h / 2.0;
        var pw = h / 9.0;
        if (pw < 1) { pw = 1; }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(pw);

        if (show == 2 || show == 15) {                 // Battery
            dc.drawRectangle(cx - half, cy - h * 0.28, h * 0.82, h * 0.56);
            dc.fillRectangle(cx - half + h * 0.82, cy - h * 0.12, h * 0.1, h * 0.24);
            dc.fillRectangle(cx - half + h * 0.1, cy - h * 0.16, h * 0.42, h * 0.32);
        } else if (show == 3) {                        // Heart
            var rr = h * 0.26;
            dc.fillCircle(cx - rr * 0.75, cy - h * 0.12, rr);
            dc.fillCircle(cx + rr * 0.75, cy - h * 0.12, rr);
            dc.fillPolygon([[cx - half * 0.92, cy - h * 0.06], [cx + half * 0.92, cy - h * 0.06], [cx, cy + half]]);
        } else if (show == 14) {                       // Thermometer (temperature)
            dc.drawLine(cx, cy - half, cx, cy + h * 0.18);
            dc.fillCircle(cx, cy + h * 0.3, h * 0.17);
        } else if (show == 17) {                        // Sun (weather temp)
            dc.fillCircle(cx, cy, h * 0.22);
            for (var a = 0; a < 8; a += 1) {
                var th = a * 45 * Math.PI / 180.0;
                dc.drawLine(cx + Math.cos(th) * h * 0.32, cy + Math.sin(th) * h * 0.32,
                            cx + Math.cos(th) * half, cy + Math.sin(th) * half);
            }
        } else if (show == 18) {                        // Cloud (weather condition)
            dc.fillRectangle(cx - h * 0.38, cy, h * 0.66, h * 0.18);
            dc.fillCircle(cx - h * 0.2, cy, h * 0.16);
            dc.fillCircle(cx + h * 0.02, cy - h * 0.08, h * 0.2);
            dc.fillCircle(cx + h * 0.24, cy, h * 0.14);
        } else if (show == 16) {                        // Bell (notifications)
            dc.fillPolygon([[cx - h * 0.28, cy + h * 0.16], [cx - h * 0.2, cy - h * 0.12],
                            [cx + h * 0.2, cy - h * 0.12], [cx + h * 0.28, cy + h * 0.16]]);
            dc.fillCircle(cx, cy - h * 0.18, h * 0.07);
            dc.fillCircle(cx, cy + h * 0.3, h * 0.07);
        } else if (show == 12) {                        // Mountain (elevation)
            dc.fillPolygon([[cx - half, cy + half], [cx - h * 0.12, cy - h * 0.18], [cx + h * 0.18, cy + half]]);
            dc.fillPolygon([[cx - h * 0.05, cy + half], [cx + h * 0.2, cy - half], [cx + half, cy + half]]);
        } else if (show == 9) {                         // Move bar (bars)
            dc.fillRectangle(cx - half, cy + h * 0.06, h * 0.2, h * 0.34);
            dc.fillRectangle(cx - half + h * 0.3, cy - h * 0.1, h * 0.2, h * 0.5);
            dc.fillRectangle(cx - half + h * 0.6, cy - h * 0.28, h * 0.2, h * 0.68);
        } else if (show == 7) {                         // Stairs (floors)
            dc.fillRectangle(cx - half, cy + h * 0.2, h * 0.33, h * 0.2);
            dc.fillRectangle(cx - half + h * 0.2, cy, h * 0.33, h * 0.4);
            dc.fillRectangle(cx - half + h * 0.4, cy - h * 0.2, h * 0.4, h * 0.6);
        } else if (show == 5) {                         // Flame (calories)
            dc.fillPolygon([[cx, cy - half], [cx + h * 0.3, cy], [cx + h * 0.18, cy + half],
                            [cx - h * 0.18, cy + half], [cx - h * 0.3, cy]]);
        } else if (show == 11) {                        // Droplet (pulse ox)
            dc.fillPolygon([[cx, cy - half], [cx + h * 0.3, cy + h * 0.1], [cx - h * 0.3, cy + h * 0.1]]);
            dc.fillCircle(cx, cy + h * 0.15, h * 0.3);
        } else if (show == 6) {                         // Pin (distance)
            dc.fillCircle(cx, cy - h * 0.1, h * 0.28);
            dc.fillPolygon([[cx - h * 0.22, cy], [cx + h * 0.22, cy], [cx, cy + half]]);
        } else if (show == 1) {                         // Calendar (date)
            dc.drawRectangle(cx - half, cy - h * 0.32, h, h * 0.72);
            dc.fillRectangle(cx - half, cy - h * 0.32, h, h * 0.2);
        } else if (show == 10 || show == 13) {          // Gauge (stress / pressure)
            dc.drawArc(cx, cy + h * 0.15, half, Graphics.ARC_CLOCKWISE, 200, -20);
            dc.drawLine(cx, cy + h * 0.15, cx + h * 0.28, cy - h * 0.2);
        } else if (show == 4) {                         // Foot (steps)
            dc.fillCircle(cx, cy + h * 0.05, h * 0.27);
            dc.fillCircle(cx + h * 0.22, cy - h * 0.22, h * 0.1);
        } else if (show == 8) {                         // Lightning (active minutes)
            dc.fillPolygon([[cx + h * 0.12, cy - half], [cx - h * 0.28, cy + h * 0.05],
                            [cx - h * 0.02, cy + h * 0.05], [cx - h * 0.12, cy + half],
                            [cx + h * 0.28, cy - h * 0.05], [cx + h * 0.02, cy - h * 0.05]]);
        } else {                                        // generic dot
            dc.fillCircle(cx, cy, h * 0.2);
        }
        dc.setPenWidth(1);
    }

    function resolveColor(id as Number) as Number {
        switch (id) {
            case 0:  return 0xFFFFFF;  // White
            case 1:  return 0xAAAAAA;  // Light gray
            case 2:  return 0xFF0000;  // Red
            case 3:  return 0xFF5500;  // Orange
            case 4:  return 0xFFFF00;  // Yellow
            case 5:  return 0x00FF00;  // Green
            case 6:  return 0x00FFFF;  // Cyan
            case 7:  return 0x0000FF;  // Blue
            case 8:  return 0xFF00FF;  // Magenta
            case 9:  return 0xFFAAFF;  // Pink
            case 10: return 0x000000;  // Black
            case 11: return accent_color;        // Accent (theme, bold)
            case 12: return muted_color;         // Muted (theme, soft)
            case 13: return secondhand_color;    // Second hand (theme, highest contrast)
            default: return 0xFFFFFF;
        }
    }

    function resolveFont(id as Number) {
        switch (id) {
            case 0:  return Graphics.FONT_XTINY;   // Tiny
            case 2:  return Graphics.FONT_SMALL;   // Medium
            case 3:  return Graphics.FONT_MEDIUM;  // Large
            default: return Graphics.FONT_TINY;    // Small
        }
    }

    // Newest sample value from a SensorHistory iterator, or null.
    function newestData(iter) {
        if (iter == null) { return null; }
        var s = iter.next();
        return (s != null) ? s.data : null;
    }

    function fmtInt(d) {
        return (d != null) ? d.format("%d") : null;
    }

    function tempStr(c, ds) {
        var t = c;
        if (ds.temperatureUnits == System.UNIT_STATUTE) { t = c * 9.0 / 5.0 + 32.0; }
        return t.format("%d") + "°";
    }

    function getValueString(show as Number, _now as $.Toybox.Time.Gregorian.Info) {
        var ds = System.getDeviceSettings();
        if (show == 1) { return _now.day.toString(); }                          // Date
        if (show == 3) {                                                         // Heart rate
            var ai = Activity.getActivityInfo();
            return (ai != null && ai.currentHeartRate != null) ? ai.currentHeartRate.toString() : null;
        }
        if (show == 15) { return System.getSystemStats().battery.format("%d"); } // Device battery
        if (show == 16) { return ds.notificationCount.toString(); }             // Notifications

        if (Toybox has :SensorHistory) {
            if (show == 2 && SensorHistory has :getBodyBatteryHistory) {
                return fmtInt(newestData(SensorHistory.getBodyBatteryHistory({:period=>1, :order=>SensorHistory.ORDER_NEWEST_FIRST})));
            }
            if (show == 10 && SensorHistory has :getStressHistory) {
                return fmtInt(newestData(SensorHistory.getStressHistory({:period=>1, :order=>SensorHistory.ORDER_NEWEST_FIRST})));
            }
            if (show == 11 && SensorHistory has :getOxygenSaturationHistory) {
                return fmtInt(newestData(SensorHistory.getOxygenSaturationHistory({:period=>1, :order=>SensorHistory.ORDER_NEWEST_FIRST})));
            }
            if (show == 12 && SensorHistory has :getElevationHistory) {
                return fmtInt(newestData(SensorHistory.getElevationHistory({:period=>1, :order=>SensorHistory.ORDER_NEWEST_FIRST})));
            }
            if (show == 13 && SensorHistory has :getPressureHistory) {
                var p = newestData(SensorHistory.getPressureHistory({:period=>1, :order=>SensorHistory.ORDER_NEWEST_FIRST}));
                return (p != null) ? (p / 100.0).format("%d") : null;            // Pa -> hPa
            }
            if (show == 14 && SensorHistory has :getTemperatureHistory) {
                var t = newestData(SensorHistory.getTemperatureHistory({:period=>1, :order=>SensorHistory.ORDER_NEWEST_FIRST}));
                return (t != null) ? tempStr(t, ds) : null;
            }
        }

        if (show >= 4 && show <= 9) {                                            // ActivityMonitor
            var am = ActivityMonitor.getInfo();
            if (show == 4) { return (am.steps != null) ? am.steps.toString() : null; }
            if (show == 5) { return (am.calories != null) ? am.calories.toString() : null; }
            if (show == 6) {
                if (am.distance == null) { return null; }
                var km = am.distance / 100000.0;
                return (ds.distanceUnits == System.UNIT_STATUTE) ? (km * 0.621371).format("%.1f") : km.format("%.1f");
            }
            if (show == 7) { return (am.floorsClimbed != null) ? am.floorsClimbed.toString() : null; }
            if (show == 8) {
                if (am has :activeMinutesDay && am.activeMinutesDay != null) { return am.activeMinutesDay.total.toString(); }
                return null;
            }
            if (show == 9) { return (am.moveBarLevel != null) ? am.moveBarLevel.toString() : null; }
        }

        if ((show == 17 || show == 18) && (Toybox has :Weather)) {               // Weather
            var cc = Weather.getCurrentConditions();
            if (cc != null) {
                if (show == 17 && cc.temperature != null) { return tempStr(cc.temperature, ds); }
                if (show == 18 && cc.condition != null) { return conditionStr(cc.condition); }
            }
        }
        return null;
    }

    function getLabelString(show as Number) {
        switch (show) {
            case 1:  return "DATE";
            case 2:  return "BB";
            case 3:  return "HR";
            case 4:  return "STEP";
            case 5:  return "CAL";
            case 6:  return "DIST";
            case 7:  return "FLR";
            case 8:  return "ACT";
            case 9:  return "MOVE";
            case 10: return "STR";
            case 11: return "SPO2";
            case 12: return "ELEV";
            case 13: return "BARO";
            case 14: return "TEMP";
            case 15: return "BATT";
            case 16: return "NOTIF";
            case 17: return "WX";
            case 18: return "WX";
            default: return null;
        }
    }

    function conditionStr(condition as Number) {
        switch (condition) {
            case Weather.CONDITION_CLEAR:
            case Weather.CONDITION_MOSTLY_CLEAR:
            case Weather.CONDITION_FAIR:           return "Clear";
            case Weather.CONDITION_PARTLY_CLOUDY:
            case Weather.CONDITION_MOSTLY_CLOUDY:
            case Weather.CONDITION_THIN_CLOUDS:    return "P.Cldy";
            case Weather.CONDITION_CLOUDY:         return "Cloudy";
            case Weather.CONDITION_RAIN:
            case Weather.CONDITION_LIGHT_RAIN:
            case Weather.CONDITION_HEAVY_RAIN:
            case Weather.CONDITION_SHOWERS:        return "Rain";
            case Weather.CONDITION_SNOW:
            case Weather.CONDITION_LIGHT_SNOW:
            case Weather.CONDITION_HEAVY_SNOW:     return "Snow";
            case Weather.CONDITION_THUNDERSTORMS:  return "Storm";
            case Weather.CONDITION_FOG:
            case Weather.CONDITION_HAZY:           return "Fog";
            case Weather.CONDITION_WINDY:          return "Windy";
            default: return "--";
        }
    }

    function drawHands(dc as Dc, hour as Number, minute as Number) as Void {
        var WIDTH = dc.getWidth();
        var HEIGHT = dc.getHeight();

        var ox = WIDTH / 2;
        var oy = HEIGHT / 2;
        var offset = WIDTH / 25;
        var minTheta = (15-minute) * 6 * Math.PI/180;
        if (hour > 12) {
          hour -= 12;
        }
        var adjusted_hour = hour + minute.toFloat() / 60;
        var systemStats = System.getSystemStats();
        var batteryPercentage = systemStats.battery/100;

        var hourTheta = (3 - adjusted_hour)* 30 * Math.PI/180;
        var minHandLength = WIDTH * 0.38;
        var maxHourHandLength = WIDTH * 0.23;
        var totalHourHandLength = maxHourHandLength + offset;
        var unchargedHourHandLength = totalHourHandLength * (1-batteryPercentage);

        var minHandStartX = ox - Math.cos(minTheta)*offset;
        var minHandStartY = oy + Math.sin(minTheta)*offset;

        var minHandEndX = ox + Math.cos(minTheta)*minHandLength;
        var minHandEndY = oy - Math.sin(minTheta)*minHandLength;

        var hourHandStartX = ox - Math.cos(hourTheta)*offset;
        var hourHandStartY = oy + Math.sin(hourTheta)*offset;

        var maxHourHandEndX = ox + Math.cos(hourTheta)*maxHourHandLength;
        var maxHourHandEndY = oy - Math.sin(hourTheta)*maxHourHandLength;
        var unchargedHourHandEndX = hourHandStartX + Math.cos(hourTheta)*unchargedHourHandLength;
        var unchargedHourHandEndY = hourHandStartY - Math.sin(hourTheta)*unchargedHourHandLength;

        // Hand widths scale with screen size (2 px minute / 3 px hour on the
        // fr55's 208 px screen), floored so they're never thinner than that.
        var minW = Math.round(WIDTH * 2.0 / 208.0).toNumber();
        if (minW < 2) { minW = 2; }
        var hourW = Math.round(WIDTH * 3.0 / 208.0).toNumber();
        if (hourW < 3) { hourW = 3; }

        // Battery gauge: the "discharged" portion of the hour hand, drawn at the
        // same width as the rest of the hour hand.
        dc.setColor(battery_discharged_color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(hourW);
        dc.drawLine(hourHandStartX, hourHandStartY, unchargedHourHandEndX, unchargedHourHandEndY);

        dc.setColor(hands_color, Graphics.COLOR_TRANSPARENT);

        dc.setPenWidth(minW);
        dc.drawLine(minHandStartX, minHandStartY, minHandEndX, minHandEndY);

        dc.setPenWidth(hourW);
        dc.drawLine(unchargedHourHandEndX, unchargedHourHandEndY, maxHourHandEndX, maxHourHandEndY);
    }
}

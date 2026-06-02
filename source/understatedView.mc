import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Math;


class UnderstatedView extends WatchUi.View {
    // Upright Roman numerals, index i -> the (i+1) o'clock mark.
    private const NUMERALS = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"];

    var mySettings;
    var last_theme = -1;
    var background_color;
    var numerals_color;
    var date_color;
    var hands_color;
    var battery_discharged_color;

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
                numerals_color = 0xFFFFFF;
                date_color = Graphics.COLOR_WHITE;
                hands_color = Graphics.COLOR_WHITE;
                battery_discharged_color = Graphics.COLOR_ORANGE;
                break;
            case 1: // Green
                background_color = 0x00FF00;
                numerals_color = 0xFFFFFF;
                date_color = Graphics.COLOR_WHITE;
                hands_color = Graphics.COLOR_WHITE;
                battery_discharged_color = Graphics.COLOR_DK_BLUE;
                break;
            case 2: // Purple (-> magenta on fr55's palette)
                background_color = 0xFF00FF;
                numerals_color = 0xFFFFFF;
                date_color = Graphics.COLOR_WHITE;
                hands_color = Graphics.COLOR_WHITE;
                battery_discharged_color = Graphics.COLOR_BLUE;
                break;
            case 3: // Red
                background_color = 0xFF0000;
                numerals_color = 0xFFFF00;
                date_color = Graphics.COLOR_WHITE;
                hands_color = Graphics.COLOR_WHITE;
                battery_discharged_color = Graphics.COLOR_GREEN;
                break;
            case 4: // Yellow
                background_color = 0xFFFF00;
                numerals_color = 0x000000;
                date_color = Graphics.COLOR_BLACK;
                hands_color = Graphics.COLOR_BLACK;
                battery_discharged_color = Graphics.COLOR_RED;
                break;
            case 5: // Black/Gold (gold -> yellow)
                background_color = 0x000000;
                numerals_color = 0xFFFF00;
                date_color = Graphics.COLOR_WHITE;
                hands_color = Graphics.COLOR_WHITE;
                battery_discharged_color = Graphics.COLOR_PINK;
                break;
            case 6: // Black/Silver (silver -> white)
                background_color = 0x000000;
                numerals_color = 0xFFFFFF;
                date_color = Graphics.COLOR_WHITE;
                hands_color = Graphics.COLOR_WHITE;
                battery_discharged_color = Graphics.COLOR_ORANGE;
                break;
            default: // invalid colorTheme: recover to Blue and persist the fix
                System.println("error in View!  target_theme = " + target_theme);
                mySettings.colorTheme = 0;
                mySettings.saveLocal();
                target_theme = 0;
                background_color = 0x0000FF;
                numerals_color = 0xFFFFFF;
                date_color = Graphics.COLOR_WHITE;
                hands_color = Graphics.COLOR_WHITE;
                battery_discharged_color = Graphics.COLOR_ORANGE;
        }
        last_theme = target_theme;

        return true;
    }

    function initialize() {
        View.initialize();
        mySettings = new UnderstatedSettings();
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

        drawBackground(dc);

        var _hour = _now.hour;
        var _minute = _now.min;
        var _dateString = Lang.format("$1$", [_now.day]);

        drawDate(dc, _dateString);
        drawHands(dc, _hour, _minute);
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
        return;
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
        return;
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

    function drawDate(dc as Dc, dateString as String) as Void {
        var WIDTH = dc.getWidth();
        var HEIGHT = dc.getHeight();

        dc.setColor(date_color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(WIDTH * 0.81, HEIGHT * 0.43, Graphics.FONT_SMALL, dateString, Graphics.TEXT_JUSTIFY_CENTER);
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

        // Battery gauge: the "discharged" portion of the hour hand.
        dc.setColor(battery_discharged_color, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(hourHandStartX, hourHandStartY, unchargedHourHandEndX, unchargedHourHandEndY);

        dc.setColor(hands_color, Graphics.COLOR_TRANSPARENT);

        dc.setPenWidth(2);
        dc.drawLine(minHandStartX, minHandStartY, minHandEndX, minHandEndY);

        dc.setPenWidth(3);
        dc.drawLine(unchargedHourHandEndX, unchargedHourHandEndY, maxHourHandEndX, maxHourHandEndY);
    }
}

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Math;


class UnderstatedView extends WatchUi.View {
    private const BG_BLUE = $.Rez.Drawables.id_bg_blue;
    private const BG_GREEN = $.Rez.Drawables.id_bg_green;
    private const BG_PURPLE = $.Rez.Drawables.id_bg_purple;
    private const BG_RED = $.Rez.Drawables.id_bg_red;
    private const BG_YELLOW = $.Rez.Drawables.id_bg_yellow;
    private const BG_BLACK_GOLD = $.Rez.Drawables.id_bg_black_gold;
    private const BG_BLACK_SILVER = $.Rez.Drawables.id_bg_black_silver;

    // var use_bitmap_boolean;
    var background_bitmap;
    // var background_color;
    // var numerals_color;
    var mySettings;
    var last_theme = -1;
    var date_color;
    var hands_color;
    var battery_discharged_color;

    // Resolves the active theme from the user's setting and loads the matching
    // background, but only when the theme actually changes. colorTheme 0-6 pins
    // a fixed color; colorTheme 7 ("Multi") rotates the color by day of week.
    // Returns true when the rendered theme changed (caller should clear + redraw).
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

        switch (target_theme) {
            case 0:
                background_bitmap = WatchUi.loadResource(BG_BLUE) as BitmapResource;
                date_color = Graphics.COLOR_WHITE;
                hands_color = Graphics.COLOR_WHITE;
                battery_discharged_color = Graphics.COLOR_ORANGE;
                break;
            case 1:
                background_bitmap = WatchUi.loadResource(BG_GREEN) as BitmapResource;
                date_color = Graphics.COLOR_WHITE;
                hands_color = Graphics.COLOR_WHITE;
                battery_discharged_color = Graphics.COLOR_DK_BLUE;
                break;
            case 2:
                background_bitmap = WatchUi.loadResource(BG_PURPLE) as BitmapResource;
                date_color = Graphics.COLOR_WHITE;
                hands_color = Graphics.COLOR_WHITE;
                battery_discharged_color = Graphics.COLOR_BLUE;
                break;
            case 3:
                background_bitmap = WatchUi.loadResource(BG_RED) as BitmapResource;
                date_color = Graphics.COLOR_WHITE;
                hands_color = Graphics.COLOR_WHITE;
                battery_discharged_color = Graphics.COLOR_GREEN;
                break;
            case 4:
                background_bitmap = WatchUi.loadResource(BG_YELLOW) as BitmapResource;
                date_color = Graphics.COLOR_BLACK;
                hands_color = Graphics.COLOR_BLACK;
                battery_discharged_color = Graphics.COLOR_RED;
                break;
            case 5:
                background_bitmap = WatchUi.loadResource(BG_BLACK_GOLD) as BitmapResource;
                date_color = Graphics.COLOR_WHITE;
                hands_color = Graphics.COLOR_WHITE;
                battery_discharged_color = Graphics.COLOR_PINK;
                break;
            case 6:
                background_bitmap = WatchUi.loadResource(BG_BLACK_SILVER) as BitmapResource;
                date_color = Graphics.COLOR_WHITE;
                hands_color = Graphics.COLOR_WHITE;
                battery_discharged_color = Graphics.COLOR_ORANGE;
                break;
            default: // invalid colorTheme: recover to Blue and persist the fix
                System.println("error in View!  target_theme = " + target_theme);
                mySettings.colorTheme = 0;
                mySettings.saveLocal();
                target_theme = 0;
                background_bitmap = WatchUi.loadResource(BG_BLUE) as BitmapResource;
                date_color = Graphics.COLOR_WHITE;
                hands_color = Graphics.COLOR_WHITE;
                battery_discharged_color = Graphics.COLOR_ORANGE;
        }
        last_theme = target_theme;

        return true;
    }
    function initialize() {
        //System.println("view - initialize");
        View.initialize();
        //read settings
        mySettings=new UnderstatedSettings();
        var _now = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        check_for_day_advance(true, _now);
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        //System.println("view - onLayout");
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        //System.println("view - onShow");
        mySettings.loadLocal();
        var _now = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        check_for_day_advance(true, _now);
        return;
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // System.println("onUpdate: background_bitmap = " + background_bitmap);
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);

        var _now = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        if (check_for_day_advance(false, _now)) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();
        }

        dc.drawBitmap(0, 0, background_bitmap);

        var _hour = _now.hour;
        var _minute = _now.min;
        var _dateString = Lang.format("$1$", [_now.day]);

        drawDate(dc, _dateString);
        drawHands(dc, _hour, _minute);

        // add date
        // var dateLabel = View.findDrawableById("DateLabel") as Text;
        // dateLabel.setText(getDate());

        // debugging lines
        // drawReferenceLines(dc);
    }

    function onPartialUpdate(dc as Dc) as Void {
        // System.println("onPartialUpdate");
        onUpdate(dc);
    }
    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
        // System.println("onHide");
        return;
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
        // System.println("onExitSleep");
        // check_for_day_advance(false);
        return;
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
        // System.println("onEnterSleep");
        return;
    }

    // function drawBackground(dc as Dc) as Void {
    //     var WIDTH = dc.getWidth();
    //     var HEIGHT = dc.getHeight();

    //     var ox = WIDTH / 2;
    //     var oy = HEIGHT / 2;
    //     var r_bg = ox; // radius of the background circle
    //     var r_dial = oy; // radius of the roman numerals
    //     if (oy > ox) {
    //         r_bg = oy;
    //         r_dial = ox;
    //     }

    //     // draw background
    //     dc.setColor(date_color, background_color);
    //     dc.fillCircle(ox, oy, r_bg);

    //     // draw roman numerals
    //     dc.drawRadialText(0, 0,
    //         Graphics.FONT_SMALL, "I",
    //         Graphics.TEXT_JUSTIFY_CENTER, 30, r_dial,
    //         Graphics.RadialTextDirection.RADIAL_TEXT_DIRECTION_COUNTER_CLOCKWISE
    //     );
    // }

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
        // dc.drawText(WIDTH*0.25, HEIGHT*0.25, Graphics.FONT_SMALL, hour, Graphics.TEXT_JUSTIFY_CENTER);
        // dc.drawText(WIDTH*0.50, HEIGHT*0.25, Graphics.FONT_SMALL, minute, Graphics.TEXT_JUSTIFY_CENTER);
        // dc.drawText(WIDTH*0.75, HEIGHT*0.25, Graphics.FONT_SMALL, adjusted_hour, Graphics.TEXT_JUSTIFY_CENTER);
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

        // dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        // dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.setColor(battery_discharged_color, Graphics.COLOR_TRANSPARENT);

        dc.drawLine(hourHandStartX, hourHandStartY, unchargedHourHandEndX, unchargedHourHandEndY);

        dc.setColor(hands_color, Graphics.COLOR_TRANSPARENT);
        // dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        dc.setPenWidth(2);
        dc.drawLine(minHandStartX, minHandStartY, minHandEndX, minHandEndY);

        dc.setPenWidth(3);
        dc.drawLine(unchargedHourHandEndX, unchargedHourHandEndY, maxHourHandEndX, maxHourHandEndY);

    }

    // function drawReferenceLines(dc as Dc) as Void {
    //     var WIDTH = dc.getWidth();
    //     var HEIGHT = dc.getHeight();

    //     dc.setPenWidth(1);

    //     dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    //     dc.drawRectangle(0.2 * WIDTH, 0.1 * HEIGHT, 0.6 * WIDTH, 0.8 * HEIGHT);
    //     dc.drawRectangle(0.15 * WIDTH, 0.15 * HEIGHT, 0.7 * WIDTH, 0.7 * HEIGHT);
    //     dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
    //     dc.drawRectangle(0.1 * WIDTH, 0.2 * HEIGHT, 0.8 * WIDTH, 0.6 * HEIGHT);
    //     dc.drawRectangle(0.05 * WIDTH, 0.3 * HEIGHT, 0.9 * WIDTH, 0.4 * HEIGHT);

    //     dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    //     dc.fillRectangle(0, 0.25 * HEIGHT, WIDTH, 1);
    //     dc.fillRectangle(0, 0.5 * HEIGHT, WIDTH, 1);
    //     dc.fillRectangle(0, 0.75 * HEIGHT, WIDTH, 1);
    //     dc.fillRectangle(0.25 * WIDTH, 0, 1, HEIGHT);

    //     dc.fillRectangle(0.1 * WIDTH, 0, 1, HEIGHT);
    //     dc.fillRectangle(0.9 * WIDTH, 0, 1, HEIGHT);

    //     dc.fillRectangle(0.5 * WIDTH, 0, 1, HEIGHT);
    //     dc.fillRectangle(0.75 * WIDTH, 0, 1, HEIGHT);

    //     dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
    //     dc.fillRectangle(0.3333 * WIDTH, 0, 1, HEIGHT);
    //     dc.fillRectangle(0.6666 * WIDTH, 0, 1, HEIGHT);
    // }
}

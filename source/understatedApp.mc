import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;

class UnderstatedApp extends Application.AppBase {
    var view=null;
    var delegate=null;

    function initialize() {
        AppBase.initialize();
    }

    function onSettingsChanged() {
        if(view!=null && view.mySettings!=null) {
            view.mySettings.loadLocal();
            var _now = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
            view.check_for_day_advance(true, _now);
            WatchUi.requestUpdate();
        }
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        view = new UnderstatedView();
        return [ view ];
    }
    // No getSettingsView: settings are configured from the phone (Garmin
    // Connect app) via the Connect IQ app-settings form, not on the device.
}

function getApp() as UnderstatedApp {
    return Application.getApp() as UnderstatedApp;
}
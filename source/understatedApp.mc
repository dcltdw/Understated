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
        System.println("settings changed!");
        if(view!=null) {
            view.mySettings.loadLocal();
            System.println("view colorTheme: " + view.mySettings.colorTheme);
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
    function getSettingsView() {
        var setView=new UnderstatedSettingsMenu();
        // return [setView, new UnderstatedSettingsMenuDelegate(setView)]  as Array<Views or InputDelegates>;
        return [setView, new UnderstatedSettingsMenuDelegate(setView)];
    }  


}

function getApp() as UnderstatedApp {
    return Application.getApp() as UnderstatedApp;
}
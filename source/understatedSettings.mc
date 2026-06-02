import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;


class UnderstatedSettings {
    var colorTheme = 0 as Number;
    var hasProperties = false;

    function initialize() {
        hasProperties=(Toybox.Application has :Properties);
        loadLocal();    //on-device settings
    }

    // load local settings. from Application.Storage
    function loadLocal() {
        colorTheme=Application.Storage.getValue("colorTheme");
        if(colorTheme==null) {colorTheme=0;}
    }

    //save changes to on device setting
    function saveLocal() {
        Application.Storage.setValue("colorTheme",colorTheme);
    }
}


class UnderstatedSettingsMenu extends WatchUi.Menu2 {
  var viewSettings=new UnderstatedSettings();

  function initialize() {
    viewSettings.loadLocal();

    var currentColor = "";
    switch(viewSettings.colorTheme) {
      case 0:
        currentColor = "Blue";
        break;
      case 1:
        currentColor = "Green";
        break;
      case 2:
        currentColor = "Purple";
        break;
      case 3:
        currentColor = "Red";
        break;
      case 4:
        currentColor = "Yellow";
        break;
      case 5:
        currentColor = "Black/Gold";
        break;
      case 6:
        currentColor = "Black/Silver";
        break;
      case 7:
        currentColor = "Multi";
        break;
      default: // recover from errors
        System.println("settings - init error!  colorTheme = " + viewSettings.colorTheme);
        currentColor = "Blue";
        viewSettings.colorTheme = 0;
        viewSettings.saveLocal();
    }

    Menu2.initialize(null);
    Menu2.setTitle("Settings");

    Menu2.addItem(new WatchUi.MenuItem("Color", currentColor, "colorTheme", null));

  }
}

class UnderstatedSettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
	var view=null;

  function initialize(v) {
      Menu2InputDelegate.initialize();
      view=v;
  }
    
  function onSelect(item) {
    var id=item.getId();
      var colorNames = ["Blue", "Green", "Purple", "Red", "Yellow", "Black/Gold", "Black/Silver", "Multi"];

    if(id.equals("colorTheme")) {
      view.viewSettings.colorTheme=(view.viewSettings.colorTheme + 1)%8;
      item.setSubLabel(colorNames[view.viewSettings.colorTheme]);
    }   	
	}
    
  function onBack() {
    view.viewSettings.saveLocal();
    WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
  }

}	

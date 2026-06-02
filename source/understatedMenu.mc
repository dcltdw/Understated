// using Toybox.WatchUi;
// using Toybox.System;

// class SettingsMenu2 extends WatchUi.Menu2 {

//     function initialize() {
//         Menu2.initialize({:title=>"Settings"});
//     }

// }

// class MyMenu2InputDelegate extends WatchUi.Menu2InputDelegate {
//     function initialize() {
//         Menu2InputDelegate.initialize();
//     }

//     function onSelect(item) {
//         System.println(item.getId());
//     }
// }

// class MyBehaviorDelegate extends WatchUi.BehaviorDelegate {
//     function initialize() {
//         BehaviorDelegate.initialize();
//     }

//     function onMenu() {
//         var menu = new WatchUi.Menu2({:title=>"My Menu2"});
//         var delegate;
//         menu.addItem(
//             new MenuItem(
//                 "Item 1 Label",
//                 "Item 1 subLabel",
//                 "itemOneId",
//                 {}
//             )
//         );
//         menu.addItem(
//             new MenuItem(
//                 "Item 2 Label",
//                 "Item 2 subLabel",
//                 "itemTwoId",
//                 {}
//             )
//         );
//         delegate = new MyMenu2InputDelegate(); // a WatchUi.Menu2InputDelegate
//         WatchUi.pushView(menu, delegate, WatchUi.SLIDE_IMMEDIATE);
//         return true;
//     }
// }
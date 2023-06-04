//
// Copyright 2023 by your name or organization
//

import Toybox.Application;
import Toybox.BluetoothLowEnergy;
import Toybox.Lang;
import Toybox.WatchUi;

class BrakeMonitorApp extends Application.AppBase {

    private var _profileManager as BrakeProfileManager?;
    private var _bleDelegate as BrakeDelegate?;
    private var _brakeDeviceManager as BrakeDeviceManager?;

    public function initialize() {
        AppBase.initialize();
    }

    public function onStart(state as Dictionary?) as Void {
        _profileManager = new $.BrakeProfileManager();
        _bleDelegate = new $.BrakeDelegate(_profileManager as BrakeProfileManager);
        _brakeDeviceManager = new $.BrakeDeviceManager(_bleDelegate as BrakeDelegate, _profileManager as BrakeProfileManager);

        BluetoothLowEnergy.setDelegate(_bleDelegate as BrakeDelegate);
        (_profileManager as BrakeProfileManager).registerProfiles();
        (_brakeDeviceManager as BrakeDeviceManager).start();
    }

    public function onStop(state as Dictionary?) as Void {
        _brakeDeviceManager = null;
        _bleDelegate = null;
        _profileManager = null;
    }

    public function getInitialView() as Array<Views or InputDelegates>? {
        if (_brakeDeviceManager != null) {
            return [new $.BrakeMonitorView(_brakeDeviceManager)] as Array<Views>;
        }
        return null;
    }
}

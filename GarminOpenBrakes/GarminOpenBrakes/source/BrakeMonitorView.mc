//
// Copyright 2023 by your name or organization
//

import Toybox.Activity;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

class BrakeMonitorView extends WatchUi.SimpleDataField {
    private var _tick as Number;
    private var _brakeDeviceManager as BrakeDeviceManager;

    public function initialize(brakeDeviceManager as BrakeDeviceManager) {
        SimpleDataField.initialize();
        label = "Brake Monitor";
        _brakeDeviceManager = brakeDeviceManager;
        _tick = 0;
    }

    public function compute(info as Info) as Numeric or Duration or String or Null {
        _tick++;

        if (_tick > 1) {
            _brakeDeviceManager.requestTemperature();
            _brakeDeviceManager.requestForce();
            _brakeDeviceManager.requestRPM();
            _tick = 0;
        }

    }

}

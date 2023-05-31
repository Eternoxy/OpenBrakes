//
// Copyright 2023 by Your Name or Company.
// Subject to your License Agreement and
// Application Developer Agreement.
//

import Toybox.Activity;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

class OpenBrakesDataFieldView extends WatchUi.SimpleDataField {
    private var _deviceManager as OpenBrakesDeviceManager;

    //! Set the label of the data field here
    //! @param deviceManager The device manager
    public function initialize(deviceManager as OpenBrakesDeviceManager) {
        SimpleDataField.initialize();
        label = "OpenBrakes";
        _deviceManager = deviceManager;
    }

    //! Display the received sensor data
    //! @param info The updated Activity.Info object
    //! @return Value to display in the data field
    public function compute(info as Info) as Numeric or Duration or String or Null {
        // Retrieve the data from the device manager
        var brakeForce = _deviceManager.getBrakeForce();
        var brakeTemperature = _deviceManager.getBrakeTemperature();
        var wheelRpm = _deviceManager.getWheelRpm();

        // Format the data for display
        return "BF: " + brakeForce + " BT: " + brakeTemperature + "°C RPM: " + wheelRpm;
    }
}

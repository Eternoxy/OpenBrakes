//
// Copyright 2023 by Your Name or Company.
// Subject to your License Agreement and
// Application Developer Agreement.
//

import Toybox.Application;
import Toybox.BluetoothLowEnergy;
import Toybox.Lang;
import Toybox.WatchUi;

class OpenBrakesApp extends Application.AppBase {
    private var _profileManager as OpenBrakesProfileManager?;
    private var _bleDelegate as OpenBrakesDelegate?;
    private var _deviceManager as OpenBrakesDeviceManager?;

    //! Constructor
    public function initialize() {
        AppBase.initialize();
    }

    //! Handle app startup
    //! @param state Startup arguments
    public function onStart(state as Dictionary?) as Void {
        _profileManager = new OpenBrakesProfileManager();
        _bleDelegate = new OpenBrakesDelegate(_profileManager as OpenBrakesProfileManager);
        _deviceManager = new OpenBrakesDeviceManager(_bleDelegate as OpenBrakesDelegate, _profileManager as OpenBrakesProfileManager);

        BluetoothLowEnergy.setDelegate(_bleDelegate as OpenBrakesDelegate);
        (_profileManager as OpenBrakesProfileManager).registerProfiles();
        (_deviceManager as OpenBrakesDeviceManager).start();
    }

    //! Handle app shutdown
    //! @param state Shutdown arguments
    public function onStop(state as Dictionary?) as Void {
        _deviceManager = null;
        _bleDelegate = null;
        _profileManager = null;
    }

    //! Return the initial view for the app
    //! @return Array [View]
    public function getInitialView() as Array<Views or InputDelegates>? {
        if (_deviceManager != null) {
            return [new OpenBrakesDataFieldView(_deviceManager)] as Array<Views>;
        }
        return null;
    }
}

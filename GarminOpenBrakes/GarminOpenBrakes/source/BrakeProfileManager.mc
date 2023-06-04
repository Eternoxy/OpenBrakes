//
// Copyright 2023 by your name or organization
//

import Toybox.BluetoothLowEnergy;

class BrakeProfileManager {
    public const SENSOR_SERVICE_UUID             = BluetoothLowEnergy.longToUuid(0x066334741e8e43aaL, 0xa85f02f8c2814fb2L);
    public const TEMP_CHARACTERISTIC_UUID        = BluetoothLowEnergy.longToUuid(0xa5bfea66efec4808L, 0xb4722ac3d0c5a0efL);
    public const FORCE_CHARACTERISTIC_UUID       = BluetoothLowEnergy.longToUuid(0x0ec3dcce96104d0bL, 0x9a66338ca2097fa0L);
    public const RPM_CHARACTERISTIC_UUID         = BluetoothLowEnergy.longToUuid(0xc51dfdeaecd74fc1L, 0x872c0076f2428d27L);

    private const _sensorProfileDef = {
        :uuid => SENSOR_SERVICE_UUID,
        :characteristics => [{
            :uuid => TEMP_CHARACTERISTIC_UUID
        }, {
            :uuid => FORCE_CHARACTERISTIC_UUID
        }, {
            :uuid => RPM_CHARACTERISTIC_UUID
        }]
    };

    //! Register the Bluetooth profile
    public function registerProfiles() as Void {
        BluetoothLowEnergy.registerProfile(_sensorProfileDef);
    }
}

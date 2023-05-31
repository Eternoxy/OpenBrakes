// Copyright 2023 by Your Company.
// Subject to Your Company's License Agreement.

import Toybox.BluetoothLowEnergy;

class OpenBrakesProfileManager {
    public const OPEN_BRAKES_SERVICE = BluetoothLowEnergy.longToUuid(0x123456789ABCDEF0L, 0x123456789ABCDEF0L);
    public const BRAKE_FORCE_CHARACTERISTIC = BluetoothLowEnergy.longToUuid(0x123456789ABCDEF1L, 0x123456789ABCDEF1L);
    public const DISK_TEMPERATURE_CHARACTERISTIC = BluetoothLowEnergy.longToUuid(0x123456789ABCDEF2L, 0x123456789ABCDEF2L);
    public const WHEEL_RPM_CHARACTERISTIC = BluetoothLowEnergy.longToUuid(0x123456789ABCDEF3L, 0x123456789ABCDEF3L);

    private const _openBrakesProfileDef = {
        :uuid => OPEN_BRAKES_SERVICE,
        :characteristics => [{
            :uuid => BRAKE_FORCE_CHARACTERISTIC
        }, {
            :uuid => DISK_TEMPERATURE_CHARACTERISTIC
        }, {
            :uuid => WHEEL_RPM_CHARACTERISTIC
        }]
    };

    //! Register the OpenBrakes bluetooth profile
    public function registerProfiles() as Void {
        BluetoothLowEnergy.registerProfile(_openBrakesProfileDef);
    }
}

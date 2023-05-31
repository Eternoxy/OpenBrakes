// Copyright 2023 by Your Company.
// Subject to Your Company's License Agreement.

import Toybox.BluetoothLowEnergy;
import Toybox.Lang;
import Toybox.System;

class OpenBrakesDeviceManager {
    private var _profileManager as OpenBrakesProfileManager;
    private var _device as Device?;
    private var _brakeForce as Characteristic?;
    private var _diskTemperature as Characteristic?;
    private var _wheelRPM as Characteristic?;

    //! Constructor
    //! @param bleDelegate The BLE delegate
    //! @param profileManager The profile manager
    public function initialize(bleDelegate as OpenBrakesDelegate, profileManager as OpenBrakesProfileManager) {
        _device = null;

        bleDelegate.notifyScanResult(self);
        bleDelegate.notifyConnection(self);
        bleDelegate.notifyCharRead(self);

        _profileManager = profileManager;
    }

    //! Start BLE scanning
    public function start() as Void {
        BluetoothLowEnergy.setScanState(BluetoothLowEnergy.SCAN_STATE_SCANNING);
    }

    //! Process scan result
    //! @param scanResult The scan result
    public function procScanResult(scanResult as ScanResult) as Void {
        // Pair the first OpenBrakes device we see with good RSSI
        if (scanResult.getRssi() > -50) {
            BluetoothLowEnergy.setScanState(BluetoothLowEnergy.SCAN_STATE_OFF);
            BluetoothLowEnergy.pairDevice(scanResult);
        }
    }

    //! Process a new device connection
    //! @param device The device that was connected
    public function procConnection(device as Device) as Void {
        if (device.isConnected()) {
            _device = device;
            loadOpenBrakesCharacteristics();
        } else {
            _device = null;
        }
    }

    //! Load OpenBrakes characteristics
    private function loadOpenBrakesCharacteristics() as Void {
        System.println("Loading OpenBrakes Characteristics");
        if (_device != null) {
            var openBrakesService = _device.getService(_profileManager.OPEN_BRAKES_SERVICE);
            if (openBrakesService != null) {
                _brakeForce = openBrakesService.getCharacteristic(_profileManager.BRAKE_FORCE_CHARACTERISTIC);
                _diskTemperature = openBrakesService.getCharacteristic(_profileManager.DISK_TEMPERATURE_CHARACTERISTIC);
                _wheelRPM = openBrakesService.getCharacteristic(_profileManager.WHEEL_RPM_CHARACTERISTIC);
            }
        }
    }

    //! Request the latest brake force, disk temperature, and wheel RPM data
    public function requestData() as Void {
        if (_device != null && _brakeForce != null && _diskTemperature != null && _wheelRPM != null) {
            _brakeForce.requestRead();
            _diskTemperature.requestRead();
            _wheelRPM.requestRead();
        }
    }

    public function getBrakeForce() as Number {
        return _brakeForce;
    }

    public function getBrakeTemperature() as Number {
        return _diskTemperature;
    }

    public function getWheelRpm() as Number {
        return _wheelRPM;
    }
    //! Handle the completion of a read operation on a characteristic
    //! @param char The characteristic that was read
    //! @param status The result of the operation
    //! @param value The value that was read
    public function procCharRead(char as Characteristic, status as Status, value as ByteArray) as Void {
        System.println("Proc Read: (" + char.getUuid() + ") - " + status);
        // Process the data from each characteristic
        // You may store the values, display them, or perform any other operations needed
    }
}


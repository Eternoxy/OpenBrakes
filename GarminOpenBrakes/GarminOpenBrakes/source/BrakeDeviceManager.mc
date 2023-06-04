//
// Copyright 2023 by your name or organization
//

import Toybox.BluetoothLowEnergy;
import Toybox.Lang;
import Toybox.System;

class BrakeDeviceManager {
    private var _profileManager as BrakeProfileManager;
    private var _device as Device?;
    private var _tempCharacteristic as Characteristic?;
    private var _forceCharacteristic as Characteristic?;
    private var _rpmCharacteristic as Characteristic?;

    public function initialize(bleDelegate as BrakeDelegate, profileManager as BrakeProfileManager) {
        _device = null;
        bleDelegate.notifyScanResult(self);
        bleDelegate.notifyConnection(self);
        bleDelegate.notifyCharRead(self);
        _profileManager = profileManager;
    }

    public function start() as Void {
        BluetoothLowEnergy.setScanState(BluetoothLowEnergy.SCAN_STATE_SCANNING);
    }

    public function procScanResult(scanResult as ScanResult) as Void {
        if (scanResult.getRssi() > -50) {
            BluetoothLowEnergy.setScanState(BluetoothLowEnergy.SCAN_STATE_OFF);
            BluetoothLowEnergy.pairDevice(scanResult);
        }
    }

    public function procConnection(device as Device) as Void {
        if (device.isConnected()) {
            _device = device;
            startServices();
        } else {
            _device = null;
        }
    }

    public function procCharRead(char as Characteristic, status as Status, value as Value) as Void {
        System.println("Proc Read: (" + char.getUuid() + ") - " + status + value);
    }

    private function startServices() as Void {
        if (_device != null) {
            var service = _device.getService(_profileManager.SENSOR_SERVICE_UUID);
            if (service != null) {
                _tempCharacteristic = service.getCharacteristic(_profileManager.TEMP_CHARACTERISTIC_UUID);
                _forceCharacteristic = service.getCharacteristic(_profileManager.FORCE_CHARACTERISTIC_UUID);
                _rpmCharacteristic = service.getCharacteristic(_profileManager.RPM_CHARACTERISTIC_UUID);
            }
        }
    }

    // Add methods to request data from characteristics
    public function requestTemperature() as Void {
        if (_tempCharacteristic != null) {
            _tempCharacteristic.requestRead();
        }
    }

    public function requestForce() as Void {
        if (_forceCharacteristic != null) {
            _forceCharacteristic.requestRead();
        }
    }

    public function requestRPM() as Void {
        if (_rpmCharacteristic != null) {
            _rpmCharacteristic.requestRead();
        }
    }
}

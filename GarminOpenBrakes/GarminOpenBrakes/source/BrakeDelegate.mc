//
// Copyright 2023 by your name or organization
//

import Toybox.BluetoothLowEnergy;
import Toybox.Lang;

class BrakeDelegate extends BluetoothLowEnergy.BleDelegate {
    private var _profileManager as BrakeProfileManager;

    private var _onScanResult as WeakReference?;
    private var _onConnection as WeakReference?;
    private var _onCharRead as WeakReference?;

    public function initialize(profileManager as BrakeProfileManager) {
        BleDelegate.initialize();
        _profileManager = profileManager;
    }

    public function onScanResults(scanResults as Iterator) as Void {
        for (var result = scanResults.next(); result != null; result = scanResults.next()) {
            if (result instanceof ScanResult) {
                if (contains(result.getServiceUuids(), _profileManager.SENSOR_SERVICE_UUID)) {
                    broadcastScanResult(result);
                }
            }
        }
    }

    public function onConnectedStateChanged(device as Device, state as ConnectionState) as Void {
        var onConnection = _onConnection;
        if (onConnection != null) {
            if (onConnection.stillAlive()) {
                (onConnection.get() as BrakeDeviceManager).procConnection(device);
            }
        }
    }

    public function onCharacteristicRead(characteristic as Characteristic, status as Status, value as Lang.ByteArray) as Void {
        var onCharRead = _onCharRead;
        if (onCharRead != null) {
            if (onCharRead.stillAlive()) {
                onCharRead.get() as BrakeDeviceManager.procCharRead(characteristic, status, value);
            }
        }
    }

    public function notifyScanResult(manager as BrakeDeviceManager) as Void {
        _onScanResult = manager.weak();
    }

    public function notifyConnection(manager as BrakeDeviceManager) as Void {
        _onConnection = manager.weak();
    }

    public function notifyCharRead(manager as BrakeDeviceManager) as Void {
        _onCharRead = manager.weak();
    }

    private function broadcastScanResult(scanResult as ScanResult) as Void {
        var onScanResult = _onScanResult;
        if (onScanResult != null) {
            if (onScanResult.stillAlive()) {
                (onScanResult.get() as BrakeDeviceManager).procScanResult(scanResult);
            }
        }
    }

    private function contains(iter as Iterator, obj as Uuid) as Boolean {
        for (var uuid = iter.next(); uuid != null; uuid = iter.next()) {
            if (uuid.equals(obj)) {
                return true;
            }
        }
        return false;
    }
}

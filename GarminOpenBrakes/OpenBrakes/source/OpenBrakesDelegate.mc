// Copyright 2023 by Your Company.
// Subject to Your Company's License Agreement.

import Toybox.BluetoothLowEnergy;
import Toybox.Lang;

class OpenBrakesDelegate extends BluetoothLowEnergy.BleDelegate {
    private var _profileManager as OpenBrakesProfileManager;

    private var _onScanResult as WeakReference?;
    private var _onConnection as WeakReference?;
    private var _onCharRead as WeakReference?;

    //! Constructor
    //! @param profileManager The profile manager
    public function initialize(profileManager as OpenBrakesProfileManager) {
        BleDelegate.initialize();
        _profileManager = profileManager;
    }

    //! Handle new Scan Results being received
    //! @param scanResults An iterator of new scan result objects
    public function onScanResults(scanResults as Iterator) as Void {
        for (var result = scanResults.next(); result != null; result = scanResults.next()) {
            if (result instanceof ScanResult) {
                if (contains(result.getServiceUuids(), _profileManager.OPEN_BRAKES_SERVICE)) {
                    broadcastScanResult(result);
                }
            }
        }
    }

    //! Handle pairing and connecting to a device
    //! @param device The device state that was changed
    //! @param state The state of the connection
    public function onConnectedStateChanged(device as Device, state as ConnectionState) as Void {
        var onConnection = _onConnection;
        if (onConnection != null) {
            if (onConnection.stillAlive()) {
                (onConnection.get() as OpenBrakesDeviceManager).procConnection(device);
            }
        }
    }

    //! Handle the completion of a read operation on a characteristic
    //! @param characteristic The characteristic that was read
    //! @param status The BluetoothLowEnergy status indicating the result of the operation
    //! @param value The value that was read
    public function onCharacteristicRead(characteristic as Characteristic, status as Status, value as ByteArray) as Void {
        var onCharRead = _onCharRead;
        if (onCharRead != null) {
            if (onCharRead.stillAlive()) {
                (onCharRead.get() as OpenBrakesDeviceManager).procCharRead(characteristic, status, value);
            }
        }
    }

    //! Store a new manager to manage scan results
    //! @param manager The manager of the scan results
    public function notifyScanResult(manager as OpenBrakesDeviceManager) as Void {
        _onScanResult = manager.weak();
    }

    //! Store a new manager to manage device connections
    //! @param manager The manager for devices
    public function notifyConnection(manager as OpenBrakesDeviceManager) as Void {
        _onConnection = manager.weak();
    }

    //! Store a new manager to handle characteristic reads
    //! @param manager The manager for characteristics
    public function notifyCharRead(manager as OpenBrakesDeviceManager) as Void {
        _onCharRead = manager.weak();
    }

    //! Broadcast a new scan result
    //! @param scanResult The new scan result
    private function broadcastScanResult(scanResult as ScanResult) as Void {
        var onScanResult = _onScanResult;
        if (onScanResult != null) {
            if (onScanResult.stillAlive()) {
                (onScanResult.get() as OpenBrakesDeviceManager).procScanResult(scanResult);
            }
        }
    }

    //! Get whether the iterator contains a specific uuid
    //! @param iter Iterator of uuid objects
    //! @param obj Uuid to search for
//! @return true if object found, false otherwise
private function contains(iter as Iterator, obj as Uuid) as Boolean {
    for (var uuid = iter.next(); uuid != null; uuid = iter.next()) {
        if (uuid.equals(obj)) {
            return true;
        }
    }

    return false;
}
}
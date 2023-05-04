import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';


class BlDevicesContent extends StatefulWidget {
  final Function(String?, FlutterReactiveBle?) onDeviceConnected;

  BlDevicesContent({required this.onDeviceConnected});

  @override
  _BlDevicesContentState createState() => _BlDevicesContentState();
}

class _BlDevicesContentState extends State<BlDevicesContent> {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  List<DiscoveredDevice> _devices = [];
  StreamSubscription<ConnectionStateUpdate>? _connection;
  String? _connectedDeviceId;
  bool _scanning = false;
  

void scanDevices() async {
  // Request location permission
  PermissionStatus locationPermission =
      await Permission.location.request();

  // Check if the permission is granted
  if (locationPermission.isGranted) {
    setState(() {
      _devices.clear();
      _scanning = true;
    });

    final stream = _ble.scanForDevices(
      withServices: [], // You can add the required service UUIDs here
      scanMode: ScanMode.balanced,
      requireLocationServicesEnabled: true,
    );

    final scanSubscription = stream.listen((device) {
      // Check if the list already contains the device before adding it
      if (!_devices.any((element) => element.id == device.id)) {
        setState(() {
          _devices.add(device);
        });
      }
    });

    await Future.delayed(Duration(seconds: 4));
    await scanSubscription.cancel();

    setState(() {
      _scanning = false;
    });
  } else {
    // Show a message if the permission is denied
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Location permission is required to scan for devices')),
    );
  }
}



  Future<void> connectDevice(DiscoveredDevice device) async {
    if (_connectedDeviceId != null && _connectedDeviceId == device.id) {
      await _connection?.cancel();
      setState(() {
        _connectedDeviceId = null;
      });
      widget.onDeviceConnected(null, null);
    } else {
      _connection?.cancel();
      _connection = _ble
          .connectToDevice(
        id: device.id,
        connectionTimeout: const Duration(seconds: 2),
      )
          .listen((connectionUpdate) {
        if (connectionUpdate.connectionState ==
            DeviceConnectionState.connected) {
          setState(() {
            _connectedDeviceId = device.id;
          });
          widget.onDeviceConnected(_connectedDeviceId, _ble);
        } else {
          setState(() {
            _connectedDeviceId = null;
          });
          widget.onDeviceConnected(null, null);
        }
      }, onError: (Object error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect: $error')),
        );
        setState(() {
          _connectedDeviceId = null;
        });
        widget.onDeviceConnected(null, null);
      });
    }
  }

  @override
  void dispose() {
    _connection?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: _scanning ? null : scanDevices,
          style: ElevatedButton.styleFrom(primary: Colors.blue),
          child: _scanning
              ? CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
              : Text('Scan Devices', style: TextStyle(color: Colors.white)),
        ),
        SizedBox(height: 16),
        Expanded(
          child: _devices.isEmpty
              ? Center(child: Text('No devices found'))
              : ListView.builder(
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    final isConnected = _connectedDeviceId == device.id;
                    return ListTile(
                      title: Text(
                          device.name.isEmpty ? 'Unknown Device' : device.name),
                      subtitle: Text(device.id),
                      trailing: isConnected
                          ? Icon(Icons.bluetooth_connected, color: Colors.blue)
                          : Icon(Icons.bluetooth_disabled, color: Colors.grey),
                      onTap: () => connectDevice(device),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

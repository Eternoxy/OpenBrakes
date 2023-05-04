import 'package:flutter/material.dart';
import 'screens/bl_devices.dart';
import 'screens/calibration.dart';
import 'screens/recording.dart';
import 'screens/data_display_export.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}


class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? _connectedDeviceId;
  FlutterReactiveBle? _ble;
  int _currentTabIndex = 0;

  void handleDeviceConnected(String? deviceId, FlutterReactiveBle? ble) {
    setState(() {
      _connectedDeviceId = deviceId;
      _ble = ble;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('BLE App'),
          bottom: TabBar(
            onTap: (index) {
              setState(() {
                _currentTabIndex = index;
              });
            },
            tabs: [
              Tab(icon: Icon(Icons.bluetooth), text: 'Bluetooth'),
              Tab(icon: Icon(Icons.tune), text: 'Calibration'),
              Tab(icon: Icon(Icons.play_arrow), text: 'Recording'),
              Tab(icon: Icon(Icons.save), text: 'Export'),
            ],
          ),
        ),
        body: IndexedStack(
          index: _currentTabIndex,
          children: [
            BlDevicesContent(onDeviceConnected: handleDeviceConnected),
            CalibrationPage(
                connectedDeviceId: _connectedDeviceId,
                ble: _ble,
                onDeviceConnected: handleDeviceConnected),
            RecordingPage(),
            ExportPage(),
          ],
        ),
      ),
    );
  }
}


import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:ui' as ui;

class CalibrationPage extends StatefulWidget {
  final String? connectedDeviceId;
  final FlutterReactiveBle? ble;
  final Function(String?, FlutterReactiveBle?) onDeviceConnected;

  CalibrationPage({this.connectedDeviceId, this.ble, required this.onDeviceConnected});

  @override
  _CalibrationState createState() => _CalibrationState();
}

class BatteryWidget extends StatelessWidget {
  final int? batteryPercentage;

  BatteryWidget({required this.batteryPercentage});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BatteryPainter(batteryPercentage),
      child: Center(
        child: Text(
          '${batteryPercentage ?? "N/A"}%',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _BatteryPainter extends CustomPainter {
  final int? batteryPercentage;

  _BatteryPainter(this.batteryPercentage);

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final paint = ui.Paint();
    final batteryWidth = size.width - 4;
    final batteryHeight = size.height - 20;
    final batteryLevelWidth = batteryWidth * (batteryPercentage! / 100);

    paint.color = Colors.grey;
    canvas.drawRect(
        ui.Rect.fromLTWH(2, 10, batteryWidth, batteryHeight), paint);

    paint.color = batteryPercentage! > 50
        ? Colors.green
        : (batteryPercentage! > 20 ? Colors.orange : Colors.red);
    canvas.drawRect(
        ui.Rect.fromLTWH(2, 10, batteryLevelWidth, batteryHeight), paint);

    paint.color = Colors.black;
    canvas.drawRect(
        ui.Rect.fromLTWH(size.width / 2 - 4, 0, 8, 10), paint);
  }

  @override
  bool shouldRepaint(_BatteryPainter oldDelegate) =>
      oldDelegate.batteryPercentage != batteryPercentage;
}

class _CalibrationState extends State<CalibrationPage> {
  // Replace these UUIDs with the actual UUIDs for your device
final String sensorUuid = "06633474-1e8e-43aa-a85f-02f8c2814fb2";
final String torqueServiceUuid = "e0f72bb5-c6f3-4953-9b2c-90db43906bf8";
final String torqueCharUuid = "0ec3dcce-9610-4d0b-9a66-338ca2097fa0";
final String tempServiceUuid = "20eeb27c-8244-4868-8528-9b878049fea8";
final String tempCharUuid = "a5bfea66-efec-4808-b472-2ac3d0c5a0ef";
final String rpmServiceUuid = "c2e40308-dbeb-4fe2-b76d-8861a4306599";
final String rpmCharUuid = "c51dfdea-ecd7-4fc1-872c-0076f2428d27";
final String batteryServiceUuid = "0000180f-0000-1000-8000-00805f9b34fb";
final String batteryCharUuid = "00002a19-0000-1000-8000-00805f9b34fb";

  double? torque;
  double? temperature;
  double? rpm;
  int? batteryPercentage;


  StreamSubscription? _torqueSubscription;
  StreamSubscription? _temperatureSubscription;
  StreamSubscription? _rpmSubscription;
  StreamSubscription? _batterySubscription;

  TextEditingController _scaleFactorController = TextEditingController();
  TextEditingController _calibrationValueController = TextEditingController();
  TextEditingController _rpmValueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.connectedDeviceId != null && widget.ble != null) {
      _subscribeToCharacteristics();
    }
  }

  @override
  void didUpdateWidget(CalibrationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.connectedDeviceId != null && widget.ble != null) {
      _subscribeToCharacteristics();
    } else {
      _unsubscribeFromCharacteristics();
    }
  }

void _subscribeToCharacteristic(String serviceUuid, String charUuid, Function(double) onUpdate) {
  widget.ble!
      .subscribeToCharacteristic(QualifiedCharacteristic(
          serviceId: Uuid.parse(serviceUuid),
          characteristicId: Uuid.parse(charUuid),
          deviceId: widget.connectedDeviceId!))
      .listen((data) {
    final byteData = ByteData.view(Uint8List.fromList(data).buffer);
    final floatValue = byteData.getFloat32(0, Endian.little);
    setState(() {
      onUpdate(floatValue);
    });
  });
}

void _subscribeToCharacteristics() {
  _subscribeToCharacteristic(sensorUuid, torqueCharUuid, (value) => torque = value);
  _subscribeToCharacteristic(sensorUuid, tempCharUuid, (value) => temperature = value);
  _subscribeToCharacteristic(sensorUuid, rpmCharUuid, (value) => rpm = value);
  _subscribeToCharacteristic(batteryServiceUuid, batteryCharUuid, (value) {
    setState(() {
      batteryPercentage = value.toInt();
    });
  });
}




void _unsubscribeFromCharacteristics() {
  _torqueSubscription?.cancel();
  _temperatureSubscription?.cancel();
  _rpmSubscription?.cancel();
}

  Future<void> _writeCharacteristic(String serviceUuid, String charUuid, String command) async {
    await widget.ble!.writeCharacteristicWithResponse(
      QualifiedCharacteristic(
        serviceId: Uuid.parse(serviceUuid),
        characteristicId: Uuid.parse(charUuid),
        deviceId: widget.connectedDeviceId!,
      ),
      value: utf8.encode(command),
    );
    _readCalibrationFeedback(serviceUuid, charUuid);
  }



  Future<void> _readCalibrationFeedback(serviceUuid, charUuid) async {
    final characteristic = QualifiedCharacteristic(
      serviceId: Uuid.parse(serviceUuid),
      characteristicId: Uuid.parse(charUuid),
      deviceId: widget.connectedDeviceId!,
    );

    final response = await widget.ble!.readCharacteristic(characteristic);
    final feedback = utf8.decode(response);

    // Show the feedback using a SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(feedback),
        duration: Duration(seconds: 3),
      ),
    );
  }

@override
void dispose() {
  _unsubscribeFromCharacteristics();
  super.dispose();
}

@override
Widget build(BuildContext context) {
  return SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          _buildSensorCard(
            title: 'Battery Level',
            value: batteryPercentage?.toDouble(),
            calibrationOptions: Container(), // No calibration options for battery
          ),
          _buildSensorCard(
            title: 'Torque Sensor',
            value: torque,
            calibrationOptions: _buildTorqueCalibrationOptions(),
          ),
          _buildSensorCard(
            title: 'Temperature Sensor',
            value: temperature,
            calibrationOptions: _buildTemperatureCalibrationOptions(),
          ),
          _buildSensorCard(
            title: 'RPM Sensor',
            value: rpm,
            calibrationOptions: _buildRpmCalibrationOptions(),
          ),
        ],
      ),
    ),
  );
}



  Widget _buildSensorCard({required String title, double? value, required Widget calibrationOptions}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Value: ${value?.toStringAsFixed(2) ?? 'N/A'}'),
            SizedBox(height: 16),
            calibrationOptions,
          ],
        ),
      ),
    );
  }

Widget _buildTorqueCalibrationOptions() {
  return Column(
    children: [
      ElevatedButton(
        onPressed: () {
          _writeCharacteristic(sensorUuid, torqueServiceUuid, 'CALIBRATE');
        },
        child: Text('Calibrate Torque'),
      ),
      ElevatedButton(
        onPressed: () {
          _writeCharacteristic(sensorUuid, torqueServiceUuid, 'TARE');
        },
        child: Text('Tare (Set to zero)'),
      ),
      Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: _scaleFactorController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Enter scale factor',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(left: 8.0),
            child: ElevatedButton(
              onPressed: () {
                final command = 'SCALE:${_scaleFactorController.text}';
                _writeCharacteristic(sensorUuid, torqueServiceUuid, command);
              },
              child: Text('Set scale factor'),
            ),
          ),
        ],
      ),
      Row(  // This is the new row for the known weight input
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: _calibrationValueController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Enter known weight',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(left: 8.0),
            child: ElevatedButton(
              onPressed: () {
                final command = 'CALIBRATE:${_calibrationValueController.text}';
                _writeCharacteristic(sensorUuid, torqueServiceUuid, command);
              },
              child: Text('Calibrate with known weight'),
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _buildTemperatureCalibrationOptions() {
  return Column(
    children: [
      Container(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: TextField(
          controller: _calibrationValueController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Enter current temperature',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      Container(
        margin: EdgeInsets.only(top: 8.0),
        child: ElevatedButton(
          onPressed: () {
            final currentValue = _calibrationValueController.text;
            if (currentValue.isNotEmpty) {
              _writeCharacteristic(sensorUuid, tempServiceUuid, 'CALIBRATE:$currentValue');
            }
          },
          child: Text('Calibrate Temperature'),
        ),
      ),
    ],
  );
}

Widget _buildRpmCalibrationOptions() {
  return Row(
    children: [
      Expanded(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            controller: _rpmValueController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Enter number of magnets',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ),
      Container(
        margin: EdgeInsets.only(left: 8.0),
        child: ElevatedButton(
          onPressed: () {
            final currentValue = _rpmValueController.text;
            if (currentValue.isNotEmpty) {
              _writeCharacteristic(sensorUuid, rpmServiceUuid, currentValue);
            }
          },
          child: Text('Calibrate RPM'),
        ),
      ),
    ],
  );
}

}
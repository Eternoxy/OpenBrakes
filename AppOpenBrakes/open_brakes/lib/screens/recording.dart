import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecordingPage extends StatefulWidget {
  @override
  _RecordingPageState createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage> {
  bool isRecording = false;
  Timer? _timer;
  String? _csvDirectoryPath;
  SharedPreferences? _prefs;
  File? _csvFile;

  // Replace these with actual sensor values
  double sensorValue1 = 1.0;
  double sensorValue2 = 2.0;
  double sensorValue3 = 3.0;

    @override
  void initState() {
    super.initState();
    _initSharedPreferences();
    _requestManageExternalStoragePermission();
  }

@override
Widget build(BuildContext context) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          isRecording ? 'Recording...' : 'Press the button to start recording',
          style: TextStyle(fontSize: 18),
        ),
        SizedBox(height: 16),
        FloatingActionButton(
          onPressed: _toggleRecording,
          tooltip: isRecording ? 'Stop recording' : 'Start recording',
          backgroundColor: isRecording ? Colors.green : Colors.red,
          child: Icon(isRecording ? Icons.stop : Icons.mic),
        ),
        SizedBox(height: 16),
        _buildSelectDirectoryButton(),
        if (_csvDirectoryPath != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Selected directory: $_csvDirectoryPath'),
          ),
      ],
    ),
  );
}


  void _toggleRecording() {
    if (isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

Future<void> _startRecording() async {
  if (_csvDirectoryPath == null) {
    await _pickDirectory();
  }

  if (_csvDirectoryPath != null) {
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMddHHmmss');
    final timestamp = formatter.format(now);
    final filePath = '$_csvDirectoryPath/$timestamp.csv';

    final file = File(filePath);
    await file.create();

    if (await file.exists()) {
      print('CSV file created at: $filePath');
      _csvFile = file;
      setState(() {
        isRecording = true;
      });
      _writeHeader();
      _startTimer();
    } else {
      print('CSV file could not be created');
    }
  } else {
    print('No directory was selected');
  }
}

  void _stopRecording() {
    setState(() => isRecording = false);
    _timer?.cancel();
    _csvDirectoryPath = null;
  }

void _startTimer() {
  _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
    await _writeDataRow();
  });
}  

Future<void> _writeDataRow() async {
  if (_csvFile == null) return;

  DateTime now = DateTime.now().toUtc().add(Duration(hours: 1)); // UTC+1
  String timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

  // Replace these example sensor values with the actual sensor values
  double torque = 0.0;
  double temperature = 0.0;
  double rpm = 0.0;

  String dataRow = '$timestamp,$torque,$temperature,$rpm\n';
  await _csvFile!.writeAsString(dataRow, mode: FileMode.append, flush: true);
}


Future<void> _writeHeader() async {
  if (_csvFile != null) {
    final headers = [
      "Time",
      "Sensor1",
      "Sensor2",
      // Add other sensor headers as needed
    ];

    final csv = ListToCsvConverter(fieldDelimiter: ',', textDelimiter: '"');
    final headerLine = csv.convert([headers]);

    await _csvFile!.writeAsString(headerLine);
  }
}  

Future<void> _pickDirectory() async {
  if (await Permission.storage.request().isGranted) {
    String? pickedDirectoryPath = await FilePicker.platform.getDirectoryPath();

    if (pickedDirectoryPath != null) {
      setState(() {
        _csvDirectoryPath = pickedDirectoryPath;
      });
      await _prefs!.setString('csvDirectoryPath', _csvDirectoryPath!);
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Storage permission is required to pick a directory')),
    );
  }
}


Widget _buildSelectDirectoryButton() {
  return ElevatedButton(
    onPressed: () async {
      await _pickDirectory();
    },
    child: Text('Select directory'),
  );
}

  Future<void> _requestManageExternalStoragePermission() async {
    await Permission.manageExternalStorage.request();
  }

Future<void> _initSharedPreferences() async {
  _prefs = await SharedPreferences.getInstance();
  _csvDirectoryPath = _prefs!.getString('csvDirectoryPath');
}

}

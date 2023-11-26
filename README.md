# OpenBrakes Sensor Suite

This Arduino project, named 'OpenBrakes', is designed to interface with various sensors including a strain gauge, temperature sensor, and a hall effect sensor for RPM measurement. The project includes features for calibration, data recording, and BLE (Bluetooth Low Energy) communication for data transmission.

## Getting Started

These instructions will help you set up 'OpenBrakes' on your Arduino device for development and testing purposes.

### Prerequisites

- Arduino IDE
- BLE compatible Arduino board (tested with ESP32)
- Strain gauge sensor, preferably mounted in a suitable measurement location. To be used in conjunction with a HX711 board. Refer to the documentation of the HX711 library or here: https://github.com/bogde/HX711
- Temperature sensor (MLX90614)
- Hall effect sensor
- Access to a Wi-Fi network (for time synchronization). WiFi credentials are hardcoded in the .ino file and should be changed to your requirements.
- usage of a generic BLE app like lightBlue will help sending commands and check the status of the sensor and is highly recommended.

### Installing

1. Clone the repository to your local machine.
2. Open the project in the Arduino IDE.
3. Connect the Arduino board to your computer.
4. Upload the code to the Arduino board.

## Usage

Once the setup is complete, the system will start measuring torque, temperature, and RPM data, and transmit these via BLE respectively print them in the command line. You can also start and stop data recording which will be saved in CSV format.

Following commands can be used to control the behaviour of the microcontroller. Take note that they have to be sent to the regarding characteristic in a string format to work correctly. Wrong inputs are handled with an error output.

Command Line (Serial) Inputs (use for example arduino serial monitor)
Start Recording

Command: START_REC
Action: Initiates the data recording process, saving sensor readings to a CSV file.
Stop Recording

Command: STOP_REC
Action: Ends the data recording process and closes the CSV file.
List Files

Command: LIST_FILES
Action: Lists all CSV files stored in the SPIFFS file system.
Read File

Command: READ_FILE:<filename>
Action: Reads and outputs the contents of the specified file.
Test Write

Command: TEST_WRITE
Action: Writes test data to the currently open file for testing purposes.
Calibration and Configuration

Temperature Sensor Calibration
Command: CALIBRATE:THERM:<value>
Action: Calibrates the temperature sensor with a reference temperature.
Strain Gauge Calibration
Command: CALIBRATE:STRAIN:<value>
Action: Calibrates the strain gauge sensor with a known weight.
RPM Sensor Calibration
Command: CALIBRATE:RPM:<value>
Action: Calibrates the RPM sensor with a specific value.
BLE Inputs
Start Recording

Command: START_REC
Action: Begins recording of sensor data to a CSV file.
Stop Recording

Command: STOP_REC
Action: Stops the recording session and closes the CSV file.
Thermal Calibration

Command: CALIBRATE:<referenceTemperature>
Action: Calibrates the temperature sensor with a reference temperature.
Strain Gauge Calibration

Commands:
CALIBRATE:<knownWeight>: Calibrates the strain gauge with a known weight.
TARE: Zeroes the strain gauge sensor.
SCALE:<factor>: Sets a custom scale factor for the strain gauge.
RPM Calibration

Command: SET_MAGNET_COUNT:<count>
Action: Updates the magnet count for accurate RPM measurement.

### Calibration

Calibration is crucial for ensuring accurate sensor readings. The system supports calibration for each sensor through BLE commands:

Thermal Calibration: Sends a calibration command with a reference temperature to the temperature sensor, ensuring accurate temperature readings.
Strain Gauge Calibration: This involves setting a known weight for calibration and taring (zeroing) the sensor. The system also supports setting a custom scale factor for the strain gauge.
RPM Calibration: Includes setting the magnet count for the hall sensor, which is crucial for accurate RPM measurements.

### Data Recording

The startRecording and stopRecording functions manage the recording of sensor data:

Starting Recording: When recording starts, the system creates a new CSV file with a timestamped filename. It logs sensor data (torque, temperature, RPM) along with timestamps in this file.
Stopping Recording: Stops the recording process and closes the CSV file.
Read and Average Sensors: While recording, the system reads and averages sensor data. If not recording, it prints averaged sensor values to the serial console for monitoring.
Data File Handling: The system handles file operations, ensuring data is correctly written to and closed in the SPIFFS file system.

### Additional Features

File Management Commands: Through serial commands, users can list all CSV files, read specific files, and even perform test writes to check file system integrity.
Continuous Monitoring: The system continues to monitor and process sensor data, even while handling BLE or serial commands, ensuring uninterrupted data collection.

### Wi-Fi and NTP

The system connects to a Wi-Fi network for NTP time synchronization, which is crucial for timestamping the recorded data.

## Built With

- Arduino IDE
- C/C++ (Arduino programming language)
- ESP32 (or any other BLE compatible Arduino board)
- Various sensors (strain gauge, temperature sensor, hall effect sensor)

## Contributing

Contributions to 'OpenBrakes' are welcome. Please read [CONTRIBUTING.md](LINK_TO_CONTRIBUTING.MD) for details on our code of conduct, and the process for submitting pull requests.

## Authors

* **[Your Name]** - *Initial work* - [Your GitHub Profile](LINK_TO_YOUR_PROFILE)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE_LINK) file for details

## Acknowledgments

* Acknowledge any libraries or resources you used.
* Inspiration, if any.
* etc.

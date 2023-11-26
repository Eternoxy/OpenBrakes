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


## BLE App

For using the BLE functionalities a generic BLE app widely available for Android and iOS alike will do the job. A app specifically for controlling this sensor was developed and the source code is provided within this github.

To build and run the BLE app, you'll need to set up your development environment. Ensure you have the following:

Flutter SDK: Install the latest version of the Flutter SDK from the Flutter website.
Visual Studio Code (VSCode): Install VSCode from the official website.
Running the App in VSCode
Clone the Repository: Clone this GitHub repository to your local machine.

Open the Project in VSCode: Start VSCode, select 'File > Open Folder', and navigate to the cloned repository folder.

Install Dependencies: Open a terminal in VSCode (View > Terminal) and run the command flutter pub get in the project's root directory. This command installs all the necessary Flutter dependencies.

Set Up a Device or Emulator: Connect a physical device (android devices with USB Debugging enabled) via USB or set up an emulator to run the app. Ensure your device/emulator has Bluetooth capabilities for BLE functionality.

Run the App: Use flutter devices to check for all available devices. Use the command flutter run in the VSCode terminal to build and run the app on your connected device or emulator. Since flutter is crossplatform compatible it can even be run in a browser.


## Data Analysis

The generated data present in a .csv file can be transfered to a computer and be analysed with the provided Jupyter Notebook. Google Colab is a powerful platform to execute Python code in form of a Jupyter Notebook. 
Here is a short guide how to set up the data analysis:

Access Google Colab: Visit Google Colab and sign in with a Google account.

Upload the Notebook: In Colab, go to 'File > Upload notebook' and select the provided Jupyter Notebook file.

Upload Data Files:

Use the file explorer (folder icon in the left sidebar) to upload your GPX and CSV files.
Make sure the file paths in the notebook match the uploaded files.
Install Libraries: Execute !pip install cells to install required Python libraries.

Run the Notebook: Run each cell sequentially using 'Shift + Enter' or the play button on the cell.

Analyze and Visualize Data: Follow the notebook steps to synchronize your data and perform analysis. 

Important Note
Google Colab sessions are temporary. If you disconnect or close the tab, you'll need to re-upload files and rerun the notebook upon your return.

#include <Arduino.h>
#include "sensors.h"
#include <bluefruit.h>
#include "StrainGaugeSensor.h"
#include "MLX90614Sensor.h"
#include "HallSensor.h"
#include <xiaobattery.h>



#define UUID128_SVC_SENSOR   "06633474-1e8e-43aa-a85f-02f8c2814fb2"
#define UUID128_CHR_THERMAL  "a5bfea66-efec-4808-b472-2ac3d0c5a0ef"
#define UUID128_CHR_STRAIN   "0ec3dcce-9610-4d0b-9a66-338ca2097fa0"
#define UUID128_CHR_RPM      "c51dfdea-ecd7-4fc1-872c-0076f2428d27"
#define UUID128_CHR_THERMAL_CALIB  "20eeb27c-8244-4868-8528-9b878049fea8"
#define UUID128_CHR_STRAIN_CALIB   "e0f72bb5-c6f3-4953-9b2c-90db43906bf8"
#define UUID128_CHR_RPM_CALIB      "c2e40308-dbeb-4fe2-b76d-8861a4306599"

const uint8_t DOUT_PIN = A1;
const uint8_t CLK_PIN = A0;
StrainGaugeSensor strainGaugeSensor(DOUT_PIN, CLK_PIN);

MLX90614Sensor temperatureSensor;

const uint8_t HALL_SENSOR_PIN = 2; // Replace with the actual pin you are using
const uint8_t MAGNET_COUNT = 1; // Replace with the actual number of magnets on the wheel, can also be done in the setup (BLE Callback)
HallSensor hallSensor(HALL_SENSOR_PIN, MAGNET_COUNT);



// BLE service and characteristics
BLEService brakeSensorService = BLEService(UUID128_SVC_SENSOR);
BLECharacteristic bleCharacteristicTherm = BLECharacteristic(UUID128_CHR_THERMAL);
BLECharacteristic bleCharacteristicStrain = BLECharacteristic(UUID128_CHR_STRAIN);
BLECharacteristic bleCharacteristicRPM = BLECharacteristic(UUID128_CHR_RPM);

BLECharacteristic bleCharacteristicThermCalib = BLECharacteristic(UUID128_CHR_THERMAL_CALIB);
BLECharacteristic bleCharacteristicStrainCalib = BLECharacteristic(UUID128_CHR_STRAIN_CALIB);
BLECharacteristic bleCharacteristicRPMCalib = BLECharacteristic(UUID128_CHR_RPM_CALIB);

BLEDis bledis;    // DIS (Device Information Service) helper class instance
BLEBas blebas;    // BAS (Battery Service) helper class instance

Xiao battery;

// Variables to store averaged sensor readings
float avgTemperature = 0;
float avgStrainGaugeValue = 0;
float avgWheelSpeedRadS = 0;

// Variables to store timestamps
unsigned long lastReadMillis = 0;
unsigned long readInterval = 10; // 100 ms for readAndAverageSensors()

unsigned long lastNotifyMillis = 0;
unsigned long notifyInterval = 1000; // 1000 ms for sendData()

unsigned long lastBatteryMillis = 0;
unsigned long batteryInterval = 10000; // 1000 ms for sendData()

uint32_t timeout = 5000; // 5 seconds timeout
uint32_t startTime;


void setup() {
  pinMode(LED_RED, OUTPUT);
  pinMode(LED_GREEN, OUTPUT);
  pinMode(LED_BLUE, OUTPUT);
  //Set high charging current:
  Serial.begin(115200);
  startTime = millis();
  while (!Serial && (millis() - startTime) < timeout); // Wait for the Serial Monitor to open or until timeout
  Serial.println("Serial communication initialized");
  strainGaugeSensor.begin();
  temperatureSensor.begin();
  hallSensor.begin();
  // Initialize BLE
  Bluefruit.begin();
  Bluefruit.Periph.setConnectCallback(connect_callback);
  Bluefruit.Periph.setDisconnectCallback(disconnect_callback);
  Bluefruit.setTxPower(4);
  Bluefruit.setName("OpenBrakes");
  bledis.setManufacturer("OpenBrakes");
  bledis.setModel("FrontBrake");
  bledis.begin();
  blebas.begin();
  blebas.write(100);
  // Set up BLE services and advertising
  setup_ble_services();
  setup_ble_advertising();
  sensors_init();
  Serial.println("Setup finished");
}

void setup_ble_services() {
  brakeSensorService.begin();
  bleCharacteristicTherm.setProperties(CHR_PROPS_NOTIFY);
  bleCharacteristicTherm.setPermission(SECMODE_OPEN, SECMODE_NO_ACCESS);
  bleCharacteristicTherm.begin();
  bleCharacteristicStrain.setProperties(CHR_PROPS_NOTIFY);
  bleCharacteristicStrain.setPermission(SECMODE_OPEN, SECMODE_NO_ACCESS);
  bleCharacteristicStrain.begin();
  bleCharacteristicRPM.setProperties(CHR_PROPS_NOTIFY);
  bleCharacteristicRPM.setPermission(SECMODE_OPEN, SECMODE_NO_ACCESS);
  bleCharacteristicRPM.begin();
  bleCharacteristicThermCalib.setProperties(CHR_PROPS_WRITE | CHR_PROPS_READ);
  bleCharacteristicThermCalib.setPermission(SECMODE_OPEN, SECMODE_OPEN);
  bleCharacteristicThermCalib.setWriteCallback(therm_calibration_callback);
  bleCharacteristicThermCalib.begin();
  bleCharacteristicStrainCalib.setProperties(CHR_PROPS_WRITE | CHR_PROPS_READ);
  bleCharacteristicStrainCalib.setPermission(SECMODE_OPEN, SECMODE_OPEN);
  bleCharacteristicStrainCalib.setWriteCallback(strain_calibration_callback);
  bleCharacteristicStrainCalib.begin();
  bleCharacteristicRPMCalib.setProperties(CHR_PROPS_WRITE | CHR_PROPS_READ);
  bleCharacteristicRPMCalib.setPermission(SECMODE_OPEN, SECMODE_OPEN);
  bleCharacteristicRPMCalib.setWriteCallback(rpm_calibration_callback);
  bleCharacteristicRPMCalib.begin();
  Serial.println("Service and Characteristic Setup finished");
}

void setup_ble_advertising() {
  Bluefruit.Advertising.addFlags(BLE_GAP_ADV_FLAGS_LE_ONLY_GENERAL_DISC_MODE);
  Bluefruit.Advertising.addTxPower();
  Bluefruit.Advertising.addService(bledis);
  Bluefruit.Advertising.addService(blebas);
  Bluefruit.Advertising.addService(brakeSensorService);
  Bluefruit.Advertising.addName();
  Bluefruit.Advertising.restartOnDisconnect(true);
  Bluefruit.Advertising.setInterval(32, 244);
  Bluefruit.Advertising.setFastTimeout(30);
  Bluefruit.Advertising.start(0);
  Serial.println("Advertising Setup finished");
}

void connect_callback(uint16_t conn_handle) {
  Serial.println("Connected");
}

void disconnect_callback(uint16_t conn_handle, uint8_t reason) {
  Serial.println("Disconnected");
}

void therm_calibration_callback(uint16_t conn_handle, BLECharacteristic *chr, uint8_t *data, uint16_t len) {
  String command = String((char *)data);

  if (command.startsWith("CALIBRATE:")) {
    // Parse the reference temperature for calibration
    float referenceTemperature = command.substring(10).toFloat();

    // Call the temperature sensor calibration function
    temperatureSensor.calibrate(referenceTemperature);

    // Respond with a message
    chr->write("Temperature calibrated", 22);
  } else {
    Serial.println("Unknown command");
    chr->write("Unknown command", 15);
  }
}

void strain_calibration_callback(uint16_t conn_handle, BLECharacteristic *chr, uint8_t *data, uint16_t len) {
  String command = String((char *)data);

  if (command.startsWith("CALIBRATE")) {
    // Call the strain gauge calibration function
    strainGaugeSensor.calibrate();

    // Respond with a message
    chr->write("Calibration successful", 22);
  } else if (command.startsWith("TARE")) {
    // Call the strain gauge tare function
    strainGaugeSensor.tare();

    // Respond with a message
    chr->write("Tare successful", 14);
  } else if (command.startsWith("SCALE:")) {
    // Set the scale factor
    float factor = command.substring(6).toFloat();
    strainGaugeSensor.setScale(factor);

    // Respond with a message
    chr->write("Scale factor set", 16);
  } else {
    Serial.println("Unknown command");
    chr->write("Unknown command", 15);
  }
}


void rpm_calibration_callback(uint16_t conn_handle, BLECharacteristic *chr, uint8_t *data, uint16_t len) {
  // Call the wheel RPM calibration function

  String command = String((char *)data);
  uint8_t newMagnetCount = command.toInt();

  if (newMagnetCount > 0) {
    Serial.print("Updating magnet count to: ");
    Serial.println(newMagnetCount);

    hallSensor.setMagnetCount(newMagnetCount);

    // Send feedback after updating the magnet count
    String feedback = "Magnet count updated to: " + String(newMagnetCount);
    chr->write(feedback.c_str());
  } else {
    Serial.println("Invalid data received for magnet count update");

    // Send feedback about the invalid data
    String feedback = "Invalid data received for magnet count update";
    chr->write(feedback.c_str());
  }
}


void loop() {
  // Call readAndAverageSensors() every 100 ms
  unsigned long currentMillis = millis();
   if (currentMillis - lastReadMillis >= readInterval) {
     readAndAverageSensors();
     blinkRedLEDOnce();
     lastReadMillis = currentMillis;
   }
  // Call sendData() every 1000 ms
  if (Bluefruit.connected()){
  if (currentMillis - lastNotifyMillis >= notifyInterval) {
    sendNotifications();
    blinkGreenLEDOnce();
    lastNotifyMillis = currentMillis;
  }
  }
  if (currentMillis - lastBatteryMillis >= batteryInterval) {
    //blebas.notify(map(battery.GetBatteryVoltage(),3.0,4.2,0,100));
    blebas.notify(50);
    lastBatteryMillis = currentMillis;
  }  
}

void readAndAverageSensors() {
  const int numSamples = 10;
  float temperatureSum = 0;
  float strainGaugeSum = 0;
  float wheelSpeedSum = 0;

  for (int i = 0; i < numSamples; i++) {
    temperatureSum += temperatureSensor.readTemperature();
    strainGaugeSum += strainGaugeSensor.read();
    wheelSpeedSum += hallSensor.readSpeedRadS();
  }

  avgTemperature = temperatureSum / numSamples;
  avgStrainGaugeValue = strainGaugeSum / numSamples;
  avgWheelSpeedRadS = wheelSpeedSum / numSamples;
}

void sendNotifications() {
  // Convert floating-point values to byte arrays
  uint8_t temperatureBytes[sizeof(avgTemperature)];
  memcpy(temperatureBytes, &avgTemperature, sizeof(avgTemperature));

  uint8_t strainGaugeBytes[sizeof(avgStrainGaugeValue)];
  memcpy(strainGaugeBytes, &avgStrainGaugeValue, sizeof(avgStrainGaugeValue));

  uint8_t speedBytes[sizeof(avgWheelSpeedRadS)];
  memcpy(speedBytes, &avgWheelSpeedRadS, sizeof(avgWheelSpeedRadS));

  // Print averaged values to the Serial monitor
  Serial.print("Avg Temperature: ");
  Serial.print(avgTemperature);
  Serial.print(" | Avg Strain Gauge Value: ");
  Serial.print(avgStrainGaugeValue);
  Serial.print(" | Avg Wheel Speed (rad/s): ");
  Serial.println(avgWheelSpeedRadS);

  // Transmit data only when a BLE connection is established
  if (Bluefruit.connected()) {
    // Send notifications
    bleCharacteristicTherm.notify(temperatureBytes, sizeof(avgTemperature));
    bleCharacteristicStrain.notify(strainGaugeBytes, sizeof(avgStrainGaugeValue));
    bleCharacteristicRPM.notify(speedBytes, sizeof(avgWheelSpeedRadS));
  }
}

void writeToCSV() {
  // Function to write raw data into a .csv file for later detailed review
}

unsigned long previousMillisGreen = 0;
unsigned long previousMillisRed = 0;
const unsigned long intervalGreen = 50;
const unsigned long intervalRed = 50;

void blinkGreenLEDOnce() {
  unsigned long currentMillis = millis();

  if (currentMillis - previousMillisGreen >= intervalGreen) {
    static bool ledStateGreen = false;

    digitalWrite(LED_GREEN, ledStateGreen);
    ledStateGreen = !ledStateGreen;
    previousMillisGreen = currentMillis;
  }
}

void blinkRedLEDOnce() {
  unsigned long currentMillis = millis();

  if (currentMillis - previousMillisRed >= intervalRed) {
    static bool ledStateRed = false;

    digitalWrite(LED_RED, ledStateRed);
    ledStateRed = !ledStateRed;
    previousMillisRed = currentMillis;
  }
}







#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include "StrainGaugeSensor.h"
#include "MLX90614Sensor.h"
#include "HallSensor.h"
#include <WiFi.h>
#include <time.h>



#define SERVICE_UUID               "06633474-1e8e-43aa-a85f-02f8c2814fb2"
#define THERMAL_CHAR_UUID          "a5bfea66-efec-4808-b472-2ac3d0c5a0ef"
#define STRAIN_CHAR_UUID           "0ec3dcce-9610-4d0b-9a66-338ca2097fa0"
#define RPM_CHAR_UUID              "c51dfdea-ecd7-4fc1-872c-0076f2428d27"
#define UUID128_CHR_THERMAL_CALIB  "20eeb27c-8244-4868-8528-9b878049fea8"
#define UUID128_CHR_STRAIN_CALIB   "e0f72bb5-c6f3-4953-9b2c-90db43906bf8"
#define UUID128_CHR_RPM_CALIB      "c2e40308-dbeb-4fe2-b76d-8861a4306599"
#define DATA_PACKET_CHAR_UUID        "9be68165-d986-47e9-9624-8abc47dfe306"

void therm_calibration_callback(uint16_t conn_handle, BLECharacteristic *chr, uint8_t *data, uint16_t len);
void strain_calibration_callback(uint16_t conn_handle, BLECharacteristic *chr, uint8_t *data, uint16_t len);
void rpm_calibration_callback(uint16_t conn_handle, BLECharacteristic *chr, uint8_t *data, uint16_t len);


const uint8_t DOUT_PIN = 18;
const uint8_t CLK_PIN = 19;
float strainGaugeScaleFactor = 2000;
StrainGaugeSensor strainGaugeSensor(DOUT_PIN, CLK_PIN);
MLX90614Sensor temperatureSensor;

const uint8_t HALL_SENSOR_PIN = 4;
const uint8_t MAGNET_COUNT = 1;
HallSensor hallSensor(HALL_SENSOR_PIN, MAGNET_COUNT);

const char* ssid = "iPhone von Johannes";
const char* password = "12345678";
const char* ntpServer = "pool.ntp.org";    // NTP Server
const long  gmtOffset_sec = 3600;          // Offset for your timezone in seconds. This is for GMT +1. Adjust accordingly.
const int   daylightOffset_sec = 3600;     // If daylight saving is used, adjust accordingly. This is for 1 hour daylight saving.
// Constants for timeouts
const uint32_t WIFI_CONNECTION_TIMEOUT_MS = 10000;  // 10 seconds
const uint32_t NTP_SYNC_TIMEOUT_MS = 10000;         // 10 seconds
const time_t NTP_REFERENCE_TIMESTAMP = 1510644967;   // Nov 14 2017

#pragma pack(push, 1) // Ensures no padding
struct DataPacket {
    uint32_t timestamp;
    float torque;
    float temperature;
    uint16_t rpm;
};
#pragma pack(pop)



BLEServer *pServer = NULL;
BLECharacteristic *pCharacteristicThermal = NULL;
BLECharacteristic *pCharacteristicStrain = NULL;
BLECharacteristic *pCharacteristicRPM = NULL;
BLECharacteristic *pCharacteristicThermalCalib = NULL;
BLECharacteristic *pCharacteristicStrainCalib = NULL;
BLECharacteristic *pCharacteristicRPMCalib = NULL;
BLECharacteristic *pCharacteristicDataPacket = NULL;

float avgTemperature = 0;
float avgStrainGaugeValue = 0;
float avgWheelSpeedRadS = 0;

unsigned long lastReadMillis = 0;
unsigned long readInterval = 100;

unsigned long lastNotifyMillis = 0;
unsigned long notifyInterval = 1000;

bool isTaring = false;
bool isRecording = false;

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) override {
        Serial.println("Connected");
    }

    void onDisconnect(BLEServer* pServer) override {
        Serial.println("Disconnected");
        isRecording = false;
    }
};

class ThermCalibrationCallbacks : public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *characteristic) override {
        therm_calibration_callback(0, characteristic, (uint8_t*) characteristic->getValue().c_str(), characteristic->getValue().length());
    }
};

class StrainCalibrationCallbacks : public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *characteristic) override {
        strain_calibration_callback(0, characteristic, (uint8_t*) characteristic->getValue().c_str(), characteristic->getValue().length());
    }
};

class RPMCalibrationCallbacks : public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *characteristic) override {
        rpm_calibration_callback(0, characteristic, (uint8_t*) characteristic->getValue().c_str(), characteristic->getValue().length());
    }
};

void setup() {
    Serial.begin(115200);
    strainGaugeSensor.begin();
    strainGaugeSensor.setScale(strainGaugeScaleFactor);
    strainGaugeSensor.tare();
    temperatureSensor.begin();
    hallSensor.begin();

    BLEDevice::init("OpenBrakes");
    pServer = BLEDevice::createServer();

    pServer->setCallbacks(new MyServerCallbacks());

    BLEService *pService = pServer->createService(SERVICE_UUID);

    pCharacteristicThermal = pService->createCharacteristic(THERMAL_CHAR_UUID, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
    pCharacteristicStrain = pService->createCharacteristic(STRAIN_CHAR_UUID, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
    pCharacteristicRPM = pService->createCharacteristic(RPM_CHAR_UUID, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
    pCharacteristicDataPacket = pService->createCharacteristic(DATA_PACKET_CHAR_UUID,BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
);

    // Create calibration characteristics
pCharacteristicThermalCalib = pService->createCharacteristic(
    UUID128_CHR_THERMAL_CALIB, 
    BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_READ
);
pCharacteristicStrainCalib = pService->createCharacteristic(
    UUID128_CHR_STRAIN_CALIB, 
    BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_READ
);
pCharacteristicRPMCalib = pService->createCharacteristic(
    UUID128_CHR_RPM_CALIB, 
    BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_READ
);
    // Set the callback handlers
    pCharacteristicThermalCalib->setCallbacks(new ThermCalibrationCallbacks());
    pCharacteristicStrainCalib->setCallbacks(new StrainCalibrationCallbacks());
    pCharacteristicRPMCalib->setCallbacks(new RPMCalibrationCallbacks());

    pService->start();

    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->start();
    Serial.print("Connecting to ");
    Serial.println(ssid);
    Serial.println(connectWiFi(WIFI_CONNECTION_TIMEOUT_MS) ? "WiFi connected" : "WiFi connection failed or timed out.");

    Serial.println(syncNTP(NTP_SYNC_TIMEOUT_MS) ? "Time set successfully." : "NTP time synchronization failed or timed out.");
    Serial.println("Setup finished");

}

void loop() {
    unsigned long currentMillis = millis();
    if (!isTaring && !isRecording) {
        if (currentMillis - lastReadMillis >= readInterval) {
            readAndAverageSensors();
            lastReadMillis = currentMillis;
        }
    
        if (currentMillis - lastNotifyMillis >= notifyInterval) {
            sendNotifications();
            printCurrentTime();
            lastNotifyMillis = currentMillis;
        }
    }
    if (isRecording) {
        broadcastDataPacket();
        delay(50);
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

  // Print the averaged sensor values
  Serial.print("Avg Temperature: "); Serial.println(avgTemperature);
  Serial.print("Avg Strain Gauge: "); Serial.println(avgStrainGaugeValue);
  Serial.print("Avg Wheel Speed (Rad/s): "); Serial.println(avgWheelSpeedRadS);
}

void sendNotifications() {
  // Convert floating-point values to byte arrays
  uint8_t temperatureBytes[sizeof(avgTemperature)];
  memcpy(temperatureBytes, &avgTemperature, sizeof(avgTemperature));

  uint8_t strainGaugeBytes[sizeof(avgStrainGaugeValue)];
  memcpy(strainGaugeBytes, &avgStrainGaugeValue, sizeof(avgStrainGaugeValue));

  uint8_t speedBytes[sizeof(avgWheelSpeedRadS)];
  memcpy(speedBytes, &avgWheelSpeedRadS, sizeof(avgWheelSpeedRadS));

  pCharacteristicThermal->setValue(temperatureBytes, sizeof(avgTemperature));
  pCharacteristicThermal->notify();

  pCharacteristicStrain->setValue(strainGaugeBytes, sizeof(avgStrainGaugeValue));
  pCharacteristicStrain->notify();

  pCharacteristicRPM->setValue(speedBytes, sizeof(avgWheelSpeedRadS));
  pCharacteristicRPM->notify();
}

void therm_calibration_callback(uint16_t conn_handle, BLECharacteristic *chr, uint8_t *data, uint16_t len) {
  String command = String((char *)data);

  if (command.startsWith("CALIBRATE:")) {
    // Parse the reference temperature for calibration
    float referenceTemperature = command.substring(10).toFloat();

    // Call the temperature sensor calibration function
    temperatureSensor.calibrate(referenceTemperature);

    // Respond with a message
    chr->setValue((uint8_t*)"Temperature calibrated", 22);
  } else {
    Serial.println("Unknown command");
    chr->setValue((uint8_t*)"Unknown command", 15);
  }
}

void strain_calibration_callback(uint16_t conn_handle, BLECharacteristic *chr, uint8_t *data, uint16_t len) {
  String command = String((char *)data);

  if (command.startsWith("CALIBRATE:")) {
    isTaring = true;
    delay(5000);
    Serial.println("Calibration initial delay");
    float knownWeight = command.substring(10).toFloat();
    strainGaugeSensor.calibrate(knownWeight);
    delay(3000);
    Serial.println("Calibration exit delay");
    isTaring = false;

    // Since the calibrate function is now void, you may want to retrieve the scale in another way, 
    // e.g., from a member function of strainGaugeSensor like strainGaugeSensor.getScale(). 
    // For the purpose of this example, I'm assuming such a function exists:
    float scale = strainGaugeSensor.getScale();
    
    // Respond with the updated scale factor
    String feedback = "Updated scale factor: " + String(scale, 4); // 4 decimal places
    Serial.println("Calibration finished, Scale factor is now " + String(scale));
    chr->setValue((uint8_t*)feedback.c_str(), feedback.length());
  } else if (command.startsWith("TARE")) {
    // Call the strain gauge tare function
    isTaring = true;
    delay(5000);
    Serial.println("Tare intial delay");
    strainGaugeSensor.tare();
    delay(3000);
    Serial.println("Tare exit delay");
    isTaring = false;  

    // Respond with a message
    chr->setValue((uint8_t*)"Tare successful", 14);
  } else if (command.startsWith("SCALE:")) {
    // Set the scale factor
    isTaring = true;
    delay(5000);
    Serial.println("Scale intial delay");
    float factor = command.substring(6).toFloat();
    strainGaugeSensor.setScale(factor);
    delay(3000);
    Serial.println("Scale exit delay");
    isTaring = false; 

    // Respond with a message
    chr->setValue((uint8_t*)"Scale factor set", 16);
  } else {
    Serial.println("Unknown command");
    chr->setValue((uint8_t*)"Unknown command", 15);
  }
}



void rpm_calibration_callback(uint16_t conn_handle, BLECharacteristic *chr, uint8_t *data, uint16_t len) {
  String command = String((char *)data);

  // Handle Start Recording command
  if (command.startsWith("START_REC")) {
    isRecording = true;
    Serial.println("Recording started");
    chr->setValue((uint8_t*)"Recording started", 17);

  // Handle Stop Recording command
  } else if (command.startsWith("STOP_REC")) {
    isRecording = false;
    Serial.println("Recording stopped");
    chr->setValue((uint8_t*)"Recording stopped", 17);

  // Handle magnet count calibration
  } else {
    uint8_t newMagnetCount = command.toInt();
    if (newMagnetCount > 0) {
      Serial.print("Updating magnet count to: ");
      Serial.println(newMagnetCount);
      hallSensor.setMagnetCount(newMagnetCount);
      // Send feedback after updating the magnet count
      String feedback = "Magnet count updated to: " + String(newMagnetCount);
      chr->setValue((uint8_t*)feedback.c_str(), feedback.length());
    } else {
      Serial.println("Invalid data received for magnet count update");
      // Send feedback about the invalid data
      String feedback = "Invalid data received for magnet count update";
      chr->setValue((uint8_t*)feedback.c_str(), feedback.length());
    }
  }
}

bool connectWiFi(uint32_t timeout) {
    uint32_t startMillis = millis();
    WiFi.begin(ssid, password);
    while (WiFi.status() != WL_CONNECTED && millis() - startMillis < timeout) {
        delay(500);
    }
    return WiFi.status() == WL_CONNECTED;
}

bool syncNTP(uint32_t timeout) {
    configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
    uint32_t startMillis = millis();
    while (time(nullptr) <= NTP_REFERENCE_TIMESTAMP && millis() - startMillis < timeout) {
        delay(500);
    }
    return time(nullptr) > NTP_REFERENCE_TIMESTAMP;
}

void printCurrentTime() {
  time_t now;
  struct tm timeinfo;
  
  time(&now); // Get the current time
  localtime_r(&now, &timeinfo); // Convert the time structure

  Serial.printf("Current time: %04d-%02d-%02d %02d:%02d:%02d\n",
                timeinfo.tm_year + 1900,
                timeinfo.tm_mon + 1,
                timeinfo.tm_mday,
                timeinfo.tm_hour,
                timeinfo.tm_min,
                timeinfo.tm_sec);
}

void broadcastDataPacket() {
    DataPacket packet;
    
    packet.timestamp = time(nullptr); // Current time
    packet.torque = strainGaugeSensor.read(); // Assuming a readValue function or similar
    packet.temperature = temperatureSensor.readTemperature();
    packet.rpm = hallSensor.readSpeedRadS();

    pCharacteristicDataPacket->setValue((uint8_t*)&packet, sizeof(packet));
    pCharacteristicDataPacket->notify();
}


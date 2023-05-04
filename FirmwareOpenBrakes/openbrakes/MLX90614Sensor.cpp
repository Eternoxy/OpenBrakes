#include "MLX90614Sensor.h"
#include <Arduino.h>

MLX90614Sensor::MLX90614Sensor() : calibrationOffset(0.0) {
}

void MLX90614Sensor::begin() {
  mlx.begin();
}

float MLX90614Sensor::readTemperature() {
  // Commented out the original read function
  // return mlx.readObjectTempC() + calibrationOffset;

  // Return random numbers between 20 and 500 for testing
  return random(20, 501);
}

void MLX90614Sensor::calibrate(float referenceTemperature) {
  float currentTemperature = mlx.readObjectTempC();
  calibrationOffset = referenceTemperature - currentTemperature;

  // Print the calibration information to the Serial
  Serial.print("Temperature calibration: Reference Temperature = ");
  Serial.print(referenceTemperature);
  Serial.print(" °C, Current Temperature = ");
  Serial.print(currentTemperature);
  Serial.print(" °C, Calibration Offset = ");
  Serial.print(calibrationOffset);
  Serial.println(" °C");
}
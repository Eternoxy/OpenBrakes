#include "StrainGaugeSensor.h"

StrainGaugeSensor::StrainGaugeSensor(uint8_t dout, uint8_t clk) : _dout(dout), _clk(clk), _calibration_factor(1.0) {
}

void StrainGaugeSensor::begin() {
  _hx711.begin(_dout, _clk);
  _hx711.set_scale(_calibration_factor);
}

void StrainGaugeSensor::calibrate() {
  // Add your calibration logic here
  Serial.println("Strain gauge calibration triggered");
}

void StrainGaugeSensor::tare() {
  _hx711.tare();
  Serial.println("Strain gauge tare triggered");
}

void StrainGaugeSensor::setScale(float factor) {
  _calibration_factor = factor;
  _hx711.set_scale(_calibration_factor);
  Serial.print("Setting strain gauge scale factor to: ");
  Serial.println(factor);
}

float StrainGaugeSensor::read() {
  // Uncomment the line below to read actual values from the HX711
  // return _hx711.get_units(1);
  
  // Return a random float value between 50.0 and 100.0 for testing
  return random(500, 1000)/10.0;
}

long StrainGaugeSensor::readLong() {
  // Uncomment the line below to read actual values from the HX711
  // return _hx711.read();

  // Return a random long value between -10000 and 10000 for testing
  return random(-10000, 10000);
}

// sensors.h
#ifndef SENSORS_H
#define SENSORS_H

#include <Arduino.h>

void sensors_init() {
  // Initialize sensors (if needed)
}

float read_mlx90614() {
  static uint8_t counter = 0;
  float temperature = counter;
  counter = (counter + 1) % 128;
  return temperature;
}

long read_hx711() {
  static uint8_t counter = 0;
  long strain_gauge_value = counter;
  counter = (counter + 1) % 128;
  return strain_gauge_value;
}

int read_hall_sensor() {
  static uint8_t counter = 0;
  int wheel_rpm = counter;
  counter = (counter + 1) % 128;
  return wheel_rpm;
}

#endif // SENSORS_H

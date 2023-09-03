#include "HallSensor.h"

HallSensor* HallSensor::_instance = nullptr;

HallSensor::HallSensor(uint8_t pin, uint8_t magnetCount)
    : _pin(pin), _magnetCount(magnetCount), _magnetPasses(0), _lastMillis(0) {
    _instance = this;
}

void HallSensor::begin() {
    pinMode(_pin, INPUT_PULLUP);
    attachInterrupt(digitalPinToInterrupt(_pin), isrStatic, RISING);
}

float HallSensor::readSpeedRadS() {
    uint32_t currentTime = millis();
    uint32_t elapsedTime = currentTime - _lastMillis;

    const uint32_t SHORT_DURATION = 1000; // 1 second
    const uint32_t LONG_DURATION = 5000; // 5 seconds

    // If the elapsed time is too short (below 1s) and the number of magnet passes is below threshold, just return the last speed.
    if(elapsedTime < SHORT_DURATION && _magnetPasses < _magnetCount) {
        return _lastSpeed;
    }

    // If speed is very low (elapsed time goes beyond 5 seconds), and we haven't reached a full wheel revolution, just return the last speed.
    if(elapsedTime < LONG_DURATION && _magnetPasses < _magnetCount) {
        return _lastSpeed;
    }

    // Calculate speed
    float wheelRevolutions = (float)_magnetPasses / (float)_magnetCount;
    float revolutionsPerMinute = (wheelRevolutions * 60000.0) / elapsedTime;
    _lastSpeed = (revolutionsPerMinute * 2.0 * PI) / 60.0;

    // Reset
    _magnetPasses = 0;
    _lastMillis = currentTime;

    return _lastSpeed;
}

void HallSensor::setMagnetCount(uint8_t magnetCount) {
    _magnetCount = magnetCount;
}

void HallSensor::isr() {
    _magnetPasses++;
}

void HallSensor::isrStatic() {
    if (_instance) {
        _instance->isr();
    }
}

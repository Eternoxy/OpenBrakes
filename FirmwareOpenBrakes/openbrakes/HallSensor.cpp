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
    // Comment out the actual measurement and return a random number between 0 and 5
    /*
    uint32_t magnetPasses = _magnetPasses;
    uint32_t lastMillis = _lastMillis;
    uint32_t currentTime = millis();

    uint32_t elapsedTime = currentTime - lastMillis;
    if (elapsedTime == 0) {
        elapsedTime = 1;
    }

    _magnetPasses = 0;
    _lastMillis = currentTime;

    float wheelRevolutions = (float)magnetPasses / (float)_magnetCount;
    float revolutionsPerMinute = (wheelRevolutions * 60000.0) / elapsedTime;
    return (revolutionsPerMinute * 2.0 * PI) / 60.0;
    */
    return random(0, 6); // Generates a random number between 0 and 5
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

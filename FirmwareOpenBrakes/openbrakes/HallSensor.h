#ifndef HallSensor_h
#define HallSensor_h

#include <Arduino.h>

class HallSensor {
public:
    HallSensor(uint8_t pin, uint8_t magnetCount);
    void begin();
    float readSpeedRadS();
    void setMagnetCount(uint8_t magnetCount);
    void isr();
    static void isrStatic();

private:
    uint8_t _pin;
    uint8_t _magnetCount;
    volatile uint32_t _magnetPasses;
    volatile uint32_t _lastMillis;
    static HallSensor* _instance;
    float _lastSpeed; 
};

#endif

#ifndef StrainGaugeSensor_h
#define StrainGaugeSensor_h

#include "Arduino.h"
#include <HX711.h>

class StrainGaugeSensor {
  public:
    StrainGaugeSensor(uint8_t dout, uint8_t clk);
    
    void begin();
    void calibrate();
    void tare();
    void setScale(float factor);
    float read();
    long readLong();

  private:
    uint8_t _dout;
    uint8_t _clk;
    HX711 _hx711;
    float _calibration_factor;
};

#endif
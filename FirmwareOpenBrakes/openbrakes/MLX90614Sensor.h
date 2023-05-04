#ifndef MLX90614SENSOR_H
#define MLX90614SENSOR_H

#include <Wire.h>
#include <Adafruit_MLX90614.h>

class MLX90614Sensor {
  public:
    MLX90614Sensor();
    void begin();
    float readTemperature();
    void calibrate(float referenceTemperature);

  private:
    Adafruit_MLX90614 mlx;
    float calibrationOffset;
};

#endif

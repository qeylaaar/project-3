#include <ESP32Servo.h>

Servo s;
void setup() {
  Serial.begin(115200);
  ESP32PWM::allocateTimer(0);
  s.setPeriodHertz(50);
  s.attach(14, 500, 2400); // Kita pake pin 14 (IO14)
  Serial.println("ESP32-CAM SIAP!");
}

void loop() {
  s.write(0);   delay(1000);
  s.write(180); delay(1000);
}
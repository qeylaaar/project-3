#include <WiFi.h>
#include <HTTPClient.h>
#include <ESP32Servo.h>

const char* ssid = "aru"; 
const char* password = "asukayang";

// SESUAIKAN: Ganti ke route API Laravel kamu
// Contoh: http://10.151.203.5/spqc-laravel/public/api/nanas/update?status=
const String serverUrl = "http://10.151.203.5/api/nanas/status?status="; 

Servo myservo;
int servoPin = 27; 
bool isMatang = false;
unsigned long lastTime = 0;
unsigned long timerDelay = 10000; 

void setup() {
  Serial.begin(115200);
  
  ESP32PWM::allocateTimer(0);
  myservo.setPeriodHertz(50);
  myservo.attach(servoPin, 500, 2400);
  myservo.write(90); 

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi OK! ESP32 siap kirim data ke Laravel.");
}

void loop() {
  if ((millis() - lastTime) > timerDelay) {
    String statusKirim = isMatang ? "Mentah" : "Matang";
    int sudutServo = isMatang ? 90 : 0;

    myservo.write(sudutServo);
    
    // Kirim ke Laravel
    if (WiFi.status() == WL_CONNECTED) {
      HTTPClient http;
      String fullUrl = serverUrl + statusKirim;
      
      http.begin(fullUrl);
      int httpCode = http.GET(); 
      
      if (httpCode > 0) {
        Serial.printf("[Laravel] Status: %s, Response: %d\n", statusKirim.c_str(), httpCode);
      }
      http.end();
    }

    isMatang = !isMatang;
    lastTime = millis();
  }
}
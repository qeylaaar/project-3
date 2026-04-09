#include <WiFi.h>
#include <HTTPClient.h>
#include <ESP32Servo.h>
#include <ArduinoJson.h>

const char* ssid = "aruuu";           
const char* password = "alva123asd";  
const String url = "http://192.168.137.1:8000/api/pineapple/latest";

Servo myservo;
int servoPin = 27; 
int lastDataId = 0; // <--- INI "INGATAN" ESP32

void setup() {
  Serial.begin(115200);
  ESP32PWM::allocateTimer(0);
  myservo.setPeriodHertz(50);
  myservo.attach(servoPin, 500, 2400);
  
  myservo.write(90); // Posisi awal netral
  
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) { delay(500); Serial.print("."); }
  Serial.println("\n[WiFi] Connected!");
}

void loop() {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(url);
    int httpCode = http.GET();

    if (httpCode == 200) {
      String payload = http.getString();
      StaticJsonDocument<512> doc;
      deserializeJson(doc, payload);

      int currentId = doc["id"]; // Ambil ID data terbaru
      String statusNanas = doc["status"].as<String>();

      // --- LOGIKA "ANTI-GERAK-TERUS" ---
      // Cek apakah ID sekarang berbeda dengan ID terakhir yang diproses
      if (currentId > lastDataId) { 
        Serial.print("[NEW DATA!] Processing ID: ");
        Serial.println(currentId);
        
        // Update ingatan ESP32 agar tidak memproses ID ini lagi
        lastDataId = currentId; 

        if (statusNanas == "RIPE") {
          Serial.println("[Action] MATANG -> Gerak ke 0");
          myservo.write(0);
          delay(2000); 
          myservo.write(90); // Balik netral
        } 
        else if (statusNanas == "UNRIPE" || statusNanas == "RAW") {
          Serial.println("[Action] MENTAH -> Gerak ke 180");
          myservo.write(180);
          delay(2000);
          myservo.write(90); // Balik netral
        }
      } else {
        // ID masih sama, berarti belum ada nanas baru dari Python
        Serial.println("[Skip] Data lama (ID sama), servo diam.");
      }

    }
    http.end();
  }
  delay(2000); // Cek ke Laravel tiap 2 detik
}
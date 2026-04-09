#include <WiFi.h>
#include <HTTPClient.h>
#include <ESP32Servo.h>
#include <ArduinoJson.h>

// --- KONFIGURASI WIFI ---
const char* ssid = "HotspotNanas";   // Sesuai nama hotspot laptop
const char* password = "12345678";   // Sesuai password hotspot laptop

// --- KONFIGURASI API ---
// Pastikan IP ini sesuai dengan IP laptop (php artisan serve --host=0.0.0.0)
const String url = "http://192.168.137.1:8000/api/pineapple/latest";

Servo myservo;
int servoPin = 27;

void setup() {
  // Wajib 115200 agar monitor tidak kosong/karakter aneh
  Serial.begin(115200);
  delay(1000); 
  
  Serial.println("\n==============================");
  Serial.println("   SPQC SYSTEM STARTING...    ");
  Serial.println("==============================");

  // Inisialisasi Servo
  ESP32PWM::allocateTimer(0);
  myservo.setPeriodHertz(50);
  myservo.attach(servoPin, 500, 2400);
  
  // Test Gerak Awal (Biar tahu servo hidup)
  Serial.println("[Servo] Testing movement to 90...");
  myservo.write(90);
  delay(1000);

  // Koneksi WiFi
  Serial.print("[WiFi] Connecting to: ");
  Serial.println(ssid);
  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\n[WiFi] Connected!");
  Serial.print("[WiFi] IP Address: ");
  Serial.println(WiFi.localIP());
  Serial.println("------------------------------");
}

void loop() {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    
    Serial.print("[HTTP] GET latest status... ");
    http.begin(url);
    int httpCode = http.GET();

    if (httpCode == 200) {
      String payload = http.getString();
      Serial.println("OK");
      
      StaticJsonDocument<200> doc;
      DeserializationError error = deserializeJson(doc, payload);

      if (!error) {
        String status = doc["status"];
        Serial.print("[Data] Status dari Laravel: ");
        Serial.println(status);

        // Logika Gerak Servo
        if (status == "RIPE") {
          Serial.println("[Servo] Moving to 0 (Grade A)");
          myservo.write(0);
        } 
        else if (status == "HALF_RIPE") {
          Serial.println("[Servo] Moving to 90 (Grade B)");
          myservo.write(90);
        } 
        else if (status == "RAW") {
          Serial.println("[Servo] Moving to 180 (Grade C)");
          myservo.write(180);
        }
      } else {
        Serial.print("[Error] JSON Parse failed: ");
        Serial.println(error.c_str());
      }
    } else {
      Serial.print("[Error] HTTP Failed, code: ");
      Serial.println(httpCode);
    }
    http.end();
  } else {
    Serial.println("[Error] WiFi Disconnected!");
  }

  Serial.println("------------------------------");
  delay(3000); // Cek ulang tiap 3 detik
}
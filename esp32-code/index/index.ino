#include <WiFi.h>
#include <HTTPClient.h>
#include <ESP32Servo.h>
#include <ArduinoJson.h>

const char* ssid = "aruuu"; 
const char* password = "alva123asd";  
const String url = "http://192.168.137.1:8000/api/pineapple/latest";

Servo myservo;
int servoPin = 27; 
int lastDataId = 0; 

void setup() {
  Serial.begin(115200);
  ESP32PWM::allocateTimer(1); 
  myservo.setPeriodHertz(50);
  
  // Posisi Awal 90
  myservo.attach(servoPin, 500, 2400); 
  myservo.write(90); 
  delay(500); // Kurangi delay awal
  myservo.detach(); 
  
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) { delay(200); Serial.print("."); }
  Serial.println("\n[WiFi] Connected!");
}

// ... (bagian atas tetap sama)

void loop() {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    // Set timeout lebih pendek agar tidak nunggu kelamaan kalau server sibuk
    http.setTimeout(500); 
    http.begin(url);
    
    int httpCode = http.GET();

    if (httpCode == 200) {
      // Pakai Stream agar parsing JSON lebih cepat daripada ambil String dulu
      StaticJsonDocument<256> doc; // Ukuran diperkecil agar alokasi memori cepat
      deserializeJson(doc, http.getStream());

      int currentId = doc["id"]; 
      const char* statusNanas = doc["status"]; // Pakai const char* lebih ringan dari String

      if (currentId > lastDataId) { 
        lastDataId = currentId; 
        
        myservo.attach(servoPin, 500, 2400); 
        
        // Langsung gerak tanpa delay awal
        if (strcmp(statusNanas, "RIPE") == 0) {
          myservo.write(180); 
          delay(450);  // Pangkas lagi jadi 450ms
          myservo.write(90); 
          delay(400); 
        } 
        else {
          myservo.write(0);   
          delay(450); 
          myservo.write(90); 
          delay(400); 
        }
        
        myservo.detach(); 
      }
    }
    http.end();
  }
  // Polling dipercepat jadi 100ms (Hampir Real-time)
  delay(100); 
}
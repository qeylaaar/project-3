import cv2
import requests
import time
from ultralytics import YOLO
from flask import Flask, Response

app = Flask(__name__)

# --- 1. SETUP MODEL YOLOv11 ---
try:
    model = YOLO("best.pt") 
    print("--------------------------------------------------")
    print("✅ AI Model Loaded Successfully!")
except Exception as e:
    print(f"❌ ERROR: Model gagal dimuat! ({e})")
    exit()

# --- 2. SETUP STREAM ESP32-CAM ---
# Sesuai screenshot Hotspot kamu, IP ESP32 adalah .202
ESP32_IP = "192.168.137.202" 
stream_url = f"http://{ESP32_IP}/mjpeg" 

cap = cv2.VideoCapture(stream_url, cv2.CAP_FFMPEG)
cap.set(cv2.CAP_PROP_BUFFERSIZE, 2)

# --- 3. KONFIGURASI IP GATEWAY HOTSPOT ---
# 192.168.137.1 adalah IP Laptop kamu di jaringan Hotspot sendiri
LAPTOP_IP = "192.168.137.1"
LARAVEL_URL = f"http://{LAPTOP_IP}:8000/api/nanas/status"

last_sent_status = None 
last_send_time = 0      
COOLDOWN_TIME = 3 

def generate_frames():
    global last_sent_status, last_send_time, cap
    
    while True:
        success, frame = cap.read()
        
        if not success:
            print("⚠️ Kamera Terputus! Reconnecting...")
            cap.release()
            time.sleep(2) 
            cap = cv2.VideoCapture(stream_url, cv2.CAP_FFMPEG)
            continue

        # --- 4. DETEKSI AI ---
        results = model(frame, stream=True, conf=0.6, task='detect')
        detected_status = 0
        detected_label = ""

        for r in results:
            for box in r.boxes:
                x1, y1, x2, y2 = map(int, box.xyxy[0])
                cls = int(box.cls[0])
                label = model.names[cls].lower()
                conf = round(float(box.conf[0]) * 100, 1)

                color = (0, 255, 0) if "matured" in label and "unmatured" not in label else (0, 0, 255)
                
                cv2.rectangle(frame, (x1, y1), (x2, y2), color, 2)
                cv2.putText(frame, f"{label.upper()} {conf}%", (x1, y1 - 10), 
                            cv2.FONT_HERSHEY_SIMPLEX, 0.6, color, 2)

                if "matured" in label and "unmatured" not in label:
                    detected_status = 1 
                    detected_label = "matured"
                elif "unmatured" in label:
                    detected_status = 3 
                    detected_label = "unmatured"

        # --- 5. KIRIM KE DB ---
        current_time = time.time()
        if detected_status != 0:
            if (detected_status != last_sent_status) or (current_time - last_send_time > COOLDOWN_TIME):
                try:
                    url_api = f"{LARAVEL_URL}?status={detected_status}"
                    requests.get(url_api, timeout=0.5) 
                    print(f"🚀 [DB UPDATE] {detected_label.upper()}")
                    last_sent_status = detected_status
                    last_send_time = current_time
                except Exception:
                    pass

        # --- 6. ENCODE UNTUK FLUTTER ---
        ret, buffer = cv2.imencode('.jpg', frame)
        if not ret: continue
            
        frame_bytes = buffer.tobytes()
        yield (b'--frame\r\n'
               b'Content-Type: image/jpeg\r\n\r\n' + frame_bytes + b'\r\n')

@app.route('/video_feed')
def video_feed():
    return Response(generate_frames(), mimetype='multipart/x-mixed-replace; boundary=frame')

if __name__ == "__main__":
    print("--------------------------------------------------")
    print(f"🌐 Server AI: http://{LAPTOP_IP}:8888/video_feed")
    print("🍍 Sistem QC Nanas Running...")
    print("--------------------------------------------------")
    # Pakai port 8888 biar gak bentrok sama sistem Windows
    app.run(host='0.0.0.0', port=8888, threaded=True, debug=False)
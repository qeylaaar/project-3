import cv2
import requests
import time
from ultralytics import YOLO
from flask import Flask, Response

app = Flask(__name__)

# --- 1. SETUP MODEL YOLOv11 ---
try:
    model = YOLO("best.pt") 
    print("AI Model Loaded Successfully!")
except Exception as e:
    print(f"ERROR: Model gagal dimuat! ({e})")
    exit()

# --- 2. SETUP STREAM ESP32-CAM ---
ESP32_IP = "192.168.137.8" 
stream_url = f"http://{ESP32_IP}/mjpeg" 

cap = cv2.VideoCapture(stream_url)
cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)

# --- 3. KONFIGURASI API LARAVEL ---
# Pastikan IP ini adalah IP Server Laravel Anda
LARAVEL_URL = "http://192.168.137.1:8000/api/nanas/status"
last_sent_status = None 
last_send_time = 0      
COOLDOWN_TIME = 2 

def generate_frames():
    global last_sent_status, last_send_time, cap
    
    while True:
        success, frame = cap.read()
        if not success:
            print("Kamera Terputus! Reconnecting...")
            cap = cv2.VideoCapture(stream_url)
            time.sleep(1)
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

                # Warna Box (Hijau untuk Matang, Merah untuk Mentah)
                color = (0, 255, 0) if "matured" in label and "unmatured" not in label else (0, 0, 255)
                
                cv2.rectangle(frame, (x1, y1), (x2, y2), color, 2)
                cv2.putText(frame, f"{label} {conf}%", (x1, y1 - 10), 
                            cv2.FONT_HERSHEY_SIMPLEX, 0.6, color, 2)

                if "matured" in label and "unmatured" not in label:
                    detected_status = 1
                    detected_label = label
                elif "unmatured" in label:
                    detected_status = 3
                    detected_label = label

        # --- 5. KIRIM DATA KE LARAVEL ---
        current_time = time.time()
        if detected_status != 0:
            if (detected_status != last_sent_status) or (current_time - last_send_time > COOLDOWN_TIME):
                try:
                    url_api = f"{LARAVEL_URL}?status={detected_status}"
                    requests.get(url_api, timeout=0.5) 
                    print(f"[SENT] {detected_label.upper()} -> ID: {detected_status}")
                    last_sent_status = detected_status
                    last_send_time = current_time
                except Exception:
                    pass

        # --- 6. ENCODE FRAME UNTUK STREAM ---
        ret, buffer = cv2.imencode('.jpg', frame)
        frame_bytes = buffer.tobytes()
        yield (b'--frame\r\n'
               b'Content-Type: image/jpeg\r\n\r\n' + frame_bytes + b'\r\n')

@app.route('/video_feed')
def video_feed():
    return Response(generate_frames(), mimetype='multipart/x-mixed-replace; boundary=frame')

if __name__ == "__main__":
    # Jalankan server di port 5000 agar bisa diakses Flutter
    print("--------------------------------------------------")
    print("AI Stream Server Active at: http://YOUR_PC_IP:5000/video_feed")
    print("Sistem QC Nanas Berjalan...")
    print("--------------------------------------------------")
    app.run(host='0.0.0.0', port=5000, threaded=True)
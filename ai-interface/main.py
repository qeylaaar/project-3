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
ESP32_IP = "192.168.137.202" 
stream_url = f"http://{ESP32_IP}/mjpeg" 

def koneksi_kamera():
    """Fungsi untuk inisialisasi ulang kamera dengan timeout FFMPEG"""
    c = cv2.VideoCapture(stream_url, cv2.CAP_FFMPEG)
    # Paksa timeout FFMPEG ke 5 detik (5000ms) agar tidak stuck selamanya
    c.set(cv2.CAP_PROP_OPEN_TIMEOUT_MSEC, 5000)
    c.set(cv2.CAP_PROP_BUFFERSIZE, 1)
    return c

cap = koneksi_kamera()

# --- 3. KONFIGURASI IP GATEWAY HOTSPOT ---
LAPTOP_IP = "192.168.137.1"
LARAVEL_URL = f"http://{LAPTOP_IP}:8000/api/nanas/status"

last_sent_status = None 
last_send_time = 0      
COOLDOWN_TIME = 3 

def generate_frames():
    global last_sent_status, last_send_time, cap
    
    while True:
        # Tambahkan jeda napas 30ms (~30 FPS) agar ESP32-CAM tidak overheat/crash
        time.sleep(0.1)
        
        success, img = cap.read()
        
        if not success:
            print("⚠️ Kamera Terputus! Reconnecting...")
            cap.release() # Lepas total resource lama
            time.sleep(2) 
            cap = koneksi_kamera() # Sambung baru
            continue

        # --- 4. CLONE FRAME ---
        # Wajib di-copy agar proses AI tidak merusak index stream FFMPEG
        frame = img.copy()

        # --- 5. DETEKSI AI ---
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

        # --- 6. KIRIM KE LARAVEL ---
        current_time = time.time()
        if detected_status != 0:
            if (detected_status != last_sent_status) or (current_time - last_send_time > COOLDOWN_TIME):
                try:
                    url_api = f"{LARAVEL_URL}?status={detected_status}"
                    requests.get(url_api, timeout=0.3) 
                    print(f"🚀 [DB UPDATE] {detected_label.upper()}")
                    last_sent_status = detected_status
                    last_send_time = current_time
                except Exception:
                    pass

        # --- 7. ENCODE FRAME (STABILIZER) ---
        # Kompresi ke 70% JPEG untuk meringankan beban transmisi ke Flutter
        ret, buffer = cv2.imencode('.jpg', frame, [int(cv2.IMWRITE_JPEG_QUALITY), 70])
        if not ret: 
            continue
            
        frame_bytes = buffer.tobytes()
        
        try:
            yield (b'--frame\r\n'
                   b'Content-Type: image/jpeg\r\n\r\n' + frame_bytes + b'\r\n')
        except Exception:
            # Jika user tutup aplikasi Flutter, biarkan loop tetap jalan untuk scan selanjutnya
            continue

@app.route('/video_feed')
def video_feed():
    return Response(generate_frames(), mimetype='multipart/x-mixed-replace; boundary=frame')

if __name__ == "__main__":
    print("--------------------------------------------------")
    print(f"🌐 Server AI: http://{LAPTOP_IP}:8888/video_feed")
    print("🍍 Sistem QC Nanas Running...")
    print("--------------------------------------------------")
    # threaded=True wajib agar deteksi AI tidak menghalangi aliran frame ke Flutter
    app.run(host='0.0.0.0', port=8888, threaded=True, debug=False)
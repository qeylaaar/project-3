import cv2
import requests
import time
from ultralytics import YOLO

# --- 1. SETUP MODEL YOLOv11 ---
try:
    # Menggunakan model best.pt hasil latih 25 epoch
    model = YOLO("best.pt") 
    print("AI Model Loaded Successfully!")
except Exception as e:
    print(f"ERROR: Model gagal dimuat! ({e})")
    exit()

# --- 2. SETUP STREAM ESP32-CAM ---
# Masukkan IP dari Serial Monitor Arduino IDE
ESP32_IP = "192.168.137.8" 
stream_url = f"http://{ESP32_IP}/mjpeg" # Menggunakan path /mjpeg sesuai kode Arduino terbaru

cap = cv2.VideoCapture(stream_url)

# OPTIMASI ANTI-LAG: Hanya ambil frame paling baru (Buffer Size = 1)
cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)

# --- 3. KONFIGURASI API LARAVEL ---
LARAVEL_URL = "http://192.168.137.1:8000/api/nanas/status"
last_sent_status = None 
last_send_time = 0      
COOLDOWN_TIME = 2 # Jeda 2 detik antar pengiriman data agar lebih responsif

print("--------------------------------------------------")
print(f"Streaming: {stream_url}")
print("Sistem QC Nanas Aktif... Tekan 'q' untuk berhenti.")
print("--------------------------------------------------")

while True:
    ret, frame = cap.read()
    if not ret:
        print("Kamera Terputus atau Sinyal Lemah! Reconnecting...")
        cap = cv2.VideoCapture(stream_url)
        continue

    # --- 4. DETEKSI AI (Optimasi Task Detect) ---
    # conf=0.6: Deteksi hanya jika tingkat keyakinan di atas 60%
    results = model(frame, stream=True, conf=0.6, task='detect')

    detected_status = 0
    detected_label = ""

    for r in results:
        for box in r.boxes:
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            cls = int(box.cls[0])
            label = model.names[cls].lower()
            conf = round(float(box.conf[0]) * 100, 1)

            # Gambar Box Deteksi
            cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
            cv2.putText(frame, f"{label} {conf}%", (x1, y1 - 10), 
                        cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2)

            # Mapping Label Roboflow ke Sistem
            if "matured" in label and "unmatured" not in label:
                detected_status = 1  # Matang
                detected_label = label
            elif "unmatured" in label:
                detected_status = 3  # Mentah
                detected_label = label

    # --- 5. KIRIM DATA KE LARAVEL (Non-Blocking) ---
    current_time = time.time()

    if detected_status != 0:
        # Kirim jika status berubah atau cooldown habis
        if (detected_status != last_sent_status) or (current_time - last_send_time > COOLDOWN_TIME):
            try:
                # Timeout 0.5 detik agar Python tidak lag saat nunggu server
                url_api = f"{LARAVEL_URL}?status={detected_status}"
                requests.get(url_api, timeout=0.5) 
                
                print(f"[SENT] {detected_label.upper()} -> ID: {detected_status}")
                last_sent_status = detected_status
                last_send_time = current_time
            
            except Exception:
                # Skip jika Laravel sibuk atau sinyal ngelag
                pass

    # Tampilkan Stream
    cv2.imshow("ESP32-CAM AI Detection", frame)
    
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
print("Sistem Dimatikan.")
import cv2
import requests
import time
from ultralytics import YOLO

# --- 1. SETUP MODEL LOKAL ---
try:
    # Menggunakan model YOLOv11 yang sudah dilatih di Colab (25 Epoch)
    model = YOLO("best.pt") 
    print("AI Model Loaded Successfully!")
except Exception as e:
    print(f"ERROR: File best.pt tidak ditemukan atau rusak! ({e})")
    exit()

# --- 2. SETUP KAMERA (DROIDCAM) ---
# Gunakan pipeline = 1 atau 2 untuk DroidCam virtual camera
pipeline = 1 
cap = cv2.VideoCapture(pipeline)

# Atur resolusi agar FPS tetap tinggi (640x480 adalah standar emas YOLO)
cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)

# --- 3. KONFIGURASI API & TRACKER ---
LARAVEL_URL = "http://192.168.137.1:8000/api/nanas/status"
last_sent_status = None  # Menyimpan status terakhir agar tidak kirim data yang sama
last_send_time = 0       # Mencatat waktu terakhir pengiriman data
COOLDOWN_TIME = 3        # Jeda minimal 3 detik untuk update data yang sama

print("--------------------------------------------------")
print("AI Inference Started... Press 'q' to quit.")
print("Monitoring Pineapple Quality...")
print("--------------------------------------------------")

while True:
    ret, frame = cap.read()
    if not ret:
        print("Kamera terputus!")
        break

    # --- 4. JALANKAN PREDIKSI ---
    # stream=True: Mode generator untuk menghemat memori
    # conf=0.6: Hanya deteksi jika yakin di atas 60%
    results = model(frame, stream=True, conf=0.6)

    detected_status = 0
    detected_label = ""
    detected_conf = 0

    for r in results:
        for box in r.boxes:
            # Ambil koordinat kotak
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            cls = int(box.cls[0])
            label = model.names[cls].lower()
            conf = round(float(box.conf[0]) * 100, 1)

            # Gambar visual kotak hijau di layar
            cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
            cv2.putText(frame, f"{label} {conf}%", (x1, y1 - 10), 
                        cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2)

            # Mapping Label dari Roboflow ke Status Code Sistem
            # Catatan: Sesuaikan 'matured' dan 'unmatured' dengan nama class kamu
            if "matured" in label and "unmatured" not in label:
                detected_status = 1  # Matang
                detected_label = label
                detected_conf = conf
            elif "unmatured" in label:
                detected_status = 3  # Mentah
                detected_label = label
                detected_conf = conf

    # --- 5. LOGIKA PENGIRIMAN DATA SMART ---
    current_time = time.time()

    if detected_status != 0:
        # Kirim data hanya jika:
        # 1. Status berubah (misal dari mentah ke matang)
        # 2. ATAU sudah lewat dari 3 detik (update berkala buah yang sama)
        if (detected_status != last_sent_status) or (current_time - last_send_time > COOLDOWN_TIME):
            try:
                # Timeout 1.0 detik memberi ruang bagi Laravel untuk memproses database
                url_api = f"{LARAVEL_URL}?status={detected_status}"
                res = requests.get(url_api, timeout=1.0)
                
                if res.status_code == 200:
                    print(f"[SUCCESS] {detected_label.upper()} ({detected_conf}%) -> Sent to Laravel")
                    # Update tracker data terakhir
                    last_sent_status = detected_status
                    last_send_time = current_time
                else:
                    print(f"[WARNING] Laravel Response Error: {res.status_code}")
            
            except Exception as e:
                # Jika Laravel sibuk atau timeout, Python tidak akan macet/lag
                print(f"[LOG] Laravel busy or Network timeout. Skipping frame...")

    # Tampilkan window hasil deteksi
    cv2.imshow("Pineapple Smart QC - AI Vision", frame)
    
    # Tekan 'q' untuk berhenti
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

# Bersihkan resources
cap.release()
cv2.destroyAllWindows()
print("Sistem AI dihentikan.")
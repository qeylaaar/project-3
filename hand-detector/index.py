import cv2
import requests
import time
import sys

# TRIK TERAKHIR: Paksa cari jalurnya
try:
    # Coba jalur standard
    import mediapipe.python.solutions.hands as mp_hands
    import mediapipe.python.solutions.drawing_utils as mp_drawing
    print("Berhasil pakai jalur 1")
except:
    try:
        # Coba jalur alternatif
        from mediapipe.python.solutions import hands as mp_hands
        from mediapipe.python.solutions import drawing_utils as mp_drawing
        print("Berhasil pakai jalur 2")
    except:
        # Jalur darurat (biasanya buat Python 3.10)
        import mediapipe as mp
        mp_hands = mp.solutions.hands
        mp_drawing = mp.solutions.drawing_utils
        print("Berhasil pakai jalur 3")

# Inisialisasi Model
hands = mp_hands.Hands(
    static_image_mode=False,
    max_num_hands=1,
    min_detection_confidence=0.7,
    min_tracking_confidence=0.5
)

URL_LARAVEL = "http://10.85.204.5:8000/api/nanas/status?status="
last_sent_time = 0

cap = cv2.VideoCapture(0)

print("--- AI AKTIF ---")

while cap.isOpened():
    success, frame = cap.read()
    if not success: break

    frame = cv2.flip(frame, 1)
    rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    results = hands.process(rgb_frame)

    count = 0
    if results.multi_hand_landmarks:
        for hand_landmarks in results.multi_hand_landmarks:
            # Hitung jari (Telunjuk, Tengah, Manis)
            tips = [8, 12, 16]
            for tip in tips:
                if hand_landmarks.landmark[tip].y < hand_landmarks.landmark[tip - 2].y:
                    count += 1
            mp_drawing.draw_landmarks(frame, hand_landmarks, mp_hands.HAND_CONNECTIONS)

    # UI Preview
    cv2.rectangle(frame, (0, 0), (250, 80), (0, 0, 0), -1)
    cv2.putText(frame, f"GRADE: {count}", (20, 55), cv2.FONT_HERSHEY_SIMPLEX, 1.5, (0, 255, 0), 3)
    cv2.imshow('SPQC AI', frame)

    # Kirim ke Laravel
    if 1 <= count <= 3 and (time.time() - last_sent_time > 4):
        try:
            requests.get(URL_LARAVEL + str(count), timeout=1)
            print(f"TERKIRIM: {count}")
            last_sent_time = time.time()
        except:
            print("Laravel Offline")

    if cv2.waitKey(1) & 0xFF == ord('q'): break

cap.release()
cv2.destroyAllWindows()
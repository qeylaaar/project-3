<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\QualityLog;
use Illuminate\Http\Request;

class PineappleController extends Controller
{
    public function getLatest()
    {
        // Ambil data terbaru dari sensor
        $latest = QualityLog::latest()->first();

        if (!$latest) {
            return response()->json(['message' => 'No data found'], 404);
        }

        return response()->json($latest);
    }

    public function getHistory()
    {
        // Ambil 10 data terakhir untuk list di Flutter
        $history = QualityLog::latest()->take(10)->get();
        return response()->json($history);
    }

    public function setStatus(Request $request)
    {
        $statusRaw = $request->query('status'); // Matang atau Mentah
        $status = 'UNKNOWN';
        if ($statusRaw == 'Matang') $status = 'RIPE';
        if ($statusRaw == 'Mentah') $status = 'RAW';

        // Buat record baru di database dengan mock metrik lain karena ESP32 hanya kirim status
        $log = QualityLog::create([
            'weight' => rand(100, 200) / 100,
            'gas_value' => rand(30, 80), 
            'temperature' => rand(220, 280) / 10,
            'confidence_score' => rand(800, 990) / 10,
            'status' => $status,
        ]);

        return response()->json(['message' => 'Status saved successfully', 'data' => $log]);
    }
}

<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\QualityLog;
use Illuminate\Http\Request;

class PineappleController extends Controller
{
    // Ambil status terbaru untuk ESP32 & Flutter Dashboard
    public function getLatest() {
        $latest = QualityLog::latest()->first();
        return $latest ? response()->json($latest) : response()->json(['status' => 'NONE'], 404);
    }

    // Ambil daftar history untuk Flutter
    public function getHistory() {
        return response()->json(QualityLog::orderBy('created_at', 'desc')->take(20)->get());
    }

    // Input dari Laptop (1=A, 2=B, 3=C)
    public function setStatus(Request $request) {
        $input = $request->query('status');
        $map = ['1' => 'RIPE', '2' => 'HALF_RIPE', '3' => 'RAW'];
        $status = $map[$input] ?? 'UNKNOWN';

        $log = QualityLog::create([
            'weight' => rand(100, 200) / 100,
            'gas_value' => rand(30, 80),
            'temperature' => rand(220, 280) / 10,
            'confidence_score' => rand(850, 990) / 10,
            'status' => $status,
        ]);

        return response()->json(['message' => 'Success', 'grade' => $status]);
    }
}

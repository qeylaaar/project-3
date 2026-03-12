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
}

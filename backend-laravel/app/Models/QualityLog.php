<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class QualityLog extends Model
{
    protected $fillable = [
        'weight',
        'gas_value',
        'temperature',
        'confidence_score',
        'status',
    ];
}

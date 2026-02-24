package com.example.workout_timer

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val CHANNEL = "com.example.workout_timer/timer_service"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    val intent = Intent(this, TimerService::class.java).apply {
                        action = TimerService.ACTION_START
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(null)
                }
                "stopService" -> {
                    val intent = Intent(this, TimerService::class.java).apply {
                        action = TimerService.ACTION_STOP
                    }
                    startService(intent)
                    result.success(null)
                }
                "updateNotification" -> {
                    val time = call.argument<String>("time") ?: ""
                    val intent = Intent(this, TimerService::class.java).apply {
                        action = TimerService.ACTION_UPDATE
                        putExtra("time", time)
                    }
                    startService(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}

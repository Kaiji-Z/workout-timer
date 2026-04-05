package com.kaiji.workouttimer

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.CountDownTimer
import android.os.IBinder
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.MethodChannel

class TimerService : Service() {

    companion object {
        const val CHANNEL_ID = "timer_service_channel"
        const val NOTIFICATION_ID = 1001
        const val COMPLETION_CHANNEL_ID = "timer_completion_channel"
        const val COMPLETION_NOTIFICATION_ID = 1002
        const val METHOD_CHANNEL = "com.kaiji.workouttimer/timer_service"
        const val ACTION_START = "com.kaiji.workouttimer.START"
        const val ACTION_STOP = "com.kaiji.workouttimer.STOP"
        const val ACTION_UPDATE = "com.kaiji.workouttimer.UPDATE"
        const val EXTRA_DURATION = "duration"
        const val EXTRA_MODE = "mode"

        @JvmStatic
        var instance: TimerService? = null
        var methodChannel: MethodChannel? = null
    }

    private var countDownTimer: CountDownTimer? = null
    private var remainingSeconds: Int = 0
    private var totalDuration: Int = 0
    private var timerMode: String = "simple"
    private var isCompleted: Boolean = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        createCompletionNotificationChannel()
        instance = this
    }

    override fun onDestroy() {
        instance = null
        countDownTimer?.cancel()
        countDownTimer = null
        super.onDestroy()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                if (intent.hasExtra(EXTRA_DURATION)) {
                    // New route: startCountdown with duration and mode
                    val duration = intent.getIntExtra(EXTRA_DURATION, 60)
                    val mode = intent.getStringExtra(EXTRA_MODE) ?: "simple"
                    startCountdown(duration, mode)
                } else {
                    // Legacy route: notification only, no countdown (used during exercise)
                    startForegroundService()
                }
            }
            ACTION_STOP -> {
                stopCountdown()
                stopForegroundService()
            }
            ACTION_UPDATE -> {
                val time = intent.getStringExtra("time") ?: "00:00"
                updateNotification(time)
            }
        }
        return START_STICKY
    }

    fun startCountdown(durationSeconds: Int, mode: String) {
        // Cancel existing timer if any
        countDownTimer?.cancel()
        countDownTimer = null

        // Store state
        totalDuration = durationSeconds
        remainingSeconds = durationSeconds
        timerMode = mode
        isCompleted = false

        // Start foreground service with initial notification
        val initialText = if (mode == "rest") {
            "休息 ${formatTime(durationSeconds)}"
        } else {
            "剩余 ${formatTime(durationSeconds)}"
        }
        startForegroundService(initialText)

        // Create and start CountDownTimer
        countDownTimer = object : CountDownTimer(durationSeconds * 1000L, 1000L) {
            override fun onTick(millisUntilFinished: Long) {
                remainingSeconds = (millisUntilFinished / 1000).toInt()
                val timeText = formatTime(remainingSeconds)
                val notificationText = if (timerMode == "rest") {
                    "休息 $timeText"
                } else {
                    "剩余 $timeText"
                }
                updateNotification(notificationText)
                methodChannel?.invokeMethod("onTimerTick", mapOf(
                    "remaining" to remainingSeconds,
                    "completed" to false,
                    "mode" to timerMode
                ))
            }

            override fun onFinish() {
                remainingSeconds = 0
                isCompleted = true
                showCompletionNotification()
                methodChannel?.invokeMethod("onTimerTick", mapOf(
                    "remaining" to 0,
                    "completed" to true,
                    "mode" to timerMode
                ))
                updateNotification("计时结束")
            }
        }.start()
    }

    fun stopCountdown() {
        countDownTimer?.cancel()
        countDownTimer = null
        remainingSeconds = 0
        isCompleted = false
        // Cancel completion notification if user skipped rest
        val manager = getSystemService(NotificationManager::class.java)
        manager.cancel(COMPLETION_NOTIFICATION_ID)
    }

    fun getTimerState(): Map<String, Any> {
        return mapOf(
            "remaining" to remainingSeconds,
            "completed" to isCompleted,
            "mode" to timerMode
        )
    }

    private fun formatTime(seconds: Int): String {
        val mins = seconds / 60
        val secs = seconds % 60
        return String.format("%02d:%02d", mins, secs)
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Timer Service",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Used to keep timer running in background"
            setShowBadge(false)
        }
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }

    private fun createCompletionNotificationChannel() {
        val channel = NotificationChannel(
            COMPLETION_CHANNEL_ID,
            "Timer Completion",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Rest countdown completion alert"
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 500, 200, 500)
            setBypassDnd(true)  // Override Do Not Disturb for timer alerts
        }
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }

    private fun showCompletionNotification() {
        val intent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, COMPLETION_CHANNEL_ID)
            .setContentTitle("休息结束！")
            .setContentText("准备开始下一组")
            .setSmallIcon(R.drawable.ic_launcher)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setDefaults(NotificationCompat.DEFAULT_ALL)  // Sound + vibration
            .setContentIntent(pendingIntent)
            .setTimeoutAfter(5000)  // Auto-dismiss after 5 seconds
            .build()

        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(COMPLETION_NOTIFICATION_ID, notification)
    }

    private fun startForegroundService() {
        startForeground(NOTIFICATION_ID, createNotification("计时进行中..."))
    }

    private fun startForegroundService(contentText: String) {
        val notification = createNotification(contentText)
        startForeground(NOTIFICATION_ID, notification)
    }

    private fun updateNotification(time: String) {
        val notification = createNotification(time)
        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(NOTIFICATION_ID, notification)
    }

    private fun createNotification(content: String): Notification {
        val intent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("健身计时器")
            .setContentText(content)
            .setSmallIcon(R.drawable.ic_launcher)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun stopForegroundService() {
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }
}

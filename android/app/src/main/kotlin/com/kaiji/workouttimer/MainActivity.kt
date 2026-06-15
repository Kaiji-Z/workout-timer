package com.kaiji.workouttimer

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity() {

    companion object {
        const val CHANNEL = "com.kaiji.workouttimer/timer_service"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        TimerService.methodChannel = channel

        channel.setMethodCallHandler { call, result ->
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
                "startCountdown" -> {
                    val duration = call.argument<Int>("duration") ?: 60
                    val mode = call.argument<String>("mode") ?: "simple"
                    val intent = Intent(this, TimerService::class.java).apply {
                        action = TimerService.ACTION_START
                        putExtra(TimerService.EXTRA_DURATION, duration)
                        putExtra(TimerService.EXTRA_MODE, mode)
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(null)
                }
                "stopCountdown" -> {
                    val intent = Intent(this, TimerService::class.java).apply {
                        action = TimerService.ACTION_STOP
                    }
                    startService(intent)
                    result.success(null)
                }
                "getRemainingTime" -> {
                    val state = TimerService.instance?.getTimerState()
                        ?: mapOf("remaining" to 0, "completed" to false, "mode" to "none")
                    result.success(state)
                }
                "isIgnoringBatteryOptimizations" -> {
                    val pm = getSystemService(POWER_SERVICE) as PowerManager
                    val isIgnoring = pm.isIgnoringBatteryOptimizations(packageName)
                    result.success(isIgnoring)
                }
                "requestIgnoreBatteryOptimizations" -> {
                    try {
                        val intent = Intent(
                            Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        // Fallback: open app battery settings page
                        try {
                            val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                            startActivity(intent)
                            result.success(true)
                        } catch (e2: Exception) {
                            result.success(false)
                        }
                    }
                }
                "getOemManufacturer" -> {
                    val brand = Build.BRAND.lowercase(Locale.ROOT)
                    val oem = when {
                        brand.contains("huawei") || brand.contains("honor") -> "huawei"
                        brand.contains("xiaomi") || brand.contains("redmi") || brand.contains("poco") -> "xiaomi"
                        brand.contains("oppo") || brand.contains("realme") -> "oppo"
                        brand.contains("vivo") || brand.contains("iqoo") -> "vivo"
                        brand.contains("meizu") -> "meizu"
                        brand.contains("samsung") -> "samsung"
                        brand.contains("oneplus") -> "oneplus"
                        else -> null
                    }
                    result.success(oem)
                }
                "isOemAutoStartAvailable" -> {
                    val isAvailable = try {
                        getOemAutoStartIntents().any { intent ->
                            packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY) != null
                        }
                    } catch (e: Exception) {
                        android.util.Log.d("MainActivity", "isOemAutoStartAvailable failed: ${e.message}")
                        false
                    }
                    result.success(isAvailable)
                }
                "requestOemAutoStart" -> {
                    val opened = try {
                        val intents = getOemAutoStartIntents()
                        var success = false
                        for (intent in intents) {
                            if (packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY) != null) {
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(intent)
                                success = true
                                break
                            }
                        }
                        if (!success) {
                            // Fallback: open app details settings page
                            val fallbackIntent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = Uri.parse("package:$packageName")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(fallbackIntent)
                            success = true
                        }
                        success
                    } catch (e: Exception) {
                        android.util.Log.d("MainActivity", "requestOemAutoStart failed: ${e.message}")
                        false
                    }
                    result.success(opened)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getOemAutoStartIntents(): List<Intent> {
        val brand = Build.BRAND.lowercase(Locale.ROOT)
        val intents = mutableListOf<Intent>()

        when {
            brand.contains("huawei") -> {
                // Huawei EMUI 9+ / HarmonyOS — 应用启动管理
                intents.add(Intent().setComponent(ComponentName("com.huawei.systemmanager",
                    "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity")))
                intents.add(Intent().setComponent(ComponentName("com.huawei.systemmanager",
                    "com.huawei.systemmanager.optimize.process.ProtectActivity")))
                intents.add(Intent().setComponent(ComponentName("com.huawei.systemmanager",
                    "com.huawei.systemmanager.appcontrol.activity.StartupAppControlActivity")))
            }
            brand.contains("honor") -> {
                // Honor MagicOS — uses Huawei systemmanager
                intents.add(Intent().setComponent(ComponentName("com.huawei.systemmanager",
                    "com.huawei.systemmanager.optimize.process.ProtectActivity")))
                intents.add(Intent().setComponent(ComponentName("com.huawei.systemmanager",
                    "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity")))
            }
            brand.contains("xiaomi") || brand.contains("redmi") || brand.contains("poco") -> {
                // Xiaomi MIUI / HyperOS — 自启动管理
                intents.add(Intent().setComponent(ComponentName("com.miui.securitycenter",
                    "com.miui.permcenter.autostart.AutoStartManagementActivity")))
            }
            brand.contains("oppo") || brand.contains("realme") -> {
                // OPPO ColorOS — 自启动管理
                intents.add(Intent().setComponent(ComponentName("com.coloros.safecenter",
                    "com.coloros.safecenter.permission.startup.StartupAppListActivity")))
                intents.add(Intent().setComponent(ComponentName("com.coloros.safecenter",
                    "com.coloros.safecenter.startupapp.StartupAppListActivity")))
                intents.add(Intent().setComponent(ComponentName("com.oppo.safe",
                    "com.oppo.safe.permission.startup.StartupAppListActivity")))
            }
            brand.contains("vivo") || brand.contains("iqoo") -> {
                // vivo OriginOS / Funtouch OS — 后台高耗电 / 自启动
                intents.add(Intent().setComponent(ComponentName("com.iqoo.secure",
                    "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity")))
                intents.add(Intent().setComponent(ComponentName("com.iqoo.secure",
                    "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager")))
                intents.add(Intent().setComponent(ComponentName("com.vivo.permissionmanager",
                    "com.vivo.permissionmanager.activity.BgStartUpManagerActivity")))
            }
            brand.contains("meizu") -> {
                // Meizu Flyme — 智能休眠
                intents.add(Intent().setComponent(ComponentName("com.meizu.safe",
                    "com.meizu.safe.permission.SmartBGActivity")))
                intents.add(Intent().setComponent(ComponentName("com.meizu.safe",
                    "com.meizu.safe.security.AppSecActivity")))
            }
            brand.contains("samsung") -> {
                // Samsung One UI — Battery optimization
                intents.add(Intent().setComponent(ComponentName("com.samsung.android.lool",
                    "com.samsung.android.sm.ui.battery.BatteryActivity")))
                intents.add(Intent().setComponent(ComponentName("com.samsung.android.lool",
                    "com.samsung.android.sm.battery.ui.usage.CheckableAppListActivity")))
            }
            brand.contains("oneplus") -> {
                // OnePlus OxygenOS — 后台优化
                intents.add(Intent().setComponent(ComponentName("com.oneplus.security",
                    "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity")))
            }
        }
        return intents
    }
}

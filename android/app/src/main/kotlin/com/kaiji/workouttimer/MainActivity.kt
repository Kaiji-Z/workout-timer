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

        // Each OEM's intent list is ordered: power-saving / battery pages FIRST
        // (those actually keep the timer alive in background), auto-start LAST
        // (fallback). requestOemAutoStart() opens the first resolvable one.
        //
        // VERIFICATION STATUS legend (in the per-OEM comments below):
        //   [VERIFIED]   confirmed working on a real device
        //   [OFFICIAL]   path confirmed by OEM official docs, Activity name from community
        //   [UNVERIFIED] Activity name from community reverse-engineering, not tested
        //   [RESTRICTED] known to reject third-party startActivity on new OS versions
        when {
            brand.contains("huawei") || brand.contains("honor") -> {
                // HarmonyOS / EMUI. "App launch management" is the ONE page that
                // holds auto-start + "allow background activity" toggles together.
                // Official doc: consumer.huawei.com/cn/support/content/zh-cn00428704
                // [OFFICIAL] app launch management (the critical page)
                intents.add(Intent().setComponent(ComponentName("com.huawei.systemmanager",
                    "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity")))
                // [UNVERIFIED] older EMUI "protected apps"
                intents.add(Intent().setComponent(ComponentName("com.huawei.systemmanager",
                    "com.huawei.systemmanager.optimize.process.ProtectActivity")))
                // [UNVERIFIED] power optimization
                intents.add(Intent().setComponent(ComponentName("com.huawei.systemmanager",
                    "com.huawei.systemmanager.power.ui.HwPowerManagerActivity")))
            }
            brand.contains("xiaomi") || brand.contains("redmi") || brand.contains("poco") -> {
                // MIUI / HyperOS. The "power strategy = unrestricted" setting is
                // what keeps apps alive; auto-start alone is NOT enough.
                // Official doc: dev.mi.com Powerkeeper (confirms the strategy, not the Activity name)
                // [UNVERIFIED] power-saver / hidden-mode container (the critical one)
                intents.add(Intent().setComponent(ComponentName("com.miui.powerkeeper",
                    "com.miui.powerkeeper.ui.HiddenAppsContainerManagementActivity")))
                // [UNVERIFIED] per-app power config entry
                intents.add(Intent().setComponent(ComponentName("com.miui.powerkeeper",
                    "com.miui.powerkeeper.ui.PowercfgEnterActivity")))
                // [UNVERIFIED] auto-start management (fallback only).
                // NOTE: on Android 13+ startActivity may throw SecurityException
                // even when resolveActivity succeeds; the outer try-catch handles it.
                intents.add(Intent().setComponent(ComponentName("com.miui.securitycenter",
                    "com.miui.permcenter.autostart.AutoStartManagementActivity")))
            }
            brand.contains("oppo") || brand.contains("realme") -> {
                // ColorOS. Safe-center package name varies across versions:
                //   com.coloros.safecenter (newer) / com.color.safecenter / com.oppo.safe
                // [UNVERIFIED] safe-center startup list (newer ColorOS)
                intents.add(Intent().setComponent(ComponentName("com.coloros.safecenter",
                    "com.coloros.safecenter.permission.startup.StartupAppListActivity")))
                intents.add(Intent().setComponent(ComponentName("com.coloros.safecenter",
                    "com.coloros.safecenter.startupapp.StartupAppListActivity")))
                // [UNVERIFIED] power-usage model
                intents.add(Intent().setComponent(ComponentName("com.coloros.safecenter",
                    "com.coloros.safecenter.powerusage.PowerUsageModelActivity")))
                // [UNVERIFIED] older ColorOS safe-center
                intents.add(Intent().setComponent(ComponentName("com.oppo.safe",
                    "com.oppo.safe.permission.startup.StartupAppListActivity")))
                // [RESTRICTED] newer ColorOS rejects direct startActivity for these
                // components even when declared; resolveActivity may still pass.
                // If all above fail, requestOemAutoStart falls back to app-details page.
            }
            brand.contains("vivo") || brand.contains("iqoo") -> {
                // OriginOS / Funtouch OS. "Background high power usage" allow-list
                // is the critical setting for background survival.
                // [VERIFIED on OriginOS 6, iQOO 12, Android 16] background high-power
                // usage page — opens without privileged permission.
                intents.add(Intent().setComponent(ComponentName("com.iqoo.powersaving",
                    "com.iqoo.powersaving.BackgroundHighUsageActivity")))
                // [UNVERIFIED] older Funtouch OS high-power allow-list
                intents.add(Intent().setComponent(ComponentName("com.iqoo.secure",
                    "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity")))
                // [VERIFIED on OriginOS 6] auto-start management (opens, but is the
                // wrong page — fallback only, NOT what users should configure).
                intents.add(Intent().setComponent(ComponentName("com.vivo.permissionmanager",
                    "com.vivo.permissionmanager.activity.BgStartUpManagerActivity")))
                intents.add(Intent().setComponent(ComponentName("com.iqoo.secure",
                    "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager")))
            }
            brand.contains("meizu") -> {
                // Flyme. "Smart background" is the keep-alive entry.
                // [UNVERIFIED] smart background
                intents.add(Intent().setComponent(ComponentName("com.meizu.safe",
                    "com.meizu.safe.permission.SmartBGActivity")))
                // [UNVERIFIED] app security
                intents.add(Intent().setComponent(ComponentName("com.meizu.safe",
                    "com.meizu.safe.security.AppSecActivity")))
            }
            brand.contains("samsung") -> {
                // One UI. Device-care battery page; package/activity names vary
                // a lot across One UI versions.
                // [UNVERIFIED] device-care battery
                intents.add(Intent().setComponent(ComponentName("com.samsung.android.lool",
                    "com.samsung.android.sm.ui.battery.BatteryActivity")))
                // [UNVERIFIED] checkable app list
                intents.add(Intent().setComponent(ComponentName("com.samsung.android.lool",
                    "com.samsung.android.sm.battery.ui.usage.CheckableAppListActivity")))
            }
            brand.contains("oneplus") -> {
                // OxygenOS. Chain-launch merges auto-start + battery.
                // [UNVERIFIED] chain launch list
                intents.add(Intent().setComponent(ComponentName("com.oneplus.security",
                    "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity")))
                // [UNVERIFIED] alternate chain launch activity
                intents.add(Intent().setComponent(ComponentName("com.oneplus.security",
                    "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity2")))
            }
        }
        return intents
    }
}

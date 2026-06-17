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

        // Intents are ordered by priority: power-saving / battery-management
        // pages come FIRST (those are what actually keep the timer alive when
        // the app is backgrounded), auto-start pages come LAST as a fallback.
        // requestOemAutoStart() resolves them in order and opens the first one
        // that exists on this device, so the ordering below is load-bearing.
        when {
            brand.contains("huawei") -> {
                // HarmonyOS / EMUI — 应用启动管理 is the single page that holds
                // both auto-start AND "allow background activity" toggles, so it
                // stays first. Older EMUI used ProtectActivity (受保护应用).
                intents.add(Intent().setComponent(ComponentName("com.huawei.systemmanager",
                    "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity")))
                intents.add(Intent().setComponent(ComponentName("com.huawei.systemmanager",
                    "com.huawei.systemmanager.optimize.process.ProtectActivity")))
                // 电源优化 (power manager) — last-resort battery entry
                intents.add(Intent().setComponent(ComponentName("com.huawei.systemmanager",
                    "com.huawei.systemmanager.power.ui.HwPowerManagerActivity")))
                intents.add(Intent().setComponent(ComponentName("com.huawei.systemmanager",
                    "com.huawei.systemmanager.appcontrol.activity.StartupAppControlActivity")))
            }
            brand.contains("honor") -> {
                // Honor MagicOS — reuses Huawei systemmanager
                intents.add(Intent().setComponent(ComponentName("com.huawei.systemmanager",
                    "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity")))
                intents.add(Intent().setComponent(ComponentName("com.huawei.systemmanager",
                    "com.huawei.systemmanager.optimize.process.ProtectActivity")))
                intents.add(Intent().setComponent(ComponentName("com.huawei.systemmanager",
                    "com.huawei.systemmanager.power.ui.HwPowerManagerActivity")))
            }
            brand.contains("xiaomi") || brand.contains("redmi") || brand.contains("poco") -> {
                // MIUI / HyperOS — the power-saver ("神隐模式"/省电策略) is what
                // keeps the app alive; auto-start alone is NOT enough.
                // 省电策略 / 神隐模式 (power keeper — the critical one)
                intents.add(Intent().setComponent(ComponentName("com.miui.powerkeeper",
                    "com.miui.powerkeeper.ui.HiddenAppsContainerManagementActivity")))
                // 省电策略另一入口
                intents.add(Intent().setComponent(ComponentName("com.miui.powerkeeper",
                    "com.miui.powerkeeper.powercfg.PowercfgEnterActivity")))
                // 自启动管理 (auto-start — fallback only)
                intents.add(Intent().setComponent(ComponentName("com.miui.securitycenter",
                    "com.miui.permcenter.autostart.AutoStartManagementActivity")))
            }
            brand.contains("oppo") || brand.contains("realme") -> {
                // ColorOS — newer versions merge power + auto-start into the safe
                // center; older versions split them. List both orders.
                intents.add(Intent().setComponent(ComponentName("com.coloros.safecenter",
                    "com.coloros.safecenter.permission.startup.StartupAppListActivity")))
                intents.add(Intent().setComponent(ComponentName("com.coloros.safecenter",
                    "com.coloros.safecenter.startupapp.StartupAppListActivity")))
                // 耗电保护 (power-usage protection) entry
                intents.add(Intent().setComponent(ComponentName("com.coloros.safecenter",
                    "com.coloros.safecenter.powerusage.PowerUsageModelActivity")))
                intents.add(Intent().setComponent(ComponentName("com.oppo.safe",
                    "com.oppo.safe.permission.startup.StartupAppListActivity")))
            }
            brand.contains("vivo") || brand.contains("iqoo") -> {
                // vivo OriginOS / Funtouch OS — "后台高耗电" allow-list is the
                // critical setting for background survival. Several Activity
                // names vary across versions, so list all known ones before
                // falling back to the auto-start page.
                // 后台高耗电白名单 (high-power-usage allow-list — the critical one)
                intents.add(Intent().setComponent(ComponentName("com.iqoo.secure",
                    "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity")))
                // 后台耗电管理 (excessive power manager — older Funtouch core)
                intents.add(Intent().setComponent(ComponentName("com.vivo.abe",
                    "com.vivo.applicationbehaviorengine.ui.ExcessivePowerManagerActivity")))
                // 后台优化 (newer OriginOS)
                intents.add(Intent().setComponent(ComponentName("com.iqoo.secure",
                    "com.iqoo.secure.ui.phoneoptimize.BgOptimizeActivity")))
                // 自启动 (auto-start — fallback only, what users mistakenly see today)
                intents.add(Intent().setComponent(ComponentName("com.iqoo.secure",
                    "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager")))
                intents.add(Intent().setComponent(ComponentName("com.vivo.permissionmanager",
                    "com.vivo.permissionmanager.activity.BgStartUpManagerActivity")))
            }
            brand.contains("meizu") -> {
                // Flyme — 智能休眠 is the background-keep-alive entry.
                intents.add(Intent().setComponent(ComponentName("com.meizu.safe",
                    "com.meizu.safe.permission.SmartBGActivity")))
                intents.add(Intent().setComponent(ComponentName("com.meizu.safe",
                    "com.meizu.safe.security.AppSecActivity")))
            }
            brand.contains("samsung") -> {
                // One UI — device-maintenance battery page; package/activity
                // names vary a lot across One UI versions, so cover both.
                intents.add(Intent().setComponent(ComponentName("com.samsung.android.lool",
                    "com.samsung.android.sm.ui.battery.BatteryActivity")))
                intents.add(Intent().setComponent(ComponentName("com.samsung.android.lool",
                    "com.samsung.android.sm.battery.ui.usage.CheckableAppListActivity")))
            }
            brand.contains("oneplus") -> {
                // OxygenOS — 链式启动 merges auto-start + battery; battery
                // optimize is a separate entry on some versions.
                intents.add(Intent().setComponent(ComponentName("com.oneplus.security",
                    "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity")))
                intents.add(Intent().setComponent(ComponentName("com.oneplus.security",
                    "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity2")))
            }
        }
        return intents
    }
}

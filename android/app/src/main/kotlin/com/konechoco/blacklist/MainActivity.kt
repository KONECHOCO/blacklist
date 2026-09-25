package com.konechoco.blacklist

import android.app.role.RoleManager
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter <-> Android bridge ("com.konechoco.blacklist/screening"):
 *  - requestRole / isActive: the system call-screening role
 *  - writeRules: rules.json read by BlacklistScreeningService on every call
 *  - readLog / clearLog: screened-call history
 *  - takeLaunchNumber: number from a tapped "report this call" notification
 */
class MainActivity : FlutterActivity() {
    private var pendingRole: MethodChannel.Result? = null
    private var launchNumber: String? = null
    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        launchNumber = intent?.getStringExtra(EXTRA_NUMBER)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "platform" -> result.success("android")
                    "isActive" -> result.success(roleHeld())
                    "requestRole" -> requestRole(result)
                    "writeRules" -> {
                        val json = call.argument<String>("json") ?: "{}"
                        val file = Rules.file(this@MainActivity)
                        val tmp = java.io.File(file.path + ".tmp")
                        tmp.writeText(json)
                        tmp.renameTo(file)
                        result.success(true)
                    }
                    "readLog" -> result.success(CallLog.read(this@MainActivity))
                    "clearLog" -> { CallLog.clear(this@MainActivity); result.success(true) }
                    "takeLaunchNumber" -> { result.success(launchNumber); launchNumber = null }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        intent.getStringExtra(EXTRA_NUMBER)?.let { channel?.invokeMethod("reportNumber", it) }
    }

    private fun roleHeld(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return false
        return getSystemService(RoleManager::class.java).isRoleHeld(RoleManager.ROLE_CALL_SCREENING)
    }

    private fun requestRole(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) { result.success(false); return }
        val roles = getSystemService(RoleManager::class.java)
        if (roles.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)) { result.success(true); return }
        pendingRole = result
        @Suppress("DEPRECATION")
        startActivityForResult(roles.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING), REQUEST_ROLE)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_ROLE) {
            pendingRole?.success(roleHeld())
            pendingRole = null
        }
    }

    companion object {
        const val CHANNEL = "com.konechoco.blacklist/screening"
        const val EXTRA_NUMBER = "report_number"
        private const val REQUEST_ROLE = 4711
    }
}

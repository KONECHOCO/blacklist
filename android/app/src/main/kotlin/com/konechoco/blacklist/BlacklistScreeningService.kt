package com.konechoco.blacklist

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.ContactsContract
import android.telecom.Call
import android.telecom.CallScreeningService
import android.telecom.TelecomManager
import android.telephony.PhoneNumberUtils
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import org.json.JSONObject
import java.io.File

/**
 * Called by Android for every incoming call once the app holds the call-screening
 * role. Decides in a few milliseconds from the on-device rules the Flutter app
 * writes (rules.json): block, warn with a notification, or let it ring.
 */
class BlacklistScreeningService : CallScreeningService() {

    override fun onScreenCall(details: Call.Details) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
            details.callDirection != Call.Details.DIRECTION_INCOMING) {
            respondToCall(details, CallResponse.Builder().build())
            return
        }
        val rules = Rules.load(this)
        val raw = details.handle?.schemeSpecificPart
        val hidden = raw.isNullOrBlank() ||
            details.handlePresentation != TelecomManager.PRESENTATION_ALLOWED
        val number = if (hidden) "" else Rules.toE164(raw!!, rules.home)
        val decision = rules.decide(number, hidden) { isContact(it) }

        val response = CallResponse.Builder()
        when (decision.action) {
            Action.BLOCK -> response.setDisallowCall(true).setRejectCall(true)
                .setSkipCallLog(false).setSkipNotification(true)
            Action.SILENCE -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) response.setSilenceCall(true)
            else -> {}
        }
        respondToCall(details, response.build())

        CallLog.append(this, number, decision)
        when (decision.action) {
            Action.BLOCK, Action.SILENCE, Action.WARN -> notify(number, rules.text(decision), decision)
            Action.UNKNOWN -> if (rules.askUnknown) notify(number, rules.texts.optString("unknown"), decision)
            else -> {}
        }
    }

    private fun isContact(number: String): Boolean {
        if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.READ_CONTACTS) != PackageManager.PERMISSION_GRANTED) return false
        val uri = Uri.withAppendedPath(ContactsContract.PhoneLookup.CONTENT_FILTER_URI, Uri.encode(number))
        return try {
            contentResolver.query(uri, arrayOf(ContactsContract.PhoneLookup._ID), null, null, null)?.use { it.count > 0 } ?: false
        } catch (_: Exception) { false }
    }

    private fun notify(number: String, text: String, decision: Decision) {
        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(this, android.Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) return
        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(NotificationChannel(CHANNEL, "Blacklist", NotificationManager.IMPORTANCE_DEFAULT))
        }
        // Tapping opens the app on the report sheet for that number.
        val open = Intent(this, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            .putExtra(MainActivity.EXTRA_NUMBER, number)
        val pending = PendingIntent.getActivity(this, number.hashCode(), open,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val title = if (number.isEmpty()) Rules.hiddenLabel(this) else PhoneNumberUtils.formatNumber(number, Rules.load(this).home) ?: number
        val notification = NotificationCompat.Builder(this, CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_shield)
            .setContentTitle(title)
            .setContentText(text)
            .setAutoCancel(true)
            .setContentIntent(pending)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .build()
        try { NotificationManagerCompat.from(this).notify(number.hashCode(), notification) } catch (_: SecurityException) {}
    }

    companion object { const val CHANNEL = "screening" }
}

enum class Action { ALLOW, BLOCK, SILENCE, WARN, UNKNOWN }

data class Decision(val action: Action, val reason: String, val category: String = "", val score: Int = 0)

/** On-device rules written by the Flutter app (see ScreeningBridge.writeRules). */
class Rules(private val json: JSONObject) {
    val home: String = json.optString("home", "IT")
    val askUnknown = json.optBoolean("askUnknown", true)
    val texts: JSONObject = json.optJSONObject("texts") ?: JSONObject()
    private val labels: JSONObject = json.optJSONObject("labels") ?: JSONObject()
    private val mode = json.optString("mode", "block")          // block | silence | warn
    private val threshold = json.optInt("blockThreshold", 7)
    private val blockHidden = json.optBoolean("blockHidden", false)
    private val blockForeign = json.optBoolean("blockForeign", false)
    private val allow = json.optJSONArray("allow").toSet()
    private val block = json.optJSONArray("block").toSet()
    private val prefixes = json.optJSONArray("prefixes").toSet()
    private val spam: JSONObject = json.optJSONObject("spam") ?: JSONObject()

    fun decide(number: String, hidden: Boolean, isContact: (String) -> Boolean): Decision {
        if (hidden) return if (blockHidden) Decision(Action.BLOCK, "hidden") else Decision(Action.ALLOW, "hidden")
        if (number in allow) return Decision(Action.ALLOW, "allow")
        if (number in block) return Decision(Action.BLOCK, "user")
        prefixes.firstOrNull { number.startsWith(it) }?.let { return Decision(Action.BLOCK, "prefix:$it") }
        spam.optJSONArray(number)?.let { entry ->
            val category = entry.optString(0, "other")
            val score = entry.optInt(1, 7)
            val action = when {
                score < threshold -> Action.WARN
                mode == "silence" -> Action.SILENCE
                mode == "warn" -> Action.WARN
                else -> Action.BLOCK
            }
            return Decision(action, "community", category, score)
        }
        if (isContact(number)) return Decision(Action.ALLOW, "contact")
        if (blockForeign && !number.startsWith("+${dialCode()}")) return Decision(Action.BLOCK, "foreign")
        return Decision(Action.UNKNOWN, "unknown")
    }

    fun text(d: Decision): String {
        val label = labels.optString(d.category, d.category)
        return when (d.action) {
            Action.BLOCK -> texts.optString("blocked", "Blocked: {label}")
            Action.SILENCE -> texts.optString("silenced", "Silenced: {label}")
            else -> texts.optString("warn", "Possible spam: {label} ({score}/9)")
        }.replace("{label}", if (d.category.isEmpty()) texts.optString("userRule", "") else label)
            .replace("{score}", d.score.toString())
    }

    private fun dialCode(): String = json.optString("homeDial", "39")

    companion object {
        private var cached: Rules? = null
        private var cachedAt = 0L

        fun file(context: Context) = File(context.filesDir, "rules.json")

        fun load(context: Context): Rules {
            val f = file(context)
            val stamp = if (f.exists()) f.lastModified() else 0L
            cached?.let { if (stamp == cachedAt) return it }
            val rules = try { Rules(JSONObject(f.readText())) } catch (_: Exception) { Rules(JSONObject()) }
            cached = rules
            cachedAt = stamp
            return rules
        }

        fun toE164(raw: String, region: String): String =
            PhoneNumberUtils.formatNumberToE164(raw, region) ?: raw.filter { it.isDigit() || it == '+' }

        fun hiddenLabel(context: Context): String =
            try { JSONObject(file(context).readText()).optJSONObject("texts")?.optString("hidden") } catch (_: Exception) { null } ?: "Hidden number"

        private fun org.json.JSONArray?.toSet(): Set<String> {
            if (this == null) return emptySet()
            return (0 until length()).map { optString(it) }.filter { it.isNotEmpty() }.toSet()
        }
    }
}

/** Screening history shown in the app's "Calls" tab (last 500 entries). */
object CallLog {
    private fun file(context: Context) = File(context.filesDir, "screened.jsonl")

    fun append(context: Context, number: String, d: Decision) {
        val line = JSONObject()
            .put("n", number).put("t", System.currentTimeMillis())
            .put("a", d.action.name.lowercase()).put("r", d.reason)
            .put("c", d.category).put("s", d.score)
            .toString()
        val f = file(context)
        synchronized(this) {
            val lines = if (f.exists()) f.readLines().takeLast(499) else emptyList()
            f.writeText((lines + line).joinToString("\n") + "\n")
        }
    }

    fun read(context: Context): String = file(context).let { if (it.exists()) it.readText() else "" }

    fun clear(context: Context) { file(context).delete() }
}

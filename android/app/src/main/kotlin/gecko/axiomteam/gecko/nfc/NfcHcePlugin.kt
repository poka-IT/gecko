package gecko.axiomteam.gecko.nfc

import android.app.Activity
import android.content.pm.PackageManager
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.nfc.cardemulation.CardEmulation
import android.nfc.tech.IsoDep
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.WindowManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter plugin bridging NFC HCE capabilities to Dart.
 *
 * Provides:
 * - HCE emulation control (seller mode — phone acts as NFC card)
 * - Reader mode (buyer mode — phone reads NFC card/HCE device)
 * - Event stream for NFC state changes
 */
class NfcHcePlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {

    companion object {
        private const val TAG = "NfcHcePlugin"
        private const val CHANNEL = "gecko.axiomteam.gecko/nfc_hce"
        private const val EVENT_CHANNEL = "gecko.axiomteam.gecko/nfc_hce_events"

        // Same AID as PaymentHceService
        private val SELECT_APDU = byteArrayOf(
            0x00, 0xA4.toByte(), 0x04, 0x00,
            0x07, // AID length
            0xF0.toByte(), 0x47, 0x31, 0x4E, 0x4B, 0x47, 0x4F, // AID
            0x00 // Le
        )

        private const val MAX_FRAGMENT_SIZE = 240
    }

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var activity: Activity? = null
    private var nfcAdapter: NfcAdapter? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var readerModeTimeoutRunnable: Runnable? = null

    // --- FlutterPlugin ---

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(binding.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler(this@NfcHcePlugin)
        }
        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL).apply {
            setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        eventChannel = null
        eventSink = null
    }

    // --- ActivityAware ---

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        nfcAdapter = NfcAdapter.getDefaultAdapter(activity)
    }

    override fun onDetachedFromActivityForConfigChanges() { activity = null }
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        nfcAdapter = NfcAdapter.getDefaultAdapter(activity)
    }
    override fun onDetachedFromActivity() {
        stopReaderMode()
        activity = null
    }

    // --- MethodCallHandler ---

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isHceSupported" -> result.success(isHceSupported())
            "startEmulation" -> {
                val uri = call.argument<String>("uri")
                if (uri == null) {
                    result.error("INVALID_ARG", "URI required", null)
                } else {
                    startEmulation(uri, result)
                }
            }
            "stopEmulation" -> { stopEmulation(); result.success(true) }
            "isEmulating" -> result.success(PaymentHceService.isEmulating)
            "startReaderMode" -> {
                val timeoutMs = call.argument<Int>("timeoutMs") ?: 15000
                startReaderMode(timeoutMs, result)
            }
            "stopReaderMode" -> { stopReaderMode(); result.success(true) }
            "setKeepScreenOn" -> {
                val keepOn = call.argument<Boolean>("keepOn") ?: false
                setKeepScreenOn(keepOn)
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    // --- HCE Emulation (Seller) ---

    private fun isHceSupported(): Boolean {
        val adapter = nfcAdapter ?: return false
        if (!adapter.isEnabled) return false
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.KITKAT) return false
        return try {
            CardEmulation.getInstance(adapter) != null
        } catch (e: Exception) { false }
    }

    private fun startEmulation(uri: String, result: MethodChannel.Result) {
        try {
            PaymentHceService.currentPaymentUri = uri
            PaymentHceService.isEmulating = true

            // Set this app as preferred HCE service while in foreground
            val act = activity
            val adapter = nfcAdapter
            if (act != null && adapter != null) {
                try {
                    val cardEmulation = CardEmulation.getInstance(adapter)
                    val component = android.content.ComponentName(act, PaymentHceService::class.java)
                    cardEmulation.setPreferredService(act, component)
                } catch (e: Exception) {
                    Log.w(TAG, "Could not set preferred HCE service: ${e.message}")
                }
            }

            sendEvent("emulation_started", mapOf("uri" to uri))
            result.success(true)
        } catch (e: Exception) {
            result.error("HCE_ERROR", e.message, null)
        }
    }

    private fun stopEmulation() {
        PaymentHceService.currentPaymentUri = null
        PaymentHceService.isEmulating = false

        val act = activity
        val adapter = nfcAdapter
        if (act != null && adapter != null) {
            try {
                CardEmulation.getInstance(adapter).unsetPreferredService(act)
            } catch (e: Exception) {
                Log.w(TAG, "Could not unset preferred HCE service: ${e.message}")
            }
        }

        sendEvent("emulation_stopped")
    }

    // --- Reader Mode (Buyer) ---

    private fun startReaderMode(timeoutMs: Int, result: MethodChannel.Result) {
        val act = activity ?: run {
            result.error("NO_ACTIVITY", "No activity attached", null)
            return
        }
        val adapter = nfcAdapter ?: run {
            result.error("NO_NFC", "NFC not available", null)
            return
        }

        val flags = NfcAdapter.FLAG_READER_NFC_A or
                NfcAdapter.FLAG_READER_NFC_B or
                NfcAdapter.FLAG_READER_SKIP_NDEF_CHECK or
                NfcAdapter.FLAG_READER_NO_PLATFORM_SOUNDS

        adapter.enableReaderMode(act, { tag ->
            mainHandler.post { handleTagDiscovered(tag) }
        }, flags, null)

        // Auto-timeout
        readerModeTimeoutRunnable?.let { mainHandler.removeCallbacks(it) }
        readerModeTimeoutRunnable = Runnable {
            stopReaderMode()
            sendEvent("reader_mode_timeout")
        }
        mainHandler.postDelayed(readerModeTimeoutRunnable!!, timeoutMs.toLong())

        sendEvent("reader_mode_started")
        result.success(true)
    }

    private fun stopReaderMode() {
        readerModeTimeoutRunnable?.let { mainHandler.removeCallbacks(it) }
        readerModeTimeoutRunnable = null

        val act = activity
        val adapter = nfcAdapter
        if (act != null && adapter != null) {
            try {
                adapter.disableReaderMode(act)
            } catch (e: Exception) {
                Log.w(TAG, "Error disabling reader mode: ${e.message}")
            }
        }

        sendEvent("reader_mode_stopped")
    }

    private fun handleTagDiscovered(tag: Tag) {
        sendEvent("tag_discovered", mapOf("id" to tag.id.joinToString("") { "%02X".format(it) }))

        Thread {
            try {
                val isoDep = IsoDep.get(tag)
                if (isoDep == null) {
                    mainHandler.post { sendEvent("communication_error", mapOf("message" to "Not an ISO-DEP tag")) }
                    return@Thread
                }

                isoDep.connect()
                isoDep.timeout = 5000

                // Send SELECT with G1NKGO AID
                val selectResponse = isoDep.transceive(SELECT_APDU)
                if (selectResponse.size < 2) {
                    isoDep.close()
                    mainHandler.post { sendEvent("communication_error", mapOf("message" to "Empty response")) }
                    return@Thread
                }

                val sw = getStatusWord(selectResponse)

                val uriBytes: ByteArray = when {
                    // Single round-trip: URI in SELECT response + 9000
                    sw == 0x9000 && selectResponse.size > 2 -> {
                        selectResponse.copyOfRange(0, selectResponse.size - 2)
                    }
                    // Fragmented: need GET_DATA commands
                    (sw and 0xFF00) == 0x6100 -> {
                        readFragmented(isoDep, selectResponse)
                    }
                    else -> {
                        isoDep.close()
                        mainHandler.post { sendEvent("communication_error", mapOf("message" to "Unexpected SW: ${"%04X".format(sw)}")) }
                        return@Thread
                    }
                }

                isoDep.close()
                val uri = String(uriBytes, Charsets.UTF_8)
                mainHandler.post {
                    sendEvent("payment_read", mapOf("paymentUri" to uri))
                    stopReaderMode()
                }
            } catch (e: Exception) {
                mainHandler.post {
                    sendEvent("communication_error", mapOf("message" to (e.message ?: "Unknown error")))
                }
            }
        }.start()
    }

    private fun readFragmented(isoDep: IsoDep, firstResponse: ByteArray): ByteArray {
        val result = mutableListOf<Byte>()
        // First response might contain data before the status word
        if (firstResponse.size > 2) {
            result.addAll(firstResponse.copyOfRange(0, firstResponse.size - 2).toList())
        }

        var fragmentIndex = 0
        while (true) {
            val getDataApdu = byteArrayOf(
                0x00, 0xCA.toByte(), 0x00, fragmentIndex.toByte(), 0x00
            )
            val response = isoDep.transceive(getDataApdu)
            if (response.size < 2) break

            val sw = getStatusWord(response)
            if (response.size > 2) {
                result.addAll(response.copyOfRange(0, response.size - 2).toList())
            }

            if (sw == 0x9000) break // Last fragment
            if ((sw and 0xFF00) != 0x6100) break // Unexpected status
            fragmentIndex++
        }

        return result.toByteArray()
    }

    private fun getStatusWord(response: ByteArray): Int {
        if (response.size < 2) return 0
        val sw1 = response[response.size - 2].toInt() and 0xFF
        val sw2 = response[response.size - 1].toInt() and 0xFF
        return (sw1 shl 8) or sw2
    }

    // --- Utilities ---

    private fun setKeepScreenOn(keepOn: Boolean) {
        activity?.runOnUiThread {
            if (keepOn) {
                activity?.window?.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            } else {
                activity?.window?.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            }
        }
    }

    private fun sendEvent(type: String, data: Map<String, Any> = emptyMap()) {
        mainHandler.post {
            eventSink?.success(mapOf("type" to type) + data)
        }
    }
}

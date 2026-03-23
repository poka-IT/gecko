package gecko.axiomteam.gecko.nfc

import android.nfc.cardemulation.HostApduService
import android.os.Bundle
import android.util.Log

/**
 * HCE (Host Card Emulation) service for NFC tap-to-pay.
 *
 * Emulates an NFC card that responds to SELECT commands with a payment URI.
 * Uses AID F047314E4B474F ("G1NKGO") — shared with Ginkgo for cross-app compatibility.
 *
 * Protocol:
 * 1. Reader sends SELECT with AID → response contains URI if <= 250 bytes (single round-trip)
 * 2. If URI > 250 bytes, reader sends GET_DATA (INS=0xCA) with fragment index in P2
 */
class PaymentHceService : HostApduService() {

    companion object {
        private const val TAG = "PaymentHceService"

        // AID: "G1NKGO" in hex
        private val AID = byteArrayOf(
            0xF0.toByte(), 0x47, 0x31, 0x4E, 0x4B, 0x47, 0x4F
        )

        // APDU status words
        private val SW_OK = byteArrayOf(0x90.toByte(), 0x00)
        private val SW_NOT_FOUND = byteArrayOf(0x6A.toByte(), 0x82.toByte())
        private val SW_ERROR = byteArrayOf(0x6F.toByte(), 0x00)

        // Max payload per fragment (avoid exceeding APDU response limits)
        private const val MAX_FRAGMENT_SIZE = 240

        @Volatile
        var currentPaymentUri: String? = null

        @Volatile
        var isEmulating: Boolean = false
    }

    private var uriBytes: ByteArray? = null

    override fun processCommandApdu(commandApdu: ByteArray, extras: Bundle?): ByteArray {
        if (commandApdu.size < 4) return SW_ERROR

        val ins = commandApdu[1]
        return when {
            // SELECT command
            ins == 0xA4.toByte() -> handleSelect(commandApdu)
            // GET_DATA command (fragmented read)
            ins == 0xCA.toByte() -> handleGetData(commandApdu)
            else -> SW_ERROR
        }
    }

    private fun handleSelect(apdu: ByteArray): ByteArray {
        // Verify AID matches
        if (apdu.size < 5 + AID.size) return SW_NOT_FOUND
        val aidOffset = 5
        for (i in AID.indices) {
            if (apdu[aidOffset + i] != AID[i]) return SW_NOT_FOUND
        }

        val uri = currentPaymentUri
        if (uri.isNullOrEmpty()) {
            Log.w(TAG, "SELECT received but no payment URI set")
            return SW_NOT_FOUND
        }

        uriBytes = uri.toByteArray(Charsets.UTF_8)

        // Single round-trip optimization: return URI directly in SELECT response
        // if it fits (avoids LINK_LOSS from second APDU exchange)
        return if (uriBytes!!.size <= 250) {
            uriBytes!! + SW_OK
        } else {
            // Signal that data is available, client should use GET_DATA
            val remaining = uriBytes!!.size
            byteArrayOf(0x61.toByte(), (remaining and 0xFF).toByte())
        }
    }

    private fun handleGetData(apdu: ByteArray): ByteArray {
        val data = uriBytes ?: return SW_NOT_FOUND
        val fragmentIndex = apdu[3].toInt() and 0xFF
        val offset = fragmentIndex * MAX_FRAGMENT_SIZE

        if (offset >= data.size) return SW_NOT_FOUND

        val end = minOf(offset + MAX_FRAGMENT_SIZE, data.size)
        val fragment = data.copyOfRange(offset, end)
        val isLast = end >= data.size

        return if (isLast) {
            fragment + SW_OK
        } else {
            val remaining = data.size - end
            fragment + byteArrayOf(0x61.toByte(), (remaining and 0xFF).toByte())
        }
    }

    override fun onDeactivated(reason: Int) {
        Log.d(TAG, "HCE deactivated: reason=$reason")
        uriBytes = null
    }
}

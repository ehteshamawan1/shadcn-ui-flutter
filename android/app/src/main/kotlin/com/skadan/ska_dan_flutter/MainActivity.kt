package com.skadan.ska_dan_flutter

import io.flutter.embedding.android.FlutterFragmentActivity
import android.app.PendingIntent
import android.content.Intent
import android.nfc.NfcAdapter

// NFC foreground dispatch prevents Android system from showing "New Tag Scanned" popup
// or white screen with tag details. The nfc_manager plugin handles actual tag processing.
// Reference: https://stackoverflow.com/questions/76443776
class MainActivity: FlutterFragmentActivity() {
    override fun onResume() {
        super.onResume()
        val adapter: NfcAdapter? = NfcAdapter.getDefaultAdapter(this)
        val pendingIntent: PendingIntent = PendingIntent.getActivity(
            this, 0,
            Intent(this, javaClass).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE
        )
        // Pass null for filters - this catches ALL NFC tags before system handles them
        adapter?.enableForegroundDispatch(this, pendingIntent, null, null)
    }

    override fun onPause() {
        super.onPause()
        val adapter: NfcAdapter? = NfcAdapter.getDefaultAdapter(this)
        adapter?.disableForegroundDispatch(this)
    }
}

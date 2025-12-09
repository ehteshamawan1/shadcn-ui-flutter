package com.skadan.ska_dan_flutter

import io.flutter.embedding.android.FlutterActivity

// Note: NFC foreground dispatch removed - it was blocking nfc_manager plugin
// from receiving tags. The nfc_manager plugin handles NFC sessions internally.
class MainActivity : FlutterActivity()

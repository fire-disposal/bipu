package com.bipupu.user.mobile

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Disable hardware acceleration for problematic devices
        window?.setFormat(android.graphics.PixelFormat.TRANSLUCENT)
        super.onCreate(savedInstanceState)
    }
}

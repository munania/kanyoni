package com.example.kanyoni

import android.content.Intent
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine

// Extends AudioServiceActivity (not plain FlutterActivity) so audio_service
// keeps sharing one Flutter engine between the UI and the playback service.
class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        EqualizerHost.attach(messenger)
        TagEditorHost.attach(this, messenger)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        EqualizerHost.detach()
        TagEditorHost.detach()
        super.cleanUpFlutterEngine(flutterEngine)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        // The system "allow Kanyoni to modify this file?" prompt reports here.
        if (TagEditorHost.onActivityResult(requestCode, resultCode)) return
        super.onActivityResult(requestCode, resultCode, data)
    }
}

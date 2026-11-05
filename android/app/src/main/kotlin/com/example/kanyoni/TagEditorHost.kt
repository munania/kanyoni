package com.example.kanyoni

import android.annotation.SuppressLint
import android.app.Activity
import android.app.RecoverableSecurityException
import android.content.ContentUris
import android.media.MediaMetadataRetriever
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.jaudiotagger.audio.AudioFileIO
import org.jaudiotagger.tag.FieldKey
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.logging.Level
import java.util.logging.Logger

/**
 * Reads and writes audio tags.
 *
 * Writing flow (designed so a failure can never leave a half-written song):
 *  1. Make sure we may modify the file. On Android 11+ that is the system
 *     "Allow Kanyoni to modify this audio file?" prompt
 *     (MediaStore.createWriteRequest); on Android 10 the equivalent
 *     RecoverableSecurityException prompt; older versions just need the
 *     storage permission the app already asks for.
 *  2. Copy the file to the cache, plus a second copy as a backup.
 *  3. Edit the tags on the temporary copy and re-read it to verify.
 *  4. Only then overwrite the original. If that write fails, the backup is
 *     written back.
 *  5. Ask the media scanner to re-index the file so the library updates.
 */
object TagEditorHost : MethodChannel.MethodCallHandler {
    const val CHANNEL = "kanyoni/tags"
    private const val REQUEST_WRITE = 7301

    private val EDITABLE = setOf("mp3", "flac", "m4a", "mp4", "ogg", "oga", "opus")

    private val FIELD_KEYS = mapOf(
        "title" to FieldKey.TITLE,
        "artist" to FieldKey.ARTIST,
        "album" to FieldKey.ALBUM,
        "albumArtist" to FieldKey.ALBUM_ARTIST,
        "genre" to FieldKey.GENRE,
        "year" to FieldKey.YEAR,
        "track" to FieldKey.TRACK
    )

    private class Pending(
        val uri: Uri,
        val changes: Map<String, String>,
        val result: MethodChannel.Result
    )

    private var channel: MethodChannel? = null
    private var activity: Activity? = null
    private var pending: Pending? = null
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    fun attach(activity: Activity, messenger: BinaryMessenger) {
        this.activity = activity
        channel?.setMethodCallHandler(null)
        channel = MethodChannel(messenger, CHANNEL).also { it.setMethodCallHandler(this) }
        // The tag library is chatty; silence its logging.
        Logger.getLogger("org.jaudiotagger").level = Level.OFF
    }

    fun detach() {
        pending?.let { fail(it.result, "NO_ACTIVITY", "The window was closed") }
        pending = null
        channel?.setMethodCallHandler(null)
        channel = null
        activity = null
    }

    /** Returns true when the result belonged to us. */
    fun onActivityResult(requestCode: Int, resultCode: Int): Boolean {
        if (requestCode != REQUEST_WRITE) return false
        val p = pending ?: return true
        pending = null
        if (resultCode == Activity.RESULT_OK) {
            worker.execute { runEdit(p.uri, p.changes, p.result) }
        } else {
            fail(p.result, "PERMISSION_DENIED", "The user did not allow the change")
        }
        return true
    }

    // ---------------------------------------------------------------------------

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val id = call.argument<Number>("id")?.toLong()
        if (id == null) {
            result.error("BAD_ARGS", "Missing song id", null)
            return
        }
        val uri = ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id)

        when (call.method) {
            "readTags" -> worker.execute { readTags(uri, result) }

            "writeTags" -> {
                @Suppress("UNCHECKED_CAST")
                val changes = call.argument<Map<String, String>>("changes")
                if (changes == null) {
                    result.error("BAD_ARGS", "Missing changes", null)
                    return
                }
                if (pending != null) {
                    result.error("BUSY", "Another edit is waiting for permission", null)
                    return
                }
                worker.execute { begin(uri, changes, result) }
            }

            else -> result.notImplemented()
        }
    }

    private fun readTags(uri: Uri, result: MethodChannel.Result) {
        val act = activity
        if (act == null) {
            fail(result, "NO_ACTIVITY", null)
            return
        }
        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(act, uri)
            val year = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_YEAR)
                ?: retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DATE)
            val map = mapOf(
                "title" to retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_TITLE),
                "artist" to retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ARTIST),
                "album" to retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ALBUM),
                "albumArtist" to retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ALBUMARTIST),
                "genre" to retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_GENRE),
                "year" to year,
                "track" to retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_CD_TRACK_NUMBER)
            )
            main.post { result.success(map) }
        } catch (e: Exception) {
            fail(result, "READ_FAILED", e.message)
        } finally {
            try {
                retriever.release()
            } catch (_: Exception) {
            }
        }
    }

    /** Step 1: do we already have permission to modify this file? */
    private fun begin(uri: Uri, changes: Map<String, String>, result: MethodChannel.Result) {
        val act = activity
        if (act == null) {
            fail(result, "NO_ACTIVITY", null)
            return
        }
        try {
            // Opening for read+write doesn't change the file; it only checks access.
            act.contentResolver.openFileDescriptor(uri, "rw")?.close()
        } catch (e: SecurityException) {
            main.post { requestAccess(uri, changes, result, e) }
            return
        } catch (e: Exception) {
            fail(result, "WRITE_FAILED", e.message)
            return
        }
        runEdit(uri, changes, result)
    }

    @SuppressLint("NewApi")
    private fun requestAccess(
        uri: Uri,
        changes: Map<String, String>,
        result: MethodChannel.Result,
        cause: SecurityException
    ) {
        val act = activity
        if (act == null) {
            fail(result, "NO_ACTIVITY", null)
            return
        }
        try {
            val sender = when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.R ->
                    MediaStore.createWriteRequest(act.contentResolver, listOf(uri)).intentSender

                Build.VERSION.SDK_INT == Build.VERSION_CODES.Q &&
                        cause is RecoverableSecurityException ->
                    cause.userAction.actionIntent.intentSender

                else -> null
            }
            if (sender == null) {
                fail(result, "PERMISSION_DENIED", "Storage permission is missing")
                return
            }
            pending = Pending(uri, changes, result)
            act.startIntentSenderForResult(sender, REQUEST_WRITE, null, 0, 0, 0)
        } catch (e: Exception) {
            pending = null
            fail(result, "PERMISSION_DENIED", e.message)
        }
    }

    /** Steps 2-5. Runs on the worker thread. */
    private fun runEdit(uri: Uri, changes: Map<String, String>, result: MethodChannel.Result) {
        val act = activity
        if (act == null) {
            fail(result, "NO_ACTIVITY", null)
            return
        }
        val resolver = act.contentResolver

        var displayName: String? = null
        var dataPath: String? = null
        try {
            resolver.query(
                uri,
                arrayOf(MediaStore.MediaColumns.DISPLAY_NAME, MediaStore.MediaColumns.DATA),
                null, null, null
            )?.use { c ->
                if (c.moveToFirst()) {
                    displayName = c.getString(0)
                    dataPath = c.getString(1)
                }
            }
        } catch (_: Exception) {
        }

        val ext = displayName?.substringAfterLast('.', "")?.lowercase().orEmpty()
        if (ext !in EDITABLE) {
            fail(result, "UNSUPPORTED_FORMAT", "Cannot edit .$ext files")
            return
        }

        val stamp = System.nanoTime()
        val temp = File(act.cacheDir, "tagedit_$stamp.$ext")
        val backup = File(act.cacheDir, "tagedit_${stamp}_original.$ext")

        try {
            val input = resolver.openInputStream(uri)
                ?: throw IllegalStateException("Cannot open the file")
            input.use { src -> temp.outputStream().use { dst -> src.copyTo(dst) } }
            temp.copyTo(backup, overwrite = true)

            applyChanges(temp, changes)
            AudioFileIO.read(temp) // verify the edited copy is still a valid file

            try {
                val out = resolver.openOutputStream(uri, "wt")
                    ?: throw IllegalStateException("Cannot open the file for writing")
                out.use { dst -> temp.inputStream().use { src -> src.copyTo(dst) } }
            } catch (e: Exception) {
                // The original may now be damaged: put the backup back.
                try {
                    resolver.openOutputStream(uri, "wt")?.use { dst ->
                        backup.inputStream().use { src -> src.copyTo(dst) }
                    }
                } catch (_: Exception) {
                }
                throw e
            }

            rescan(act, dataPath)
            main.post { result.success(null) }
        } catch (e: SecurityException) {
            fail(result, "PERMISSION_DENIED", e.message)
        } catch (e: Exception) {
            fail(result, "WRITE_FAILED", e.message)
        } finally {
            temp.delete()
            backup.delete()
        }
    }

    private fun applyChanges(file: File, changes: Map<String, String>) {
        val audioFile = AudioFileIO.read(file)
        val tag = audioFile.tagOrCreateAndSetDefault
        for ((name, value) in changes) {
            val key = FIELD_KEYS[name] ?: continue
            if (value.isEmpty()) tag.deleteField(key) else tag.setField(key, value)
        }
        audioFile.commit()
    }

    /** Re-index the file so MediaStore (and so the app's library) shows the new tags. */
    private fun rescan(act: Activity, path: String?) {
        if (path.isNullOrEmpty()) return
        val latch = CountDownLatch(1)
        MediaScannerConnection.scanFile(act.applicationContext, arrayOf(path), null) { _, _ ->
            latch.countDown()
        }
        latch.await(5, TimeUnit.SECONDS)
    }

    private fun fail(result: MethodChannel.Result, code: String, message: String?) {
        main.post { result.error(code, message, null) }
    }
}

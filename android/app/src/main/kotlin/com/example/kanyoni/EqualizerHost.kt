package com.example.kanyoni

import android.annotation.SuppressLint
import android.annotation.TargetApi
import android.media.audiofx.DynamicsProcessing
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Bridge between Flutter and Android's multi-band equalizer
 * (android.media.audiofx.DynamicsProcessing, API 28+).
 *
 * It is a singleton on purpose: the audio effect is attached to the player's
 * audio session and must keep running when the Activity is destroyed but music
 * keeps playing in the background service. Only the channel handler is
 * re-attached when an Activity (re)creates the Flutter engine.
 */
object EqualizerHost : MethodChannel.MethodCallHandler {
    const val CHANNEL = "kanyoni/equalizer"

    private var channel: MethodChannel? = null
    private var engine: Engine? = null

    fun attach(messenger: BinaryMessenger) {
        channel?.setMethodCallHandler(null)
        channel = MethodChannel(messenger, CHANNEL).also {
            it.setMethodCallHandler(this)
        }
    }

    /** Called when the Activity goes away. The effect itself keeps running. */
    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    // DynamicsProcessing is only touched after an explicit SDK_INT >= P check.
    @SuppressLint("NewApi")
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "isSupported" ->
                    result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.P)

                "start" -> {
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
                        result.success(false)
                        return
                    }
                    val sessionId = call.argument<Int>("sessionId")
                    val edges = call.argument<List<Double>>("edges")
                    val gains = call.argument<List<Double>>("gains")
                    val preamp = call.argument<Double>("preampDb") ?: 0.0
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    if (sessionId == null || edges == null || gains == null ||
                        edges.isEmpty() || edges.size != gains.size
                    ) {
                        result.error("BAD_ARGS", "Invalid start arguments", null)
                        return
                    }
                    engine?.release()
                    engine = null
                    engine = try {
                        Engine(
                            sessionId,
                            edges.map { it.toFloat() },
                            gains.map { it.toFloat() },
                            preamp.toFloat(),
                            enabled
                        )
                    } catch (e: Exception) {
                        // Some devices/ROMs reject DynamicsProcessing. Report
                        // "not supported" so Dart falls back to the system
                        // equalizer instead of failing.
                        null
                    }
                    result.success(engine != null)
                }

                "setEnabled" -> {
                    engine?.setEnabled(call.argument<Boolean>("enabled") ?: false)
                    result.success(null)
                }

                "setGains" -> {
                    val indices = call.argument<List<Int>>("indices") ?: emptyList()
                    val gains = call.argument<List<Double>>("gains") ?: emptyList()
                    engine?.setGains(indices, gains.map { it.toFloat() })
                    result.success(null)
                }

                "setPreamp" -> {
                    engine?.setPreamp((call.argument<Double>("db") ?: 0.0).toFloat())
                    result.success(null)
                }

                "release" -> {
                    engine?.release()
                    engine = null
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("EQ_ERROR", e.message, null)
        }
    }

    /**
     * Wraps one DynamicsProcessing instance. Kept in its own class so that
     * nothing here is loaded on devices older than Android 9.
     */
    @TargetApi(Build.VERSION_CODES.P)
    private class Engine(
        sessionId: Int,
        private val edges: List<Float>,
        gains: List<Float>,
        preampDb: Float,
        enabled: Boolean
    ) {
        private val dp: DynamicsProcessing

        init {
            val config = DynamicsProcessing.Config.Builder(
                DynamicsProcessing.VARIANT_FAVOR_FREQUENCY_RESOLUTION,
                CHANNELS,
                true, edges.size,   // pre-EQ: the graphic equalizer bands
                false, 0,           // multi-band compressor: unused
                false, 0,           // post-EQ: unused
                true                // limiter: stops boosted peaks clipping
            ).build()

            dp = DynamicsProcessing(0, sessionId, config)

            for (i in edges.indices) {
                dp.setPreEqBandAllChannelsTo(
                    i, DynamicsProcessing.EqBand(true, edges[i], gains[i])
                )
            }
            dp.setInputGainAllChannelsTo(preampDb)

            try {
                dp.setLimiterAllChannelsTo(
                    DynamicsProcessing.Limiter(
                        true,   // inUse
                        true,   // enabled
                        0,      // linkGroup
                        1f,     // attack ms
                        60f,    // release ms
                        10f,    // ratio
                        -1f,    // threshold dB
                        0f      // post gain dB
                    )
                )
            } catch (e: Exception) {
                // The limiter is a safety net; the equalizer works without it.
            }

            dp.setEnabled(enabled)
        }

        fun setEnabled(enabled: Boolean) {
            dp.setEnabled(enabled)
        }

        fun setGains(indices: List<Int>, gains: List<Float>) {
            for (k in indices.indices) {
                val band = indices[k]
                if (band < 0 || band >= edges.size || k >= gains.size) continue
                dp.setPreEqBandAllChannelsTo(
                    band, DynamicsProcessing.EqBand(true, edges[band], gains[k])
                )
            }
        }

        fun setPreamp(db: Float) {
            dp.setInputGainAllChannelsTo(db)
        }

        fun release() {
            try {
                dp.setEnabled(false)
                dp.release()
            } catch (e: Exception) {
            }
        }

        companion object {
            private const val CHANNELS = 2
        }
    }
}

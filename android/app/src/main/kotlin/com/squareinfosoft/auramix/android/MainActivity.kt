package com.squareinfosoft.auramix.android

import android.media.audiofx.BassBoost
import android.media.audiofx.DynamicsProcessing
import android.media.audiofx.Equalizer
import android.media.audiofx.LoudnessEnhancer
import android.media.audiofx.PresetReverb
import android.media.audiofx.Virtualizer
import android.os.Build
import android.util.Log
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: AudioServiceActivity() {
    private val TAG = "AuraMixAudioFx"
    private val CHANNEL = "com.squareinfosoft.auramix/audiofx"
    private var equalizer: Equalizer? = null
    private var bassBoost: BassBoost? = null
    private var virtualizer: Virtualizer? = null
    private var loudnessEnhancer: LoudnessEnhancer? = null
    private var presetReverb: PresetReverb? = null
    private var dynamicsProcessing: DynamicsProcessing? = null
    private var currentSessionId: Int = 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initSession" -> {
                    val rawSession = call.argument<Any>("sessionId")
                    val sessionId = when (rawSession) {
                        is Number -> rawSession.toInt()
                        is String -> rawSession.toIntOrNull() ?: 0
                        else -> 0
                    }
                    initAudioEffects(sessionId)
                    result.success(true)
                }
                "setEqualizerBands" -> {
                    val rawList = call.argument<List<*>>("levels")
                    if (rawList != null) {
                        val intList = rawList.mapNotNull { 
                            when (it) {
                                is Number -> it.toInt()
                                is String -> it.toIntOrNull()
                                else -> null
                            }
                        }
                        setAllBands(intList)
                    } else {
                        Log.w(TAG, "setEqualizerBands: levels list was null")
                    }
                    result.success(true)
                }
                "setBassBoost" -> {
                    val raw = call.argument<Any>("strength")
                    val strength = when (raw) {
                        is Number -> raw.toInt()
                        is String -> raw.toIntOrNull() ?: 0
                        else -> 0
                    }
                    setBassBoostStrength(strength)
                    result.success(true)
                }
                "setVirtualizer" -> {
                    val raw = call.argument<Any>("strength")
                    val strength = when (raw) {
                        is Number -> raw.toInt()
                        is String -> raw.toIntOrNull() ?: 0
                        else -> 0
                    }
                    setVirtualizerStrength(strength)
                    result.success(true)
                }
                "setLoudness" -> {
                    val raw = call.argument<Any>("gain")
                    val gain = when (raw) {
                        is Number -> raw.toInt()
                        is String -> raw.toIntOrNull() ?: 0
                        else -> 0
                    }
                    setLoudnessGain(gain)
                    result.success(true)
                }
                "setReverb" -> {
                    val raw = call.argument<Any>("preset")
                    val preset = when (raw) {
                        is Number -> raw.toInt()
                        is String -> raw.toIntOrNull() ?: 0
                        else -> 0
                    }
                    setReverbPreset(preset)
                    result.success(true)
                }
                "setEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    setAllEnabled(enabled)
                    result.success(true)
                }
                "release" -> {
                    releaseAudioEffects()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun initAudioEffects(sessionId: Int) {
        if (sessionId <= 0) return
        if (sessionId == currentSessionId && equalizer != null) return

        releaseAudioEffects()
        currentSessionId = sessionId
        Log.i(TAG, "Initializing hardware DSP audiofx for session ID: $sessionId")

        try {
            equalizer = Equalizer(1000, sessionId).apply {
                enabled = true
            }
            val range = equalizer!!.bandLevelRange
            Log.i(TAG, "Hardware Equalizer initialized: ${equalizer!!.numberOfBands} bands, range: [${range[0]}, ${range[1]}] mB")
            for (b in 0 until equalizer!!.numberOfBands) {
                Log.i(TAG, "Band $b center freq: ${equalizer!!.getCenterFreq(b.toShort()) / 1000} Hz")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing Equalizer: ${e.message}", e)
        }

        try {
            bassBoost = BassBoost(1000, sessionId).apply {
                enabled = true
            }
            Log.i(TAG, "Hardware BassBoost initialized (strength supported: ${bassBoost!!.strengthSupported})")
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing BassBoost: ${e.message}", e)
        }

        try {
            virtualizer = Virtualizer(1000, sessionId).apply {
                enabled = true
            }
            Log.i(TAG, "Hardware Virtualizer initialized (strength supported: ${virtualizer!!.strengthSupported})")
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing Virtualizer: ${e.message}", e)
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                loudnessEnhancer = LoudnessEnhancer(sessionId).apply {
                    enabled = true
                }
                Log.i(TAG, "Hardware LoudnessEnhancer initialized")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing LoudnessEnhancer: ${e.message}", e)
        }

        try {
            presetReverb = PresetReverb(1000, sessionId).apply {
                enabled = true
            }
            Log.i(TAG, "Hardware PresetReverb initialized")
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing PresetReverb: ${e.message}", e)
        }

        // Initialize Android DynamicsProcessing (API 28+) for deep isolator brickwall muting (-60 dB cuts)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            try {
                val freqs = floatArrayOf(60f, 230f, 910f, 3600f, 14000f)
                val builder = DynamicsProcessing.Config.Builder(
                    DynamicsProcessing.VARIANT_FAVOR_FREQUENCY_RESOLUTION,
                    2, // 2 channels
                    true, 5, // pre-EQ with 5 bands
                    false, 0, // MBC
                    true, 5, // post-EQ with 5 bands
                    false // limiter
                )
                val preEq = DynamicsProcessing.Eq(true, true, 5)
                val postEq = DynamicsProcessing.Eq(true, true, 5)
                for (b in 0 until 5) {
                    preEq.setBand(b, DynamicsProcessing.EqBand(true, freqs[b], 0.0f))
                    postEq.setBand(b, DynamicsProcessing.EqBand(true, freqs[b], 0.0f))
                }
                builder.setPreEqAllChannelsTo(preEq)
                builder.setPostEqAllChannelsTo(postEq)
                dynamicsProcessing = DynamicsProcessing(1000, sessionId, builder.build()).apply {
                    enabled = true
                }
                Log.i(TAG, "Hardware DynamicsProcessing initialized with 5-band Pre/Post EQ isolator!")
            } catch (e: Exception) {
                Log.w(TAG, "DynamicsProcessing not available on this device: ${e.message}")
            }
        }
    }

    private fun setAllBands(levels: List<Int>) {
        try {
            val eq = equalizer ?: run {
                Log.w(TAG, "setAllBands skipped: Equalizer is null")
                return
            }
            val numBands = eq.numberOfBands.toInt()
            val range = eq.bandLevelRange
            val min = range[0].toInt()
            val max = range[1].toInt()

            for (i in 0 until minOf(numBands, levels.size)) {
                val clamped = levels[i].coerceIn(min, max).toShort()
                eq.setBandLevel(i.toShort(), clamped)
            }
            Log.d(TAG, "Applied hardware EQ bands (clamped min: $min, max: $max): $levels")
        } catch (e: Exception) {
            Log.e(TAG, "setAllBands error: ${e.message}", e)
        }

        // Apply deep brickwall isolator via DynamicsProcessing if available
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            try {
                val dp = dynamicsProcessing ?: return
                val freqs = floatArrayOf(60f, 230f, 910f, 3600f, 14000f)
                for (i in 0 until minOf(5, levels.size)) {
                    val lvl = levels[i]
                    // If level <= -1000 mB, apply extreme brickwall cut (-45 dB to -60 dB)
                    val dbGain: Float = when {
                        lvl <= -1400 -> -60.0f // Complete mute / unlistenable kill-switch
                        lvl <= -1000 -> -35.0f
                        lvl <= -500 -> -18.0f
                        lvl < 0 -> lvl / 100.0f
                        else -> (lvl / 150.0f).coerceAtMost(12.0f) // Boost
                    }
                    val bandObj = DynamicsProcessing.EqBand(true, freqs[i], dbGain)
                    dp.setPreEqBandAllChannelsTo(i, bandObj)
                    dp.setPostEqBandAllChannelsTo(i, bandObj)
                }
                Log.d(TAG, "Applied DynamicsProcessing brickwall EQ levels: $levels")
            } catch (e: Exception) {
                Log.w(TAG, "DynamicsProcessing setBands error: ${e.message}")
            }
        }
    }

    private fun setBassBoostStrength(strength: Int) {
        try {
            val bb = bassBoost ?: return
            val s = strength.coerceIn(0, 1000).toShort()
            bb.setStrength(s)
            Log.d(TAG, "Applied BassBoost: $s")
        } catch (e: Exception) {
            Log.e(TAG, "setBassBoost error: ${e.message}", e)
        }
    }

    private fun setVirtualizerStrength(strength: Int) {
        try {
            val vz = virtualizer ?: return
            val s = strength.coerceIn(0, 1000).toShort()
            vz.setStrength(s)
            Log.d(TAG, "Applied Virtualizer: $s")
        } catch (e: Exception) {
            Log.e(TAG, "setVirtualizer error: ${e.message}", e)
        }
    }

    private fun setLoudnessGain(gain: Int) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                val le = loudnessEnhancer ?: return
                le.setTargetGain(gain.coerceIn(0, 2000))
                Log.d(TAG, "Applied LoudnessEnhancer: $gain")
            }
        } catch (e: Exception) {
            Log.e(TAG, "setLoudness error: ${e.message}", e)
        }
    }

    private fun setReverbPreset(preset: Int) {
        try {
            val rev = presetReverb ?: return
            rev.preset = preset.toShort()
            Log.d(TAG, "Applied PresetReverb: $preset")
        } catch (e: Exception) {
            Log.e(TAG, "setReverb error: ${e.message}", e)
        }
    }

    private fun setAllEnabled(enabled: Boolean) {
        try {
            equalizer?.enabled = enabled
            bassBoost?.enabled = enabled
            virtualizer?.enabled = enabled
            loudnessEnhancer?.enabled = enabled
            presetReverb?.enabled = enabled
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                dynamicsProcessing?.enabled = enabled
            }
            Log.d(TAG, "AudioFx setAllEnabled: $enabled")
        } catch (e: Exception) {
            Log.e(TAG, "setAllEnabled error: ${e.message}", e)
        }
    }

    private fun releaseAudioEffects() {
        try {
            equalizer?.release()
            equalizer = null
            bassBoost?.release()
            bassBoost = null
            virtualizer?.release()
            virtualizer = null
            loudnessEnhancer?.release()
            loudnessEnhancer = null
            presetReverb?.release()
            presetReverb = null
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                dynamicsProcessing?.release()
                dynamicsProcessing = null
            }
            Log.d(TAG, "AudioFx released")
        } catch (e: Exception) {
            Log.e(TAG, "releaseAudioEffects error: ${e.message}", e)
        }
    }

    override fun onDestroy() {
        releaseAudioEffects()
        super.onDestroy()
    }
}

package com.squareinfosoft.auramix.android

import android.media.audiofx.BassBoost
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
    private val CHANNEL = "com.squareinfosoft.auramix/audiofx"
    private var equalizer: Equalizer? = null
    private var bassBoost: BassBoost? = null
    private var virtualizer: Virtualizer? = null
    private var loudnessEnhancer: LoudnessEnhancer? = null
    private var presetReverb: PresetReverb? = null
    private var currentSessionId: Int = 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initSession" -> {
                    val sessionId = call.argument<Int>("sessionId") ?: 0
                    initAudioEffects(sessionId)
                    result.success(true)
                }
                "setEqualizerBands" -> {
                    val levels = call.argument<List<Int>>("levels")
                    if (levels != null) {
                        setAllBands(levels)
                    }
                    result.success(true)
                }
                "setBassBoost" -> {
                    val strength = call.argument<Int>("strength") ?: 0
                    setBassBoostStrength(strength)
                    result.success(true)
                }
                "setVirtualizer" -> {
                    val strength = call.argument<Int>("strength") ?: 0
                    setVirtualizerStrength(strength)
                    result.success(true)
                }
                "setLoudness" -> {
                    val gain = call.argument<Int>("gain") ?: 0
                    setLoudnessGain(gain)
                    result.success(true)
                }
                "setReverb" -> {
                    val preset = call.argument<Int>("preset") ?: 0
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

        try {
            equalizer = Equalizer(0, sessionId).apply {
                enabled = true
            }
            Log.d("AuraMixAudioFx", "Equalizer initialized for session $sessionId with ${equalizer?.numberOfBands} bands")
        } catch (e: Exception) {
            Log.e("AuraMixAudioFx", "Error initializing Equalizer: ${e.message}")
        }

        try {
            bassBoost = BassBoost(0, sessionId).apply {
                enabled = true
            }
            Log.d("AuraMixAudioFx", "BassBoost initialized for session $sessionId")
        } catch (e: Exception) {
            Log.e("AuraMixAudioFx", "Error initializing BassBoost: ${e.message}")
        }

        try {
            virtualizer = Virtualizer(0, sessionId).apply {
                enabled = true
            }
            Log.d("AuraMixAudioFx", "Virtualizer initialized for session $sessionId")
        } catch (e: Exception) {
            Log.e("AuraMixAudioFx", "Error initializing Virtualizer: ${e.message}")
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                loudnessEnhancer = LoudnessEnhancer(sessionId).apply {
                    enabled = true
                }
                Log.d("AuraMixAudioFx", "LoudnessEnhancer initialized for session $sessionId")
            }
        } catch (e: Exception) {
            Log.e("AuraMixAudioFx", "Error initializing LoudnessEnhancer: ${e.message}")
        }

        try {
            presetReverb = PresetReverb(0, sessionId).apply {
                enabled = true
            }
            Log.d("AuraMixAudioFx", "PresetReverb initialized for session $sessionId")
        } catch (e: Exception) {
            Log.e("AuraMixAudioFx", "Error initializing PresetReverb: ${e.message}")
        }
    }

    private fun setAllBands(levels: List<Int>) {
        try {
            val eq = equalizer ?: return
            val numBands = eq.numberOfBands.toInt()
            val range = eq.bandLevelRange
            val min = range[0].toInt()
            val max = range[1].toInt()

            for (i in 0 until minOf(numBands, levels.size)) {
                val clamped = levels[i].coerceIn(min, max).toShort()
                eq.setBandLevel(i.toShort(), clamped)
            }
        } catch (e: Exception) {
            Log.e("AuraMixAudioFx", "setAllBands error: ${e.message}")
        }
    }

    private fun setBassBoostStrength(strength: Int) {
        try {
            val bb = bassBoost ?: return
            val s = strength.coerceIn(0, 1000).toShort()
            bb.setStrength(s)
        } catch (e: Exception) {
            Log.e("AuraMixAudioFx", "setBassBoost error: ${e.message}")
        }
    }

    private fun setVirtualizerStrength(strength: Int) {
        try {
            val vz = virtualizer ?: return
            val s = strength.coerceIn(0, 1000).toShort()
            vz.setStrength(s)
        } catch (e: Exception) {
            Log.e("AuraMixAudioFx", "setVirtualizer error: ${e.message}")
        }
    }

    private fun setLoudnessGain(gain: Int) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                val le = loudnessEnhancer ?: return
                le.setTargetGain(gain.coerceIn(0, 2000))
            }
        } catch (e: Exception) {
            Log.e("AuraMixAudioFx", "setLoudness error: ${e.message}")
        }
    }

    private fun setReverbPreset(preset: Int) {
        try {
            val rev = presetReverb ?: return
            rev.preset = preset.toShort()
        } catch (e: Exception) {
            Log.e("AuraMixAudioFx", "setReverb error: ${e.message}")
        }
    }

    private fun setAllEnabled(enabled: Boolean) {
        try {
            equalizer?.enabled = enabled
            bassBoost?.enabled = enabled
            virtualizer?.enabled = enabled
            loudnessEnhancer?.enabled = enabled
            presetReverb?.enabled = enabled
        } catch (e: Exception) {
            Log.e("AuraMixAudioFx", "setAllEnabled error: ${e.message}")
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
        } catch (e: Exception) {
            Log.e("AuraMixAudioFx", "releaseAudioEffects error: ${e.message}")
        }
    }

    override fun onDestroy() {
        releaseAudioEffects()
        super.onDestroy()
    }
}

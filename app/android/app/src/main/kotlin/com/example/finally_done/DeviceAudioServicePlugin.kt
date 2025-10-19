package com.example.finally_done

import android.content.Context
import android.media.AudioManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class DeviceAudioServicePlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var audioManager: AudioManager? = null
    private var eventSink: EventChannel.EventSink? = null
    private var audioStateListener: AudioManager.OnAudioFocusChangeListener? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "device_audio_service")
        channel.setMethodCallHandler(this)
        
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "device_audio_events")
        eventChannel.setStreamHandler(this)
        
        audioManager = flutterPluginBinding.applicationContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isDeviceSilent" -> {
                val isSilent = audioManager?.ringerMode == AudioManager.RINGER_MODE_SILENT
                result.success(isSilent)
            }
            "isVolumeMuted" -> {
                val isMuted = audioManager?.getStreamVolume(AudioManager.STREAM_MUSIC) == 0
                result.success(isMuted)
            }
            "getVolumeLevel" -> {
                val maxVolume = audioManager?.getStreamMaxVolume(AudioManager.STREAM_MUSIC) ?: 1
                val currentVolume = audioManager?.getStreamVolume(AudioManager.STREAM_MUSIC) ?: 0
                val volumeLevel = if (maxVolume > 0) currentVolume.toFloat() / maxVolume.toFloat() else 0f
                result.success(volumeLevel)
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        startAudioStateMonitoring()
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        stopAudioStateMonitoring()
    }

    private fun startAudioStateMonitoring() {
        audioStateListener = AudioManager.OnAudioFocusChangeListener { focusChange ->
            when (focusChange) {
                AudioManager.AUDIOFOCUS_GAIN -> {
                    // Audio focus gained - device is not silent
                    eventSink?.success(mapOf("isSilent" to false))
                }
                AudioManager.AUDIOFOCUS_LOSS -> {
                    // Audio focus lost - device might be silent
                    val isSilent = audioManager?.ringerMode == AudioManager.RINGER_MODE_SILENT
                    eventSink?.success(mapOf("isSilent" to isSilent))
                }
                AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                    // Temporary loss - check ringer mode
                    val isSilent = audioManager?.ringerMode == AudioManager.RINGER_MODE_SILENT
                    eventSink?.success(mapOf("isSilent" to isSilent))
                }
            }
        }
        
        // Request audio focus to start monitoring
        audioManager?.requestAudioFocus(
            audioStateListener,
            AudioManager.STREAM_MUSIC,
            AudioManager.AUDIOFOCUS_GAIN
        )
    }

    private fun stopAudioStateMonitoring() {
        audioStateListener?.let { listener ->
            audioManager?.abandonAudioFocus(listener)
        }
        audioStateListener = null
    }
}
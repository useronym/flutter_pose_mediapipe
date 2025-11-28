package com.carecode.flutter_mp_pose_lm

import android.app.Activity
import android.content.Context
import android.util.Log
import android.view.View
import android.widget.FrameLayout
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import io.flutter.plugin.platform.PlatformViewRegistry
import io.flutter.plugin.common.MethodChannel
import androidx.camera.core.CameraSelector

class FlutterMpPoseLandmarkerPlugin : FlutterPlugin, EventChannel.StreamHandler, ActivityAware {

    private lateinit var eventChannel: EventChannel
    private lateinit var methodChannel: MethodChannel
    private var cameraManager: CameraManager? = null
    private var activity: Activity? = null
    private var platformViewRegistry: PlatformViewRegistry? = null
    private var lensFacing: Int = CameraSelector.LENS_FACING_FRONT 

    // Logging toggle variable
    private var isLoggingEnabled: Boolean = false

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        Log.d("PoseLandmarkerPlugin", "onAttachedToEngine called")

        // Initialize event channel for sending pose detection results
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "pose_landmarker/events")
        eventChannel.setStreamHandler(this)

        // Initialize method channel for method calls from Flutter
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "pose_landmarker/methods")
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {

                "setConfig" -> {
                    // Read configuration values from Flutter
                    val delegate = call.argument<Int>("delegate") ?: PoseLandmarkerHelper.DELEGATE_CPU
                    val model = call.argument<Int>("model") ?: PoseLandmarkerHelper.MODEL_POSE_LANDMARKER_LITE
                    val minPoseDetectionConfidence = call.argument<Double>("minPoseDetectionConfidence")?.toFloat()
                        ?: PoseLandmarkerHelper.DEFAULT_POSE_DETECTION_CONFIDENCE
                    val minPoseTrackingConfidence = call.argument<Double>("minPoseTrackingConfidence")?.toFloat()
                        ?: PoseLandmarkerHelper.DEFAULT_POSE_TRACKING_CONFIDENCE
                    val minPosePresenceConfidence = call.argument<Double>("minPosePresenceConfidence")?.toFloat()
                        ?: PoseLandmarkerHelper.DEFAULT_POSE_PRESENCE_CONFIDENCE

                    // Pass values to CameraManager / PoseLandmarkerHelper
                    cameraManager?.setConfig(delegate, model, minPoseDetectionConfidence, minPoseTrackingConfidence, minPosePresenceConfidence)

                    result.success(null)
                }

                "switchCamera" -> {
                    // Toggle lens facing
                    lensFacing = if (lensFacing == CameraSelector.LENS_FACING_BACK) {
                        CameraSelector.LENS_FACING_FRONT
                    } else {
                        CameraSelector.LENS_FACING_BACK
                    }
                    cameraManager?.switchCamera()
                    result.success(null)
                }

                "checkCameraPermission" -> {
                    // Check if camera permission is granted
                    val hasPermission = androidx.core.content.ContextCompat.checkSelfPermission(
                        activity!!,
                        android.Manifest.permission.CAMERA
                    ) == android.content.pm.PackageManager.PERMISSION_GRANTED

                    result.success(hasPermission)
                }

                "getCurrentCamera" -> {
                    // Return the currently active camera as a string ("front" or "back")
                    val currentLens = cameraManager?.getCurrentCameraLens() ?: CameraSelector.LENS_FACING_BACK
                    val cameraString = if (currentLens == CameraSelector.LENS_FACING_FRONT) "front" else "back"
                    result.success(cameraString)
                }

                "setLoggingEnabled" -> {
                    // Enable or disable logging from Flutter
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    isLoggingEnabled = enabled
                    result.success(null)
                }

                "pauseAnalysis" -> {
                    // Pause pose detection without stopping the camera
                    cameraManager?.pauseAnalysis()
                    result.success(null)
                }

                "resumeAnalysis" -> {
                    // Resume pose detection while keeping the camera live
                    cameraManager?.resumeAnalysis()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }

        platformViewRegistry = flutterPluginBinding.platformViewRegistry
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity

        // Initialize CameraManager and start the camera
        cameraManager = CameraManager(activity!!).apply {
            startCamera()
        }
        
        // Register a PlatformView for displaying the camera preview
        platformViewRegistry?.registerViewFactory("camera_preview_view", 
            object : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
                override fun create(context: Context, id: Int, args: Any?): PlatformView {
                    return object : PlatformView {
                        override fun getView() = cameraManager?.previewView ?: run {
                            View(context).apply { 
                                layoutParams = FrameLayout.LayoutParams(1, 1)
                            }
                        }
                        override fun dispose() {}
                    }
                }
            }
        )
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        // Set event sink and enable pose analysis
        cameraManager?.apply {
            setEventSink(events)
            enableAnalysis()
        }
    }

    override fun onCancel(arguments: Any?) {
        // Disable pose analysis
        cameraManager?.disableAnalysis()
    }

    override fun onDetachedFromActivity() {
        // Clean up camera and manager
        cameraManager?.dispose()
        cameraManager = null
        activity = null
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        eventChannel.setStreamHandler(null)
    }
    
    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) = onAttachedToActivity(binding)
}

package com.carecode.flutter_mp_pose_lm

import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import com.google.gson.Gson
import io.flutter.plugin.common.EventChannel
import java.util.Timer
import java.util.TimerTask
import kotlin.math.sin

class MockPoseManager : IPoseManager {

    private var eventSink: EventChannel.EventSink? = null
    private var timer: Timer? = null
    private var tick = 0.0
    private var paused = false
    private val gson = Gson()

    override fun setEventSink(events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun enableAnalysis() {
        startTimer()
    }

    override fun disableAnalysis() {
        stopTimer()
    }

    override fun pauseAnalysis() {
        paused = true
    }

    override fun resumeAnalysis() {
        paused = false
    }

    override fun dispose() {
        stopTimer()
        eventSink = null
    }

    private fun startTimer() {
        stopTimer() // avoid double-start
        timer = Timer()
        timer?.scheduleAtFixedRate(object : TimerTask() {
            override fun run() {
                if (!paused) emitMockPose()
            }
        }, 0L, 100L)
    }

    private fun stopTimer() {
        timer?.cancel()
        timer = null
    }

    private fun emitMockPose() {
        tick += 0.08
        val armSwing = sin(tick).toFloat() * 0.05f

        // Match CameraManager's Landmark data class shape exactly
        data class Landmark(val x: Float, val y: Float, val z: Float, val visibility: Double = 1.0)

        val landmarks = buildMockLandmarks(armSwing).map { lm ->
            Landmark(
                x = lm[0],
                y = lm[1],
                z = lm[2],
                visibility = 0.99
            )
        }

        // Match CameraManager's resultMap structure exactly
        val resultMap = mapOf(
            "timestampMs" to SystemClock.uptimeMillis(),
            "landmarks" to landmarks,
            "fps" to 10.0
        )

        // Serialize to JSON string — same as CameraManager does with gson.toJson()
        val json = gson.toJson(resultMap)

        Handler(Looper.getMainLooper()).post {
            eventSink?.success(json)
        }
    }

    override fun releaseCamera() { /* nothing to release */ }


    private fun buildMockLandmarks(armSwing: Float): List<FloatArray> {
        return listOf(
            floatArrayOf(0.50f, 0.10f, 0f),  // 0  nose
            floatArrayOf(0.52f, 0.09f, 0f),  // 1  left eye inner
            floatArrayOf(0.54f, 0.09f, 0f),  // 2  left eye
            floatArrayOf(0.56f, 0.09f, 0f),  // 3  left eye outer
            floatArrayOf(0.48f, 0.09f, 0f),  // 4  right eye inner
            floatArrayOf(0.46f, 0.09f, 0f),  // 5  right eye
            floatArrayOf(0.44f, 0.09f, 0f),  // 6  right eye outer
            floatArrayOf(0.55f, 0.11f, 0f),  // 7  left ear
            floatArrayOf(0.45f, 0.11f, 0f),  // 8  right ear
            floatArrayOf(0.53f, 0.12f, 0f),  // 9  mouth left
            floatArrayOf(0.47f, 0.12f, 0f),  // 10 mouth right
            floatArrayOf(0.62f, 0.25f, 0f),  // 11 left shoulder
            floatArrayOf(0.38f, 0.25f, 0f),  // 12 right shoulder
            floatArrayOf(0.75f, 0.25f + armSwing, 0f), // 13 left elbow
            floatArrayOf(0.25f, 0.25f + armSwing, 0f), // 14 right elbow
            floatArrayOf(0.88f, 0.25f + armSwing * 2, 0f), // 15 left wrist
            floatArrayOf(0.12f, 0.25f + armSwing * 2, 0f), // 16 right wrist
            floatArrayOf(0.90f, 0.26f + armSwing * 2, 0f), // 17 left pinky
            floatArrayOf(0.10f, 0.26f + armSwing * 2, 0f), // 18 right pinky
            floatArrayOf(0.91f, 0.24f + armSwing * 2, 0f), // 19 left index
            floatArrayOf(0.09f, 0.24f + armSwing * 2, 0f), // 20 right index
            floatArrayOf(0.89f, 0.25f + armSwing * 2, 0f), // 21 left thumb
            floatArrayOf(0.11f, 0.25f + armSwing * 2, 0f), // 22 right thumb
            floatArrayOf(0.57f, 0.55f, 0f),  // 23 left hip
            floatArrayOf(0.43f, 0.55f, 0f),  // 24 right hip
            floatArrayOf(0.58f, 0.72f, 0f),  // 25 left knee
            floatArrayOf(0.42f, 0.72f, 0f),  // 26 right knee
            floatArrayOf(0.58f, 0.88f, 0f),  // 27 left ankle
            floatArrayOf(0.42f, 0.88f, 0f),  // 28 right ankle
            floatArrayOf(0.56f, 0.91f, 0f),  // 29 left heel
            floatArrayOf(0.44f, 0.91f, 0f),  // 30 right heel
            floatArrayOf(0.60f, 0.93f, 0f),  // 31 left foot index
            floatArrayOf(0.40f, 0.93f, 0f),  // 32 right foot index
        )
    }
}
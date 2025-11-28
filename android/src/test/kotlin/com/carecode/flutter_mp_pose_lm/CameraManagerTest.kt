package com.carecode.flutter_mp_pose_lm

import android.app.Activity
import androidx.camera.core.CameraSelector
import io.flutter.plugin.common.EventChannel
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mock
import org.mockito.Mockito.*
import org.mockito.junit.MockitoJUnitRunner
import org.junit.Assert.*

@RunWith(MockitoJUnitRunner::class)
class CameraManagerTest {

    @Mock
    private lateinit var mockActivity: Activity

    @Mock
    private lateinit var mockEventSink: EventChannel.EventSink

    private lateinit var cameraManager: CameraManager

    @Before
    fun setup() {
        // Note: Full initialization requires Android context
        // These tests verify logic without full Android framework
    }

    @Test
    fun `getCurrentCameraLens returns back camera by default`() {
        cameraManager = CameraManager(mockActivity)
        assertEquals(CameraSelector.LENS_FACING_BACK, cameraManager.getCurrentCameraLens())
    }

    @Test
    fun `switchCamera toggles between front and back`() {
        cameraManager = CameraManager(mockActivity)
        val initialLens = cameraManager.getCurrentCameraLens()
        
        // After switch, should be different
        cameraManager.switchCamera()
        assertNotEquals(initialLens, cameraManager.getCurrentCameraLens())
    }

    @Test
    fun `setEventSink stores event sink`() {
        cameraManager = CameraManager(mockActivity)
        cameraManager.setEventSink(mockEventSink)
        // Verify no exception thrown
    }

    @Test
    fun `pauseAnalysis disables analysis`() {
        cameraManager = CameraManager(mockActivity)
        cameraManager.pauseAnalysis()
        // Verify no exception thrown
    }

    @Test
    fun `resumeAnalysis enables analysis`() {
        cameraManager = CameraManager(mockActivity)
        cameraManager.resumeAnalysis()
        // Verify no exception thrown
    }

    @Test
    fun `logging can be enabled and disabled`() {
        cameraManager = CameraManager(mockActivity)
        cameraManager.isLoggingEnabled = true
        assertTrue(cameraManager.isLoggingEnabled)
        
        cameraManager.isLoggingEnabled = false
        assertFalse(cameraManager.isLoggingEnabled)
    }
}

package com.carecode.flutter_mp_pose_lm

import android.content.Context
import com.google.mediapipe.tasks.vision.core.RunningMode
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mock
import org.mockito.junit.MockitoJUnitRunner
import org.junit.Assert.*

@RunWith(MockitoJUnitRunner::class)
class PoseLandmarkerHelperTest {

    @Mock
    private lateinit var mockContext: Context

    @Mock
    private lateinit var mockListener: PoseLandmarkerHelper.LandmarkerListener

    @Test
    fun `default values are set correctly`() {
        assertEquals(0.5f, PoseLandmarkerHelper.DEFAULT_POSE_DETECTION_CONFIDENCE)
        assertEquals(0.5f, PoseLandmarkerHelper.DEFAULT_POSE_TRACKING_CONFIDENCE)
        assertEquals(0.5f, PoseLandmarkerHelper.DEFAULT_POSE_PRESENCE_CONFIDENCE)
    }

    @Test
    fun `delegate constants are correct`() {
        assertEquals(0, PoseLandmarkerHelper.DELEGATE_CPU)
        assertEquals(1, PoseLandmarkerHelper.DELEGATE_GPU)
    }

    @Test
    fun `model constants are correct`() {
        assertEquals(0, PoseLandmarkerHelper.MODEL_POSE_LANDMARKER_FULL)
        assertEquals(1, PoseLandmarkerHelper.MODEL_POSE_LANDMARKER_LITE)
        assertEquals(2, PoseLandmarkerHelper.MODEL_POSE_LANDMARKER_HEAVY)
    }

    @Test
    fun `error codes are correct`() {
        assertEquals(0, PoseLandmarkerHelper.OTHER_ERROR)
        assertEquals(1, PoseLandmarkerHelper.GPU_ERROR)
    }

    @Test
    fun `ResultBundle stores data correctly`() {
        val resultBundle = PoseLandmarkerHelper.ResultBundle(
            results = emptyList(),
            inferenceTime = 100L,
            inputImageHeight = 480,
            inputImageWidth = 640
        )

        assertEquals(100L, resultBundle.inferenceTime)
        assertEquals(480, resultBundle.inputImageHeight)
        assertEquals(640, resultBundle.inputImageWidth)
        assertTrue(resultBundle.results.isEmpty())
    }
}

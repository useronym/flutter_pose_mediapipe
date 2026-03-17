// IPoseManager.kt
package com.carecode.flutter_mp_pose_lm

import io.flutter.plugin.common.EventChannel

interface IPoseManager {
    fun setEventSink(events: EventChannel.EventSink?)
    fun enableAnalysis()
    fun disableAnalysis()
    fun pauseAnalysis()
    fun resumeAnalysis()
    fun dispose()
    fun releaseCamera()
}
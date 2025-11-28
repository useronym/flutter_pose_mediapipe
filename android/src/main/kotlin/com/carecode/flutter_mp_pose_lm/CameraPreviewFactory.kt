package com.carecode.flutter_mp_pose_lm

import android.app.Activity
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import io.flutter.plugin.common.StandardMessageCodec

class CameraPreviewFactory(
    private val activity: Activity
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: android.content.Context, id: Int, args: Any?): PlatformView {
        return CameraPreview(activity)
    }
}

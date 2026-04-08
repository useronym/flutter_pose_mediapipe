import Flutter
import UIKit
import AVFoundation

/// Factory for creating native camera preview platform views.
/// Registered with viewType `camera_preview_view` (same as Android).
class NativeCameraViewFactory: NSObject, FlutterPlatformViewFactory {
    private weak var cameraManager: CameraManager?

    init(cameraManager: CameraManager) {
        self.cameraManager = cameraManager
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return NativeCameraView(frame: frame, cameraManager: cameraManager)
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

/// A platform view that displays the native camera preview via AVCaptureVideoPreviewLayer.
class NativeCameraView: NSObject, FlutterPlatformView {
    private let containerView: UIView

    init(frame: CGRect, cameraManager: CameraManager?) {
        containerView = UIView(frame: frame)
        containerView.backgroundColor = .black
        super.init()

        if let manager = cameraManager {
            let previewLayer = manager.makePreviewLayer(for: containerView)
            containerView.layer.addSublayer(previewLayer)

            // Ensure the preview layer resizes with the view
            containerView.layoutIfNeeded()
        }
    }

    func view() -> UIView {
        return containerView
    }
}

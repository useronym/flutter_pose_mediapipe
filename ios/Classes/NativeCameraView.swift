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
    private let containerView: PreviewContainerView

    init(frame: CGRect, cameraManager: CameraManager?) {
        containerView = PreviewContainerView(frame: frame)
        containerView.backgroundColor = .black
        super.init()

        if let manager = cameraManager {
            let previewLayer = manager.makePreviewLayer(for: containerView)
            containerView.previewLayer = previewLayer
            containerView.layer.addSublayer(previewLayer)
        }
    }

    func view() -> UIView {
        return containerView
    }
}

/// UIView subclass that keeps its preview layer sized to bounds on rotation / resize.
private class PreviewContainerView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer?

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}

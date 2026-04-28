import Flutter
import UIKit
import AVFoundation

/// Flutter plugin for MediaPipe Pose Landmarker on iOS.
/// Mirrors the Android `FlutterMpPoseLandmarkerPlugin.kt`.
///
/// - Registers EventChannel `pose_landmarker/events` for streaming pose results
/// - Registers MethodChannel `pose_landmarker/methods` for control commands
/// - Registers platform view `camera_preview_view` for native camera preview
public class FlutterMpPoseLandmarkerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    private var eventChannel: FlutterEventChannel?
    private var methodChannel: FlutterMethodChannel?
    private var eventSink: FlutterEventSink?

    private var cameraManager: CameraManager?
    private var videoAnalysisManager: VideoAnalysisManager?
    private var registrar: FlutterPluginRegistrar?
    private var sourceMode: String = "camera"
    private var currentDelegate: Int = PoseLandmarkerHelper.delegateCPU
    private var currentModel: Int = PoseLandmarkerHelper.modelLite
    private var currentMinPoseDetectionConfidence: Float = PoseLandmarkerHelper.defaultPoseDetectionConfidence
    private var currentMinPoseTrackingConfidence: Float = PoseLandmarkerHelper.defaultPoseTrackingConfidence
    private var currentMinPosePresenceConfidence: Float = PoseLandmarkerHelper.defaultPosePresenceConfidence

    // MARK: - FlutterPlugin Registration

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = FlutterMpPoseLandmarkerPlugin()
        instance.registrar = registrar

        // Event channel for streaming pose results
        let eventChannel = FlutterEventChannel(
            name: "pose_landmarker/events",
            binaryMessenger: registrar.messenger()
        )
        eventChannel.setStreamHandler(instance)
        instance.eventChannel = eventChannel

        // Method channel for control commands
        let methodChannel = FlutterMethodChannel(
            name: "pose_landmarker/methods",
            binaryMessenger: registrar.messenger()
        )
        methodChannel.setMethodCallHandler(instance.handle)
        instance.methodChannel = methodChannel

        // Create camera manager
        let cameraManager = CameraManager()
        instance.cameraManager = cameraManager
        let videoAnalysisManager = VideoAnalysisManager()
        instance.videoAnalysisManager = videoAnalysisManager

        // Register platform view for native camera preview
        let factory = NativeCameraViewFactory(cameraManager: cameraManager)
        registrar.register(factory, withId: "camera_preview_view")
    }

    // MARK: - MethodChannel Handler

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]

        switch call.method {
        case "setConfig":
            let delegate = args?["delegate"] as? Int ?? PoseLandmarkerHelper.delegateCPU
            let model = args?["model"] as? Int ?? PoseLandmarkerHelper.modelLite
            let minDetection = (args?["minPoseDetectionConfidence"] as? Double)
                .map { Float($0) } ?? PoseLandmarkerHelper.defaultPoseDetectionConfidence
            let minTracking = (args?["minPoseTrackingConfidence"] as? Double)
                .map { Float($0) } ?? PoseLandmarkerHelper.defaultPoseTrackingConfidence
            let minPresence = (args?["minPosePresenceConfidence"] as? Double)
                .map { Float($0) } ?? PoseLandmarkerHelper.defaultPosePresenceConfidence

            currentDelegate = delegate
            currentModel = model
            currentMinPoseDetectionConfidence = minDetection
            currentMinPoseTrackingConfidence = minTracking
            currentMinPosePresenceConfidence = minPresence

            cameraManager?.setConfig(
                delegate: delegate,
                model: model,
                minPoseDetectionConfidence: minDetection,
                minPoseTrackingConfidence: minTracking,
                minPosePresenceConfidence: minPresence
            )
            videoAnalysisManager?.setConfig(
                delegate: delegate,
                model: model,
                minPoseDetectionConfidence: minDetection,
                minPoseTrackingConfidence: minTracking,
                minPosePresenceConfidence: minPresence
            )
            result(nil)

        case "configureSource":
            sourceMode = args?["source"] as? String ?? "camera"
            if sourceMode == "camera" {
                videoAnalysisManager?.stopVideoAnalysis()
            } else {
                cameraManager?.releaseCamera()
            }
            result(nil)

        case "startVideoDetection":
            guard let path = args?["path"] as? String, !path.isEmpty else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENT",
                        message: "Video path is required",
                        details: nil
                    )
                )
                return
            }

            let intervalMs = args?["intervalMs"] as? Int ?? 33
            let loop = args?["loop"] as? Bool ?? true
            let startPositionMs = args?["startPositionMs"] as? Int ?? 0
            sourceMode = "video"
            cameraManager?.disableAnalysis()
            cameraManager?.releaseCamera()
            if videoAnalysisManager == nil {
                let manager = VideoAnalysisManager()
                manager.setConfig(
                    delegate: currentDelegate,
                    model: currentModel,
                    minPoseDetectionConfidence: currentMinPoseDetectionConfidence,
                    minPoseTrackingConfidence: currentMinPoseTrackingConfidence,
                    minPosePresenceConfidence: currentMinPosePresenceConfidence
                )
                videoAnalysisManager = manager
            }
            videoAnalysisManager?.startVideoAnalysis(
                filePath: path,
                intervalMs: intervalMs,
                loop: loop,
                startPositionMs: startPositionMs
            )
            result(nil)

        case "stopVideoDetection":
            videoAnalysisManager?.stopVideoAnalysis()
            result(nil)

        case "switchCamera":
            cameraManager?.switchCamera()
            result(nil)

        case "getCurrentCamera":
            let position = cameraManager?.getCurrentCameraPosition() ?? .front
            result(position == .front ? "front" : "back")

        case "setLoggingEnabled":
            let enabled = args?["enabled"] as? Bool ?? false
            cameraManager?.isLoggingEnabled = enabled
            result(nil)

        case "pauseAnalysis":
            cameraManager?.pauseAnalysis()
            result(nil)

        case "resumeAnalysis":
            cameraManager?.resumeAnalysis()
            result(nil)

        case "releaseCamera":
            cameraManager?.releaseCamera()
            result(nil)

        case "restoreCamera":
            cameraManager?.startCamera()
            result(nil)

        case "checkCameraPermission":
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            result(status == .authorized)

        case "requestCameraPermission":
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    result(granted)
                }
            }

        case "isPreviewMirrored":
            result(cameraManager?.previewIsMirrored ?? false)

        case "isEmulator":
            #if targetEnvironment(simulator)
            result(true)
            #else
            result(false)
            #endif

        case "getSupportedFpsRanges":
            let ranges = cameraManager?.getSupportedFpsRanges() ?? []
            result(ranges)

        case "setTargetFps":
            let min = args?["min"] as? Int ?? 0
            let max = args?["max"] as? Int ?? 0
            cameraManager?.setTargetFps(min: min, max: max)
            result(nil)

        case "clearTargetFps":
            cameraManager?.clearTargetFps()
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - FlutterStreamHandler (EventChannel)

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        print("[Plugin] onListen — cameraManager: \(cameraManager != nil)")

        // Wire camera manager results to event sink
        cameraManager?.onResults = { [weak self] json in
            self?.eventSink?(json)
        }
        cameraManager?.onError = { [weak self] error, code in
            self?.eventSink?(FlutterError(code: "POSE_ERROR", message: error, details: ["code": code]))
        }
        videoAnalysisManager?.onResults = { [weak self] json in
            self?.eventSink?(json)
        }
        videoAnalysisManager?.onError = { [weak self] error, code in
            self?.eventSink?(FlutterError(code: "VIDEO_ERROR", message: error, details: ["code": code]))
        }

        if sourceMode == "camera" {
            videoAnalysisManager?.stopVideoAnalysis()
            cameraManager?.enableAnalysis()
            cameraManager?.startCamera()
        } else {
            cameraManager?.disableAnalysis()
            cameraManager?.releaseCamera()
        }

        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        videoAnalysisManager?.stopVideoAnalysis()
        cameraManager?.disableAnalysis()
        cameraManager?.releaseCamera()
        eventSink = nil
        return nil
    }
}

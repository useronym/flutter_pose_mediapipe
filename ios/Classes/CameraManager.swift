import AVFoundation
import UIKit

/// Manages AVCaptureSession, camera preview, and frame delivery for pose detection.
/// Mirrors the Android `CameraManager.kt`.
///
/// Key difference from Android: CMSampleBuffer → MPImage is zero-copy.
/// No YUV→RGB bitmap conversion is needed on iOS.
class CameraManager: NSObject, PoseLandmarkerHelperDelegate {

    // MARK: - Properties

    private let captureSession = AVCaptureSession()
    private let videoDataOutputQueue = DispatchQueue(
        label: "com.carecode.flutter_mp_pose_lm.videoOutput",
        qos: .userInteractive
    )

    private var currentCameraPosition: AVCaptureDevice.Position = .front
    private var videoOutput: AVCaptureVideoDataOutput?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?

    var isAnalysisEnabled = false
    var isLoggingEnabled = false

    private var poseLandmarkerHelper: PoseLandmarkerHelper

    // FPS tracking
    private var lastFrameTime: CFTimeInterval = 0
    private var fps: Double = 0

    // Callback for results — set by the plugin
    var onResults: ((_ json: String) -> Void)?
    var onError: ((_ error: String, _ code: Int) -> Void)?

    // MARK: - Init

    init(
        currentDelegate: Int = PoseLandmarkerHelper.delegateGPU,
        currentModel: Int = PoseLandmarkerHelper.modelLite,
        minPoseDetectionConfidence: Float = PoseLandmarkerHelper.defaultPoseDetectionConfidence,
        minPoseTrackingConfidence: Float = PoseLandmarkerHelper.defaultPoseTrackingConfidence,
        minPosePresenceConfidence: Float = PoseLandmarkerHelper.defaultPosePresenceConfidence
    ) {
        poseLandmarkerHelper = PoseLandmarkerHelper(
            minPoseDetectionConfidence: minPoseDetectionConfidence,
            minPoseTrackingConfidence: minPoseTrackingConfidence,
            minPosePresenceConfidence: minPosePresenceConfidence,
            currentModel: currentModel,
            currentDelegate: currentDelegate
        )
        super.init()
        poseLandmarkerHelper.delegate = self
    }

    // MARK: - Configuration

    func setConfig(
        delegate: Int,
        model: Int,
        minPoseDetectionConfidence: Float,
        minPoseTrackingConfidence: Float,
        minPosePresenceConfidence: Float
    ) {
        poseLandmarkerHelper.updateConfig(
            delegate: delegate,
            model: model,
            minPoseDetectionConfidence: minPoseDetectionConfidence,
            minPoseTrackingConfidence: minPoseTrackingConfidence,
            minPosePresenceConfidence: minPosePresenceConfidence
        )
    }

    // MARK: - Camera Setup

    func startCamera() {
        videoDataOutputQueue.async { [weak self] in
            self?.setupCamera()
        }
    }

    private func setupCamera() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .vga640x480

        // Remove existing inputs
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }

        // Add camera input
        guard let camera = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: currentCameraPosition
        ) else {
            if isLoggingEnabled {
                print("[CameraManager] No camera found for position \(currentCameraPosition.rawValue)")
            }
            captureSession.commitConfiguration()
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
        } catch {
            if isLoggingEnabled {
                print("[CameraManager] Failed to create camera input: \(error)")
            }
            captureSession.commitConfiguration()
            return
        }

        // Add video data output (if not already added)
        if videoOutput == nil {
            let output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true // equivalent to STRATEGY_KEEP_ONLY_LATEST
            output.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            if captureSession.canAddOutput(output) {
                captureSession.addOutput(output)
            }
            videoOutput = output
        }

        // Set delegate for frame delivery
        if isAnalysisEnabled {
            videoOutput?.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            videoOutput?.setSampleBufferDelegate(nil, queue: nil)
        }

        // Mirror front camera
        if let connection = videoOutput?.connection(with: .video) {
            connection.isVideoMirrored = (currentCameraPosition == .front)
            connection.videoRotationAngle = 90 // portrait orientation
        }

        captureSession.commitConfiguration()

        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }

    // MARK: - Camera Control

    func switchCamera() {
        currentCameraPosition = (currentCameraPosition == .front) ? .back : .front
        startCamera()
    }

    func getCurrentCameraPosition() -> AVCaptureDevice.Position {
        return currentCameraPosition
    }

    func enableAnalysis() {
        isAnalysisEnabled = true
        videoOutput?.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
    }

    func disableAnalysis() {
        isAnalysisEnabled = false
        videoOutput?.setSampleBufferDelegate(nil, queue: nil)
    }

    func pauseAnalysis() {
        isAnalysisEnabled = false
        if isLoggingEnabled {
            print("[CameraManager] Pose analysis paused")
        }
    }

    func resumeAnalysis() {
        isAnalysisEnabled = true
        if isLoggingEnabled {
            print("[CameraManager] Pose analysis resumed")
        }
    }

    func releaseCamera() {
        disableAnalysis()
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    func dispose() {
        releaseCamera()
        poseLandmarkerHelper.clearPoseLandmarker()
    }

    // MARK: - Preview Layer

    /// Returns the AVCaptureVideoPreviewLayer for embedding in a platform view.
    func makePreviewLayer(for view: UIView) -> AVCaptureVideoPreviewLayer {
        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        videoPreviewLayer = layer
        return layer
    }

    // MARK: - PoseLandmarkerHelperDelegate

    func poseLandmarkerHelper(
        _ helper: PoseLandmarkerHelper,
        didFinishDetectionWithLandmarks landmarks: [[String: Any]],
        worldLandmarks: [[String: Any]],
        timestampMs: Int
    ) {
        let resultMap: [String: Any] = [
            "timestampMs": Int(Date().timeIntervalSince1970 * 1000),
            "landmarks": landmarks,
            "worldLandmarks": worldLandmarks,
            "fps": fps
        ]

        // Serialize to JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: resultMap),
              let json = String(data: jsonData, encoding: .utf8) else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.onResults?(json)
        }
    }

    func poseLandmarkerHelper(_ helper: PoseLandmarkerHelper, didFailWithError error: String) {
        DispatchQueue.main.async { [weak self] in
            self?.onError?(error, 0)
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard isAnalysisEnabled else { return }

        // FPS calculation
        let currentTime = CACurrentMediaTime()
        let deltaTime = currentTime - lastFrameTime
        if deltaTime > 0 {
            fps = 1.0 / deltaTime
        }
        lastFrameTime = currentTime

        // Feed to MediaPipe (zero-copy: MPImage wraps CMSampleBuffer directly)
        let timestampMs = Int(Date().timeIntervalSince1970 * 1000)
        poseLandmarkerHelper.detectAsync(sampleBuffer: sampleBuffer, timestampMs: timestampMs)
    }
}

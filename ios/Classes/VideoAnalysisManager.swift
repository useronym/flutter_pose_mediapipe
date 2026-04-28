import AVFoundation
import UIKit

/// Processes gallery videos with MediaPipe pose detection in real time.
///
/// Uses a serial queue and a loop gap larger than the analyzer window so the
/// Dart-side address analyzer naturally drops stale samples between repeats.
class VideoAnalysisManager: NSObject, PoseLandmarkerHelperDelegate {
    private static let loopGapMs = 1000

    private let processingQueue = DispatchQueue(
        label: "com.carecode.flutter_mp_pose_lm.videoAnalysis",
        qos: .userInitiated
    )

    private var poseLandmarkerHelper: PoseLandmarkerHelper?
    private var isCancelled = false
    private var intervalMs: Int = 33
    private var sourceFps: Double = 30.0

    var onResults: ((_ json: String) -> Void)?
    var onError: ((_ error: String, _ code: Int) -> Void)?

    func setConfig(
        delegate: Int,
        model: Int,
        minPoseDetectionConfidence: Float,
        minPoseTrackingConfidence: Float,
        minPosePresenceConfidence: Float
    ) {
        poseLandmarkerHelper?.clearPoseLandmarker()

        let helper = PoseLandmarkerHelper(
            minPoseDetectionConfidence: minPoseDetectionConfidence,
            minPoseTrackingConfidence: minPoseTrackingConfidence,
            minPosePresenceConfidence: minPosePresenceConfidence,
            currentModel: model,
            currentDelegate: delegate,
            runningMode: .video
        )
        helper.delegate = self
        helper.setupPoseLandmarker()
        poseLandmarkerHelper = helper
    }

    func startVideoAnalysis(filePath: String, intervalMs: Int, loop: Bool, startPositionMs: Int = 0) {
        self.intervalMs = max(1, intervalMs)
        sourceFps = 1000.0 / Double(self.intervalMs)
        isCancelled = false

        processingQueue.async { [weak self] in
            self?.runVideoAnalysis(filePath: filePath, loop: loop, startPositionMs: startPositionMs)
        }
    }

    func stopVideoAnalysis() {
        isCancelled = true
    }

    func dispose() {
        stopVideoAnalysis()
        poseLandmarkerHelper?.clearPoseLandmarker()
        poseLandmarkerHelper = nil
    }

    private func runVideoAnalysis(filePath: String, loop: Bool, startPositionMs: Int) {
        guard let helper = poseLandmarkerHelper else {
            emitError("Pose landmarker is not configured for video analysis")
            return
        }

        let asset = AVURLAsset(url: URL(fileURLWithPath: filePath))
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        let durationMs = Int((asset.duration.seconds * 1000.0).rounded())
        guard durationMs > 0 else {
            emitError("Selected video has no readable duration")
            return
        }

        let frameCount = max(0, durationMs / intervalMs)
        let runStart = CACurrentMediaTime()
        let clampedStartPositionMs = max(0, startPositionMs)
        var loopIndex = 0

        repeat {
            for frameIndex in 0...frameCount {
                if isCancelled {
                    return
                }

                let sourceTimestampMs = frameIndex * intervalMs
                let emittedTimestampMs = loopIndex * (durationMs + Self.loopGapMs) + sourceTimestampMs
                let targetWallTime = runStart + Double(emittedTimestampMs) / 1000.0
                paceUntil(targetWallTime)

                if isCancelled {
                    return
                }

                let requestedSourceTimestampMs = (clampedStartPositionMs + sourceTimestampMs) % durationMs
                let requestedTime = CMTime(value: CMTimeValue(requestedSourceTimestampMs), timescale: 1000)

                do {
                    let cgImage = try generator.copyCGImage(at: requestedTime, actualTime: nil)
                    let image = UIImage(cgImage: cgImage)
                    helper.detectVideoFrame(image: image, timestampMs: emittedTimestampMs)
                } catch {
                    emitError("Failed to decode video frame: \(error.localizedDescription)")
                }
            }

            loopIndex += 1
        } while loop && !isCancelled
    }

    private func paceUntil(_ targetWallTime: CFTimeInterval) {
        while !isCancelled {
            let remaining = targetWallTime - CACurrentMediaTime()
            if remaining <= 0 {
                return
            }
            Thread.sleep(forTimeInterval: min(remaining, 0.02))
        }
    }

    private func emitError(_ message: String, code: Int = 0) {
        DispatchQueue.main.async { [weak self] in
            self?.onError?(message, code)
        }
    }

    func poseLandmarkerHelper(
        _ helper: PoseLandmarkerHelper,
        didFinishDetectionWithLandmarks landmarks: [[String: Any]],
        worldLandmarks: [[String: Any]],
        timestampMs: Int
    ) {
        let resultMap: [String: Any] = [
            "timestampMs": timestampMs,
            "landmarks": landmarks,
            "worldLandmarks": worldLandmarks,
            "fps": sourceFps
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: resultMap),
              let json = String(data: jsonData, encoding: .utf8) else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.onResults?(json)
        }
    }

    func poseLandmarkerHelper(_ helper: PoseLandmarkerHelper, didFailWithError error: String) {
        emitError(error)
    }
}
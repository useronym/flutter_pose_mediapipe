import 'dart:async';

import '../flutter_mp_pose_landmarker.dart';
import 'stub_t_pose.dart';

/// Dart-only stub that emits a static T-pose at ~30 fps.
/// Used on platforms where native MediaPipe + camera are unavailable
/// (Windows, Linux, macOS).
class StubPoseLandmarker {
  static StreamController<PoseLandMarker>? _controller;
  static Timer? _timer;
  static bool _paused = false;

  static const Duration _frameInterval = Duration(milliseconds: 33); // ~30fps
  static const double _fps = 30.0;

  // ── No-op configuration methods ──────────────────────────────────

  static Future<void> setConfig({
    required int delegate,
    required int model,
    double minPoseDetectionConfidence = 0.5,
    double minPoseTrackingConfidence = 0.5,
    double minPosePresenceConfidence = 0.5,
  }) async {}

  static Future<void> switchCamera() async {}

  static Future<String> getCurrentCamera() async => 'front';

  static Future<void> setLoggingEnabled(bool enabled) async {}

  static Future<void> setTargetFps({required int min, required int max}) async {
  }

  static Future<void> clearTargetFps() async {}

  // ── Stub queries ─────────────────────────────────────────────────

  static Future<bool> requestCameraPermission() async => true;

  static Future<bool> checkCameraPermission() async => true;

  static Future<bool> isPreviewMirrored() async => false;

  static Future<bool> isEmulator() async => false;

  static Future<List<Map<String, int>>> getSupportedFpsRanges() async {
    return [
      {'min': 30, 'max': 30},
    ];
  }

  // ── Pause / resume ──────────────────────────────────────────────

  static Future<void> pauseDetection() async {
    _paused = true;
  }

  static Future<void> resumeDetection() async {
    _paused = false;
  }

  // ── Pose stream (lazy start / stop) ─────────────────────────────

  static Stream<PoseLandMarker> get poseLandmarkStream {
    _controller ??= StreamController<PoseLandMarker>.broadcast(
      onListen: _startTimer,
      onCancel: _stopTimer,
    );
    return _controller!.stream;
  }

  static void _startTimer() {
    _paused = false;
    _timer?.cancel();
    _timer = Timer.periodic(_frameInterval, (_) {
      if (_paused || (_controller?.isClosed ?? true)) return;
      final now = DateTime.now().millisecondsSinceEpoch;
      _controller!.add(createTPoseFrame(now, _fps));
    });
  }

  static void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    // Don't close the controller — allow re-listen.
  }
}

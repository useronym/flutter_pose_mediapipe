import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

/// Model for a single landmark point
class PoseLandmarkPoint {
  final double x;
  final double y;
  final double z;
  final double visibility;

  PoseLandmarkPoint({
    required this.x,
    required this.y,
    required this.z,
    required this.visibility,
  });

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'z': z,
      'visibility': visibility,
    };
  }

  factory PoseLandmarkPoint.fromJson(Map<String, dynamic> json) {
    return PoseLandmarkPoint(
      x: json['x'].toDouble(),
      y: json['y'].toDouble(),
      z: json['z'].toDouble(),
      visibility: json['visibility'].toDouble(),
    );
  }
}

/// Model for a detected pose with landmarks and optional FPS
class PoseLandMarker {
  final int timestampMs;
  final List<PoseLandmarkPoint> landmarks;
  final double? fps; // <- إضافة fps

  PoseLandMarker({
    required this.timestampMs,
    required this.landmarks,
    this.fps,
  });

  factory PoseLandMarker.fromJson(Map<String, dynamic> json) {
    var landmarkList = json['landmarks'] as List;
    List<PoseLandmarkPoint> landmarks = landmarkList
        .map((pointJson) => PoseLandmarkPoint.fromJson(pointJson))
        .toList();

    return PoseLandMarker(
      timestampMs: json['timestampMs'],
      landmarks: landmarks,
      fps: json['fps']?.toDouble(),
    );
  }
}

class PoseLandmarker {
  static const EventChannel _eventChannel =
      EventChannel('pose_landmarker/events');
  static const MethodChannel _channel =
      MethodChannel("pose_landmarker/methods");

  static Stream<PoseLandMarker>? _poseStream;

  /// Sets configuration including delegate, model, and confidence thresholds
  static Future<void> setConfig({
    required int delegate, // 0 = CPU, 1 = GPU
    required int model, // 0 = full, 1 = lite, 2 = heavy
    double minPoseDetectionConfidence = 0.5,
    double minPoseTrackingConfidence = 0.5,
    double minPosePresenceConfidence = 0.5,
  }) async {
    await _channel.invokeMethod("setConfig", {
      "delegate": delegate,
      "model": model,
      "minPoseDetectionConfidence": minPoseDetectionConfidence,
      "minPoseTrackingConfidence": minPoseTrackingConfidence,
      "minPosePresenceConfidence": minPosePresenceConfidence,
    });
  }

  /// Switch between front/back camera
  static Future<void> switchCamera() async {
    await _channel.invokeMethod('switchCamera');
  }

  /// Get current camera ("front" or "back")
  static Future<String> getCurrentCamera() async {
    final camera = await _channel.invokeMethod<String>('getCurrentCamera');
    return camera ?? "back"; // fallback
  }

  /// Enable or disable logging on native side
  static Future<void> setLoggingEnabled(bool enabled) async {
    await _channel.invokeMethod('setLoggingEnabled', {"enabled": enabled});
  }

  /// Pause pose detection without stopping the camera
  static Future<void> pauseDetection() async {
    await _channel.invokeMethod('pauseAnalysis');
  }

  /// Resume pose detection while keeping the camera live
  static Future<void> resumeDetection() async {
    await _channel.invokeMethod('resumeAnalysis');
  }

  /// Provides a broadcast stream of PoseLandMarker results
  static Stream<PoseLandMarker> get poseLandmarkStream {
    _poseStream ??= _eventChannel.receiveBroadcastStream().map((event) {
      try {
        final Map<String, dynamic> jsonMap = jsonDecode(event);
        return PoseLandMarker.fromJson(jsonMap);
      } catch (e) {
        print('PoseLandmarker: Error parsing event: $e');
        rethrow;
      }
    });
    return _poseStream!;
  }
}

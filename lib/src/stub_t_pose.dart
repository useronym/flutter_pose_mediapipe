import '../flutter_mp_pose_landmarker.dart';

/// MediaPipe BlazePose 33-point landmark indices:
///  0: nose,  1: left eye inner,  2: left eye,  3: left eye outer,
///  4: right eye inner,  5: right eye,  6: right eye outer,
///  7: left ear,  8: right ear,  9: mouth left, 10: mouth right,
/// 11: left shoulder, 12: right shoulder, 13: left elbow, 14: right elbow,
/// 15: left wrist, 16: right wrist, 17: left pinky, 18: right pinky,
/// 19: left index, 20: right index, 21: left thumb, 22: right thumb,
/// 23: left hip, 24: right hip, 25: left knee, 26: right knee,
/// 27: left ankle, 28: right ankle, 29: left heel, 30: right heel,
/// 31: left foot index, 32: right foot index

/// Normalized 2D landmarks for a T-pose centered in image space ([0,1]).
const List<List<double>> _tPoseNormalized = [
  // 0: nose
  [0.500, 0.12, 0.0],
  // 1: left eye inner
  [0.485, 0.10, 0.0],
  // 2: left eye
  [0.475, 0.10, 0.0],
  // 3: left eye outer
  [0.465, 0.10, 0.0],
  // 4: right eye inner
  [0.515, 0.10, 0.0],
  // 5: right eye
  [0.525, 0.10, 0.0],
  // 6: right eye outer
  [0.535, 0.10, 0.0],
  // 7: left ear
  [0.450, 0.11, 0.0],
  // 8: right ear
  [0.550, 0.11, 0.0],
  // 9: mouth left
  [0.490, 0.14, 0.0],
  // 10: mouth right
  [0.510, 0.14, 0.0],
  // 11: left shoulder
  [0.350, 0.25, 0.0],
  // 12: right shoulder
  [0.650, 0.25, 0.0],
  // 13: left elbow
  [0.200, 0.25, 0.0],
  // 14: right elbow
  [0.800, 0.25, 0.0],
  // 15: left wrist
  [0.070, 0.25, 0.0],
  // 16: right wrist
  [0.930, 0.25, 0.0],
  // 17: left pinky
  [0.050, 0.26, 0.0],
  // 18: right pinky
  [0.950, 0.26, 0.0],
  // 19: left index
  [0.045, 0.25, 0.0],
  // 20: right index
  [0.955, 0.25, 0.0],
  // 21: left thumb
  [0.055, 0.24, 0.0],
  // 22: right thumb
  [0.945, 0.24, 0.0],
  // 23: left hip
  [0.420, 0.52, 0.0],
  // 24: right hip
  [0.580, 0.52, 0.0],
  // 25: left knee
  [0.420, 0.70, 0.0],
  // 26: right knee
  [0.580, 0.70, 0.0],
  // 27: left ankle
  [0.420, 0.88, 0.0],
  // 28: right ankle
  [0.580, 0.88, 0.0],
  // 29: left heel
  [0.425, 0.90, 0.0],
  // 30: right heel
  [0.575, 0.90, 0.0],
  // 31: left foot index
  [0.410, 0.90, 0.0],
  // 32: right foot index
  [0.590, 0.90, 0.0],
];

/// World landmarks for a T-pose in meters, hip-centered (origin at hip midpoint).
const List<List<double>> _tPoseWorld = [
  // 0: nose
  [0.000, -0.55, -0.05],
  // 1: left eye inner
  [-0.02, -0.58, -0.06],
  // 2: left eye
  [-0.03, -0.58, -0.06],
  // 3: left eye outer
  [-0.04, -0.58, -0.06],
  // 4: right eye inner
  [0.02, -0.58, -0.06],
  // 5: right eye
  [0.03, -0.58, -0.06],
  // 6: right eye outer
  [0.04, -0.58, -0.06],
  // 7: left ear
  [-0.06, -0.57, -0.02],
  // 8: right ear
  [0.06, -0.57, -0.02],
  // 9: mouth left
  [-0.01, -0.52, -0.06],
  // 10: mouth right
  [0.01, -0.52, -0.06],
  // 11: left shoulder
  [-0.18, -0.40, 0.0],
  // 12: right shoulder
  [0.18, -0.40, 0.0],
  // 13: left elbow
  [-0.45, -0.40, 0.0],
  // 14: right elbow
  [0.45, -0.40, 0.0],
  // 15: left wrist
  [-0.70, -0.40, 0.0],
  // 16: right wrist
  [0.70, -0.40, 0.0],
  // 17: left pinky
  [-0.74, -0.39, 0.0],
  // 18: right pinky
  [0.74, -0.39, 0.0],
  // 19: left index
  [-0.75, -0.40, 0.0],
  // 20: right index
  [0.75, -0.40, 0.0],
  // 21: left thumb
  [-0.73, -0.41, 0.0],
  // 22: right thumb
  [0.73, -0.41, 0.0],
  // 23: left hip
  [-0.10, 0.00, 0.0],
  // 24: right hip
  [0.10, 0.00, 0.0],
  // 25: left knee
  [-0.10, 0.40, 0.0],
  // 26: right knee
  [0.10, 0.40, 0.0],
  // 27: left ankle
  [-0.10, 0.80, 0.0],
  // 28: right ankle
  [0.10, 0.80, 0.0],
  // 29: left heel
  [-0.10, 0.82, 0.02],
  // 30: right heel
  [0.10, 0.82, 0.02],
  // 31: left foot index
  [-0.10, 0.80, -0.05],
  // 32: right foot index
  [0.10, 0.80, -0.05],
];

final List<PoseLandmarkPoint> tPoseLandmarks = _tPoseNormalized
    .map((p) => PoseLandmarkPoint(
          x: p[0],
          y: p[1],
          z: p[2],
          visibility: 1.0,
          presence: 1.0,
        ))
    .toList(growable: false);

final List<WorldLandmarkPoint> tPoseWorldLandmarks = _tPoseWorld
    .map((p) => WorldLandmarkPoint(
          x: p[0],
          y: p[1],
          z: p[2],
          visibility: 1.0,
          presence: 1.0,
        ))
    .toList(growable: false);

PoseLandMarker createTPoseFrame(int timestampMs, double fps) {
  return PoseLandMarker(
    timestampMs: timestampMs,
    landmarks: tPoseLandmarks,
    worldLandmarks: tPoseWorldLandmarks,
    fps: fps,
  );
}

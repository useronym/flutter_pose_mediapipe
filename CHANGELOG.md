## [0.1.2] - 2025-11-28

### Added
- Camera permission check before starting detection.
- Configurable confidence thresholds:
  - `minPoseDetectionConfidence`
  - `minPoseTrackingConfidence`
  - `minPosePresenceConfidence`
  These can now be set dynamically using `PoseLandmarker.setConfig()`.
- Camera controls:
  - Start / Stop / Pause / Resume detection.
- Logging toggle for enabling/disabling plugin logs.
- FPS counter for performance monitoring.

### Changed
- `minPoseDetectionConfidence`, `minPoseTrackingConfidence`, and `minPosePresenceConfidence` are now runtime-changeable via `setConfig`.

### Added Tests
- Added platform interface tests covering:
- Added Integration Tests 


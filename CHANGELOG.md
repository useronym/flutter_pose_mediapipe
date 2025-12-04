# Changelog

## [0.1.3] - 2025-12-04
### Fixed
- Removed leftover `print()` debug statements.
- Updated license information and added LICENSE file.

---

## [0.1.2] - 2025-11-28
### Added
- Camera permission check before starting detection.
- Configurable confidence thresholds:
  - `minPoseDetectionConfidence`
  - `minPoseTrackingConfidence`
  - `minPosePresenceConfidence`
- Runtime configuration via `PoseLandmarker.setConfig()`.
- Camera controls:
  - Start / Stop / Pause / Resume detection.
- Logging toggle to enable/disable plugin logs.
- FPS counter for performance monitoring.
- Platform interface tests.
- Integration tests.

### Changed
- All confidence thresholds can now be updated dynamically at runtime via `setConfig()`.

---

## [0.1.1] - 2025-11-21
### Added
- Camera lens swapping (front ↔ back).
- PoseLandmarker configuration:
  - Model type (lite, full, heavy).
  - Delegate (CPU or GPU).

### Fixed
- Detection stopping after camera swap.

---

## [0.0.1] - 2025-07-26
### Added
- Initial pose detection functionality using MediaPipe.
- Android implementation with CameraX.
- Base configuration system for PoseLandmarker.
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_mp_pose_landmarker/flutter_mp_pose_landmarker.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('PoseLandmarker Integration Tests', () {
    testWidgets('setConfig with different delegates', (tester) async {
      await PoseLandmarker.setConfig(
        delegate: 0, // CPU
        model: 1, // Lite
        minPoseDetectionConfidence: 0.6,
      );
      await tester.pumpAndSettle();

      await PoseLandmarker.setConfig(
        delegate: 1, // GPU
        model: 0, // Full
      );
      await tester.pumpAndSettle();
    });

    testWidgets('camera operations work correctly', (tester) async {
      final initialCamera = await PoseLandmarker.getCurrentCamera();
      expect(initialCamera, isIn(['front', 'back']));

      await PoseLandmarker.switchCamera();
      await tester.pumpAndSettle();

      final newCamera = await PoseLandmarker.getCurrentCamera();
      expect(newCamera, isNot(equals(initialCamera)));
    });

    testWidgets('pause and resume detection', (tester) async {
      await PoseLandmarker.pauseDetection();
      await tester.pumpAndSettle();

      await PoseLandmarker.resumeDetection();
      await tester.pumpAndSettle();
    });

    testWidgets('logging can be toggled', (tester) async {
      await PoseLandmarker.setLoggingEnabled(true);
      await tester.pumpAndSettle();

      await PoseLandmarker.setLoggingEnabled(false);
      await tester.pumpAndSettle();
    });

    testWidgets('pose stream emits data', (tester) async {
      final completer = Completer<PoseLandMarker>();
      final subscription = PoseLandmarker.poseLandmarkStream.listen((pose) {
        if (!completer.isCompleted) {
          completer.complete(pose);
        }
      });

      final pose = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('No pose data received'),
      );

      expect(pose.timestampMs, greaterThan(0));
      expect(pose.landmarks, isNotEmpty);

      await subscription.cancel();
    });

    testWidgets('pose data contains valid landmarks', (tester) async {
      final completer = Completer<PoseLandMarker>();
      final subscription = PoseLandmarker.poseLandmarkStream.listen((pose) {
        if (!completer.isCompleted) {
          completer.complete(pose);
        }
      });

      final pose = await completer.future.timeout(
        const Duration(seconds: 10),
      );

      for (final landmark in pose.landmarks) {
        expect(landmark.x, inInclusiveRange(0.0, 1.0));
        expect(landmark.y, inInclusiveRange(0.0, 1.0));
        expect(landmark.visibility, inInclusiveRange(0.0, 1.0));
      }

      await subscription.cancel();
    });

    testWidgets('fps is included in pose data', (tester) async {
      final completer = Completer<PoseLandMarker>();
      final subscription = PoseLandmarker.poseLandmarkStream.listen((pose) {
        if (!completer.isCompleted && pose.fps != null) {
          completer.complete(pose);
        }
      });

      final pose = await completer.future.timeout(
        const Duration(seconds: 10),
      );

      expect(pose.fps, isNotNull);
      expect(pose.fps, greaterThan(0));

      await subscription.cancel();
    });
  });
}

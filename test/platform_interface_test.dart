import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mp_pose_landmarker/flutter_mp_pose_landmarker_platform_interface.dart';
import 'package:flutter_mp_pose_landmarker/flutter_mp_pose_landmarker_method_channel.dart';

class MockPlatform extends FlutterMpPoseLandmarkerPlatform {
  @override
  Future<String?> getPlatformVersion() async => 'Mock Version';

  @override
  Future<bool> checkCameraPermission() async => true;
}

class UnimplementedPlatform extends FlutterMpPoseLandmarkerPlatform {}

void main() {
  group('FlutterMpPoseLandmarkerPlatform', () {
    test('default instance is MethodChannelFlutterMpPoseLandmarker', () {
      expect(
        FlutterMpPoseLandmarkerPlatform.instance,
        isA<MethodChannelFlutterMpPoseLandmarker>(),
      );
    });

    test('can set custom platform instance', () {
      final mock = MockPlatform();
      FlutterMpPoseLandmarkerPlatform.instance = mock;
      expect(FlutterMpPoseLandmarkerPlatform.instance, mock);
    });

    test('throws UnimplementedError for getPlatformVersion by default', () {
      final platform = UnimplementedPlatform();
      expect(
        () => platform.getPlatformVersion(),
        throwsUnimplementedError,
      );
    });

    test('throws UnimplementedError for checkCameraPermission by default', () {
      final platform = UnimplementedPlatform();
      expect(
        () => platform.checkCameraPermission(),
        throwsUnimplementedError,
      );
    });
  });
}

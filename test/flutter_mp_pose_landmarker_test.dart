import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mp_pose_landmarker/flutter_mp_pose_landmarker_platform_interface.dart';
import 'package:flutter_mp_pose_landmarker/flutter_mp_pose_landmarker_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterMpPoseLandmarkerPlatform
    with MockPlatformInterfaceMixin
    implements FlutterMpPoseLandmarkerPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<bool> checkCameraPermission() => Future.value(true);
}

void main() {
  final FlutterMpPoseLandmarkerPlatform initialPlatform =
      FlutterMpPoseLandmarkerPlatform.instance;

  test('$MethodChannelFlutterMpPoseLandmarker is the default instance', () {
    expect(
        initialPlatform, isInstanceOf<MethodChannelFlutterMpPoseLandmarker>());
  });

  test('mock platform can be set as instance', () {
    MockFlutterMpPoseLandmarkerPlatform fakePlatform =
        MockFlutterMpPoseLandmarkerPlatform();
    FlutterMpPoseLandmarkerPlatform.instance = fakePlatform;

    expect(FlutterMpPoseLandmarkerPlatform.instance, fakePlatform);
  });
}

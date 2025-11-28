import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mp_pose_landmarker/flutter_mp_pose_landmarker_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelFlutterMpPoseLandmarker platform = MethodChannelFlutterMpPoseLandmarker();
  const MethodChannel channel = MethodChannel('flutter_mp_pose_landmarker');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'getPlatformVersion') {
          return '42';
        } else if (methodCall.method == 'checkCameraPermission') {
          return true;
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion returns correct value', () async {
    expect(await platform.getPlatformVersion(), '42');
  });

  test('checkCameraPermission returns true when granted', () async {
    expect(await platform.checkCameraPermission(), true);
  });

  test('checkCameraPermission returns false when null', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async => null,
    );
    expect(await platform.checkCameraPermission(), false);
  });
}

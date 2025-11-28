import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mp_pose_landmarker/flutter_mp_pose_landmarker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel methodChannel = MethodChannel('pose_landmarker/methods');
  const EventChannel eventChannel = EventChannel('pose_landmarker/events');

  group('PoseLandmarkPoint', () {
    test('fromJson creates correct instance', () {
      final json = {'x': 0.5, 'y': 0.3, 'z': 0.1, 'visibility': 0.9};
      final point = PoseLandmarkPoint.fromJson(json);

      expect(point.x, 0.5);
      expect(point.y, 0.3);
      expect(point.z, 0.1);
      expect(point.visibility, 0.9);
    });

    test('toJson returns correct map', () {
      final point = PoseLandmarkPoint(x: 0.5, y: 0.3, z: 0.1, visibility: 0.9);
      final json = point.toJson();

      expect(json['x'], 0.5);
      expect(json['y'], 0.3);
      expect(json['z'], 0.1);
      expect(json['visibility'], 0.9);
    });
  });

  group('PoseLandMarker', () {
    test('fromJson creates correct instance with fps', () {
      final json = {
        'timestampMs': 1234567890,
        'fps': 30.5,
        'landmarks': [
          {'x': 0.5, 'y': 0.3, 'z': 0.1, 'visibility': 0.9},
          {'x': 0.6, 'y': 0.4, 'z': 0.2, 'visibility': 0.8},
        ]
      };

      final marker = PoseLandMarker.fromJson(json);

      expect(marker.timestampMs, 1234567890);
      expect(marker.fps, 30.5);
      expect(marker.landmarks.length, 2);
      expect(marker.landmarks[0].x, 0.5);
      expect(marker.landmarks[1].x, 0.6);
    });

    test('fromJson creates correct instance without fps', () {
      final json = {
        'timestampMs': 1234567890,
        'landmarks': [
          {'x': 0.5, 'y': 0.3, 'z': 0.1, 'visibility': 0.9},
        ]
      };

      final marker = PoseLandMarker.fromJson(json);

      expect(marker.timestampMs, 1234567890);
      expect(marker.fps, null);
      expect(marker.landmarks.length, 1);
    });
  });

  group('PoseLandmarker', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
    });

    test('setConfig calls method channel with correct parameters', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (MethodCall call) async {
        calls.add(call);
        return null;
      });

      await PoseLandmarker.setConfig(
        delegate: 1,
        model: 0,
        minPoseDetectionConfidence: 0.6,
        minPoseTrackingConfidence: 0.7,
        minPosePresenceConfidence: 0.8,
      );

      expect(calls.length, 1);
      expect(calls[0].method, 'setConfig');
      expect(calls[0].arguments['delegate'], 1);
      expect(calls[0].arguments['model'], 0);
      expect(calls[0].arguments['minPoseDetectionConfidence'], 0.6);
      expect(calls[0].arguments['minPoseTrackingConfidence'], 0.7);
      expect(calls[0].arguments['minPosePresenceConfidence'], 0.8);
    });

    test('setConfig uses default confidence values', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (MethodCall call) async {
        calls.add(call);
        return null;
      });

      await PoseLandmarker.setConfig(delegate: 0, model: 1);

      expect(calls[0].arguments['minPoseDetectionConfidence'], 0.5);
      expect(calls[0].arguments['minPoseTrackingConfidence'], 0.5);
      expect(calls[0].arguments['minPosePresenceConfidence'], 0.5);
    });

    test('switchCamera calls method channel', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (MethodCall call) async {
        calls.add(call);
        return null;
      });

      await PoseLandmarker.switchCamera();

      expect(calls.length, 1);
      expect(calls[0].method, 'switchCamera');
    });

    test('getCurrentCamera returns camera string', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (MethodCall call) async {
        if (call.method == 'getCurrentCamera') {
          return 'front';
        }
        return null;
      });

      final camera = await PoseLandmarker.getCurrentCamera();
      expect(camera, 'front');
    });

    test('getCurrentCamera returns default on null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (MethodCall call) async {
        return null;
      });

      final camera = await PoseLandmarker.getCurrentCamera();
      expect(camera, 'back');
    });

    test('setLoggingEnabled calls method channel', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (MethodCall call) async {
        calls.add(call);
        return null;
      });

      await PoseLandmarker.setLoggingEnabled(true);

      expect(calls.length, 1);
      expect(calls[0].method, 'setLoggingEnabled');
      expect(calls[0].arguments['enabled'], true);
    });

    test('pauseDetection calls method channel', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (MethodCall call) async {
        calls.add(call);
        return null;
      });

      await PoseLandmarker.pauseDetection();

      expect(calls.length, 1);
      expect(calls[0].method, 'pauseAnalysis');
    });

    test('resumeDetection calls method channel', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (MethodCall call) async {
        calls.add(call);
        return null;
      });

      await PoseLandmarker.resumeDetection();

      expect(calls.length, 1);
      expect(calls[0].method, 'resumeAnalysis');
    });

    test('poseLandmarkStream parses events correctly', () async {
      final mockData = {
        'timestampMs': 1234567890,
        'fps': 29.5,
        'landmarks': [
          {'x': 0.5, 'y': 0.3, 'z': 0.1, 'visibility': 0.9},
        ]
      };

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        eventChannel,
        MockStreamHandler.inline(
          onListen: (args, events) {
            events.success(jsonEncode(mockData));
            events.endOfStream();
          },
        ),
      );

      final stream = PoseLandmarker.poseLandmarkStream;
      final result = await stream.first;

      expect(result.timestampMs, 1234567890);
      expect(result.fps, 29.5);
      expect(result.landmarks.length, 1);
      expect(result.landmarks[0].x, 0.5);
    });
  });
}

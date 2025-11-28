import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_mp_pose_landmarker/flutter_mp_pose_landmarker.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> ensureCameraPermission() async {
  var status = await Permission.camera.status;
  if (!status.isGranted) {
    await Permission.camera.request();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ensureCameraPermission();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pose Landmarker Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const PoseLandmarkerView(),
    );
  }
}

class PoseLandmarkerView extends StatefulWidget {
  const PoseLandmarkerView({super.key});
  @override
  State<PoseLandmarkerView> createState() => _PoseLandmarkerViewState();
}

class _PoseLandmarkerViewState extends State<PoseLandmarkerView> {
  int delegate = 0; // 0=CPU, 1=GPU
  int model = 1; // 0=Full, 1=Lite, 2=Heavy
  // Confidence parameters
  double _minPoseDetectionConfidence = 0.5;
  double _minPoseTrackingConfidence = 0.5;
  double _minPosePresenceConfidence = 0.5;

  List<PoseLandmarkPoint> _landmarks = [];
  late StreamSubscription<PoseLandMarker> _poseSubscription;

  bool _detectionPaused = false;
  bool _loggingEnabled = true;
  String _cameraLens = "Back";

  int _fps = 0;
  int _frameCount = 0;
  int _lastTimestamp = DateTime.now().millisecondsSinceEpoch;

  final _detectionController = TextEditingController();
  final _trackingController = TextEditingController();
  final _presenceController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _detectionController.text = _minPoseDetectionConfidence.toString();
    _trackingController.text = _minPoseTrackingConfidence.toString();
    _presenceController.text = _minPosePresenceConfidence.toString();

    PoseLandmarker.setConfig(
      delegate: delegate,
      model: model,
      minPoseDetectionConfidence: _minPoseDetectionConfidence,
      minPoseTrackingConfidence: _minPoseTrackingConfidence,
      minPosePresenceConfidence: _minPosePresenceConfidence,
    );

    _poseSubscription = PoseLandmarker.poseLandmarkStream.listen((pose) {
      if (!_detectionPaused) {
        setState(() {
          _landmarks = pose.landmarks;

          // FPS calculation
          _frameCount++;
          int now = DateTime.now().millisecondsSinceEpoch;
          if (now - _lastTimestamp >= 1000) {
            _fps = _frameCount;
            _frameCount = 0;
            _lastTimestamp = now;
            if (_loggingEnabled) print("FPS: $_fps");
          }
        });
      }
    });
  }

  void _switchCamera() {
    PoseLandmarker.switchCamera();
    setState(() {
      _cameraLens = _cameraLens == "Back" ? "Front" : "Back";
    });
    if (_loggingEnabled) print("Switched camera to $_cameraLens");
  }

  void _toggleLogging() {
    setState(() {
      _loggingEnabled = !_loggingEnabled;
    });
    print("Logging: $_loggingEnabled");
  }

  void _pauseResumeDetection() {
    setState(() {
      _detectionPaused = !_detectionPaused;
    });
    print(_detectionPaused ? "Detection Paused" : "Detection Resumed");
  }

  void _applyConfidenceSettings() {
    setState(() {
      _minPoseDetectionConfidence =
          double.tryParse(_detectionController.text) ?? 0.5;
      _minPoseTrackingConfidence =
          double.tryParse(_trackingController.text) ?? 0.5;
      _minPosePresenceConfidence =
          double.tryParse(_presenceController.text) ?? 0.5;

      PoseLandmarker.setConfig(
        delegate: delegate,
        model: model,
        minPoseDetectionConfidence: _minPoseDetectionConfidence,
        minPoseTrackingConfidence: _minPoseTrackingConfidence,
        minPosePresenceConfidence: _minPosePresenceConfidence,
      );

      if (_loggingEnabled) {
        print(
            "Updated confidence: detection=$_minPoseDetectionConfidence, tracking=$_minPoseTrackingConfidence, presence=$_minPosePresenceConfidence");
      }
    });
  }

  @override
  void dispose() {
    _poseSubscription.cancel();
    _detectionController.dispose();
    _trackingController.dispose();
    _presenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FloatingActionButton(
              heroTag: "switchCamera",
              child: const Icon(Icons.cameraswitch),
              onPressed: _switchCamera,
            ),
            FloatingActionButton(
              heroTag: "pauseResume",
              child: Icon(_detectionPaused ? Icons.play_arrow : Icons.pause),
              onPressed: _pauseResumeDetection,
            ),
            FloatingActionButton(
              heroTag: "loggingToggle",
              child: const Icon(Icons.bug_report),
              onPressed: _toggleLogging,
            ),
          ],
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const NativeCameraPreview(),
          Positioned(
            top: 16,
            right: 16,
            width: 150,
            height: 150,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                color: Colors.black.withOpacity(0.3),
              ),
              child: CustomPaint(
                painter: LandmarkPainter(_landmarks),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.black54,
                  child: Text(
                    'Landmarks: ${_landmarks.length}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.black54,
                  child: Text(
                    'Camera: $_cameraLens',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.black54,
                  child: Text(
                    'FPS: $_fps',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          // Confidence controls
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black45,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _detectionController,
                          decoration: const InputDecoration(
                            labelText: "Detection Confidence",
                            fillColor: Colors.white,
                            filled: true,
                          ),
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _trackingController,
                          decoration: const InputDecoration(
                            labelText: "Tracking Confidence",
                            fillColor: Colors.white,
                            filled: true,
                          ),
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _presenceController,
                          decoration: const InputDecoration(
                            labelText: "Presence Confidence",
                            fillColor: Colors.white,
                            filled: true,
                          ),
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _applyConfidenceSettings,
                    child: const Text("Apply"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NativeCameraPreview extends StatelessWidget {
  const NativeCameraPreview({super.key});
  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand(
      child: AndroidView(
        viewType: 'camera_preview_view',
        layoutDirection: TextDirection.ltr,
      ),
    );
  }
}

class LandmarkPainter extends CustomPainter {
  final List<PoseLandmarkPoint> landmarks;
  LandmarkPainter(this.landmarks);

  static const List<List<int>> connections = [
    [0, 1],
    [1, 2],
    [2, 3],
    [3, 7],
    [0, 4],
    [4, 5],
    [5, 6],
    [6, 8],
    [9, 10],
    [11, 12],
    [11, 13],
    [13, 15],
    [12, 14],
    [14, 16],
    [11, 23],
    [12, 24],
    [23, 24],
    [23, 25],
    [25, 27],
    [24, 26],
    [26, 28],
    [27, 31],
    [28, 32],
    [15, 17],
    [16, 18],
    [17, 19],
    [18, 20],
    [19, 21],
    [20, 22],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final pointPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2;

    for (var c in connections) {
      if (c[0] < landmarks.length && c[1] < landmarks.length) {
        final a = landmarks[c[0]];
        final b = landmarks[c[1]];
        canvas.drawLine(
          Offset(a.x * size.width, a.y * size.height),
          Offset(b.x * size.width, b.y * size.height),
          linePaint,
        );
      }
    }

    for (var lm in landmarks) {
      canvas.drawCircle(
        Offset(lm.x * size.width, lm.y * size.height),
        4,
        pointPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant LandmarkPainter old) =>
      old.landmarks != landmarks;
}

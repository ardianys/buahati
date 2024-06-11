import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:io';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CameraWidget(camera: camera),
    );
  }
}

class CameraWidget extends StatefulWidget {
  final CameraDescription camera;

  const CameraWidget({super.key, required this.camera});

  @override
  _CameraWidgetState createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _initializeControllerFuture = _controller!.initialize();
    _initializeControllerFuture!.then((_) {
      _startTakingPictures();
    });
  }

  void _startTakingPictures() {
    _timer = Timer.periodic(Duration(seconds: 15), (timer) async {
      await _takeAndUploadPicture();
    });
  }

  Future<void> _takeAndUploadPicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      final imagePath = File(image.path);

      // Set the file name as the current timestamp or any unique identifier
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();

      // Create a multipart request for the file upload
      var request = http.MultipartRequest(
          'POST', Uri.parse('https://absensi.rumah.vip/api/attendances'));

      // Attach the file to the request
      request.files.add(await http.MultipartFile.fromPath(
          'photo', imagePath.path,
          filename: '$fileName.jpg'));

      request.fields['token'] = 'aQgcMrG1WBW4YjFkBW';

      // Send the request
      var streamedResponse = await request.send();

      // Convert the StreamedResponse to a Response
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        print('File uploaded successfully');
        print('Server response: ${response.body}');
      } else {
        print('File upload failed with status: ${response.statusCode}');
        print('Server response: ${response.body}');
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dash Cam')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return const Center(
              // child: CameraPreview(_controller!),
              child: Text('Taking pictures in the background...'),
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }
}

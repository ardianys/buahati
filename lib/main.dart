import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:async';
import 'dart:io';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CameraWidget(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CameraWidget(),
          ],
        ),
      ),
    );
  }
}

class CameraWidget extends StatefulWidget {
  @override
  _CameraWidgetState createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  File? _image;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  // Step 3 & 4: Initialize CameraController and get available cameras
  void _initCamera() async {
    final cameras = await availableCameras();
    _controller = CameraController(cameras.first, ResolutionPreset.medium);
    _initializeControllerFuture = _controller!.initialize();
  }

  // Step 5: Implement a method to take a picture
  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      final imagePath = File(image.path);

      // Set the file name as the current timestamp or any unique identifier
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();

      // Create a reference to the Firebase Storage bucket
      FirebaseStorage storage = FirebaseStorage.instance;
      Reference ref = storage.ref().child('uploads/$fileName.jpg');

      // Upload the file
      UploadTask uploadTask = ref.putFile(imagePath);

      // Optional: if you want to get the download URL after uploading
      uploadTask.whenComplete(() async {
        final downloadUrl = await ref.getDownloadURL();
        print('File uploaded. Download URL: $downloadUrl');

        // Update your state or UI with the download URL
        setState(() {
          _image = imagePath;
          // You can also store the downloadUrl in your state
        });
      }).catchError((onError) {
        print(onError);
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Absen Buah Hati')),
      // Step 6: Update UI
      body: Column(
        children: <Widget>[
          Expanded(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Center(
                    // Center the container
                    child: Container(
                      width: MediaQuery.of(context).size.width *
                          0.4, // 50% of screen width
                      height: MediaQuery.of(context).size.height *
                          0.4, // 50% of screen height
                      child:
                          CameraPreview(_controller!), // CameraPreview widget
                    ),
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          _image == null
              ? Text('No image selected.')
              : Container(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: Image.file(_image!, fit: BoxFit.cover),
                ),
          FloatingActionButton(
            onPressed: _takePicture,
            tooltip: 'Take Picture',
            child: Icon(Icons.camera),
          ),
        ],
      ),
    );
  }

  // Step 7: Dispose the controller
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

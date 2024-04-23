import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pytorch/flutter_pytorch.dart';
import 'package:flutter_pytorch/pigeon.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YOLO model',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'YOLO MODEL'),
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
  String? _imagePrediction;
  late ModelObjectDetection _objectModel;
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool objectDetection = false;
  List<ResultObjectDetection?> objDetect = [];

  @override
  void initState() {
    loadModel();
    super.initState();
  }

  Future loadModel() async {
    String pathObjectDetectionModel = "assets/models/yolov5s.torchscript";
    try {
      _objectModel = await FlutterPytorch.loadObjectDetectionModel(
          pathObjectDetectionModel, 80, 640, 640,
          labelPath: "assets/labels/labels.txt");
    } catch (e) {
      if (e is PlatformException) {
        print("only supported for android, Error is $e");
      } else {
        print("Error is $e");
      }
    }
  }

  Future runObjectDetection(ImageSource gallery) async {
    //pick an image

    final XFile? image = await _picker.pickImage(source: gallery);
    objDetect = await _objectModel.getImagePrediction(
        await File(image!.path).readAsBytes(),
        minimumScore: 0.1,
        IOUThershold: 0.3);
    setState(() {
      _image = File(image.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
                child: Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                height: double.infinity,
                width: double.infinity,
                child: objDetect.isNotEmpty
                    ? _image == null
                        ? const Text('No image selected')
                        : _objectModel.renderBoxesOnImage(_image!, objDetect)
                    : _image == null
                        ? const Text('No image selected')
                        : Image.file(_image!),
              ),
            )),
            Center(
              child: Visibility(
                visible: _imagePrediction != null,
                child: Text("$_imagePrediction"),
              ),
            ),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    runObjectDetection(ImageSource.gallery);
                  },
                  child: const Icon(Icons.folder),
                ),
                const SizedBox(
                  width: 40,
                ),
                ElevatedButton(
                  onPressed: () {
                    runObjectDetection(ImageSource.camera);
                  },
                  child: const Icon(Icons.camera),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

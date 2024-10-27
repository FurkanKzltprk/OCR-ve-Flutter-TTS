import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_ml_vision/google_ml_vision.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(BrailleConverterApp());
}

class BrailleConverterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FURKAN OCR DENEME',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: OCRScreen(),
    );
  }
}

class OCRScreen extends StatefulWidget {
  @override
  _OCRScreenState createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  late CameraController _controller;
  bool _isCameraInitialized = false;
  String _recognizedText = '';
  final FlutterTts flutterTts = FlutterTts();
  bool _isCameraVisible = false;

  @override
  void initState() {
    super.initState();
  }

  void initializeCamera() async {
    _controller = CameraController(
      cameras[0],
      ResolutionPreset.high,
    );

    await _controller.initialize();
    setState(() {
      _isCameraInitialized = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    flutterTts.stop();
    super.dispose();
  }

  Future<void> captureAndProcessImage() async {
    if (!_controller.value.isInitialized) return;

    // Fotoğrafı çek
    XFile file = await _controller.takePicture();
    File imageFile = File(file.path);

    // OCR işlemi
    await performOCR(imageFile);
  }

  Future<void> performOCR(File imageFile) async {
    final GoogleVisionImage visionImage = GoogleVisionImage.fromFile(imageFile);
    final TextRecognizer textRecognizer = GoogleVision.instance.textRecognizer();
    final VisionText visionText = await textRecognizer.processImage(visionImage);

    setState(() {
      _recognizedText = visionText.text ?? ''; // Null kontrolü eklendi
    });
  }

  Future<void> speakText() async {
    if (_recognizedText.isNotEmpty) {
      await flutterTts.setLanguage("en-US"); // Dili ayarlayın (İngilizce örneği)
      await flutterTts.setVoice({"name": "en-us-x-sfg#male"});
      await flutterTts.speak(_recognizedText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FURKAN OCR DENEME'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          // Kamera önizlemesi
          Expanded(
            child: _isCameraInitialized && _isCameraVisible
                ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: CameraPreview(_controller),
            )
                : Center(
              child: Text(
                'Kamerayı açmak için butona tıklayın.',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          SizedBox(height: 20),

          // Fotoğraf çek ve OCR işlemi başlat
          ElevatedButton(
            onPressed: () {
              if (!_isCameraVisible) {
                initializeCamera(); // Butona tıklayınca kamerayı aç
                setState(() {
                  _isCameraVisible = true; // Kamera görünürlüğünü aç
                });
              } else {
                captureAndProcessImage(); // Kamera açıksa fotoğraf çek
              }
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: Colors.orange,
            ),
            child: Text(_isCameraVisible ? 'Fotoğraf Çek' : 'Kamerayı Aç'),
          ),

          // OCR sonucu
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: TextEditingController(text: _recognizedText),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
                labelText: 'Metin',
                labelStyle: TextStyle(color: Colors.blueAccent),
                hintText: 'Tanınan metin burada görünecek',
                hintStyle: TextStyle(color: Colors.grey),
                contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
              ),
              maxLines: null,
              readOnly: true,
            ),
          ),

          // Metni sese dönüştür
          ElevatedButton(
            onPressed: speakText,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: Colors.orange,
            ),
            child: Text('Sese Dönüştür'),
          ),
        ],
      ),
    );
  }
}

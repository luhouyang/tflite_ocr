import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;

import 'package:ocr/static_data.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'dart:math' as math;

class DrawingPad extends StatefulWidget {
  const DrawingPad({super.key});

  @override
  State<DrawingPad> createState() => _DrawingPadState();
}

class _DrawingPadState extends State<DrawingPad> {
  List<Offset> points = []; // List to store touch points

  final GlobalKey _repaintKey = GlobalKey();

  Future<String> predict(input) async {
    final interpreter =
        await tfl.Interpreter.fromAsset('assets/ocr_model_q.tflite');

    // List<List<List<List<double>>>> input = StaticData().input;
    List<String> classes = StaticData().classes;

    var output = List.filled(47, 0).reshape([1, 47]);

    interpreter.run(input, output);

    int maxIndex = 0;
    double maxValue = output[0][0];

    for (int i = 1; i < output[0].length; i++) {
      maxValue =
          math.max(maxValue, output[0][i]); // Use math.max for comparison
    }

    maxIndex = output[0].indexOf(maxValue);

    debugPrint(classes[maxIndex]);
    return classes[maxIndex];
  }

  // Convert the image to Uint8List
  Uint8List imageBytes =
      Uint8List.fromList(img.encodePng(img.Image(width: 28, height: 28)));
  String predTxt = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.memory(
          imageBytes,
          scale: 0.1,
        ),
        Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.black)),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8.0),
                        topRight: Radius.circular(8.0))),
                height: MediaQuery.of(context).size.height * 0.4,
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.4,
                        width: MediaQuery.of(context).size.width,
                        child: RepaintBoundary(
                          key: _repaintKey,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              // check if in boundries
                              if ((details.localPosition.dx <=
                                          MediaQuery.of(context).size.width &&
                                      details.localPosition.dx >= 0) &&
                                  (details.localPosition.dy <=
                                          MediaQuery.of(context).size.height *
                                              0.4 &&
                                      details.localPosition.dy >= 0)) {
                                setState(
                                    () => points.add(details.localPosition));
                              }
                            },
                            child: CustomPaint(
                              painter: DrawingPainter(points),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (points.isEmpty)
                      const Center(
                        child: Text('Draw Here'),
                      )
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8.0),
                        bottomRight: Radius.circular(8.0))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      style: const ButtonStyle(
                          backgroundColor: MaterialStatePropertyAll(
                              ui.Color.fromARGB(255, 64, 83, 231))),
                      onPressed: () async {
                        img.Image processedImage =
                            await _captureAndPreprocessImage();
                        List<List<List<List<double>>>> imageArray =
                            _convertToNormalizedArray(processedImage);

                        imageBytes =
                            Uint8List.fromList(img.encodePng(processedImage));

                        predTxt = await predict(imageArray);
                        // You can now use `processedImage` as needed.
                        setState(() => points.clear());
                      },
                      child: const Text(
                        'Predict & Clear',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      "Prediction: $predTxt",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<img.Image> _captureAndPreprocessImage() async {
    // Capture the drawing as an image
    RenderRepaintBoundary boundary =
        _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();

    // Load the image with the image package
    img.Image capturedImage = img.decodeImage(pngBytes)!;

    // Invert colors
    img.invert(capturedImage);

    // Apply Gaussian blur with sigma = 1
    capturedImage = img.gaussianBlur(capturedImage, radius: 1);

    // Convert to grayscale
    capturedImage = img.grayscale(capturedImage);

    // Extract the region around the character (bounding box)
    img.Image boundingBoxImage = _extractBoundingBox(capturedImage);

    // Center the character in a square image
    img.Image squareImage = _centerImage(boundingBoxImage);

    // Add a 2-pixel border
    img.Image paddedImage = img.copyResize(squareImage,
        width: squareImage.width + 4, height: squareImage.height + 4);

    // Resize to 28x28
    img.Image resizedImage = img.copyResize(paddedImage,
        width: 28, height: 28, interpolation: img.Interpolation.cubic);

    // Normalize to [0, 1]
    img.Image finalImage =
        img.adjustColor(resizedImage, contrast: 1.0, brightness: 1.0);

    // Convert the final image to a byte array
    return finalImage;
  }

  List<List<List<List<double>>>> _convertToNormalizedArray(img.Image image) {
    List<List<List<List<double>>>> normalizedArray = List.generate(
      1,
      (_) => List.generate(
        28,
        (_) => List.generate(
          28,
          (_) => List.filled(1, 0.0),
        ),
      ),
    );

    for (int y = 0; y < 28; y++) {
      for (int x = 0; x < 28; x++) {
        img.Pixel pixel = image.getPixel(x, y);
        double gray = img.getLuminance(pixel) as double;
        normalizedArray[0][y][x][0] = gray;
      }
    }

    return normalizedArray;
  }

  img.Image _extractBoundingBox(img.Image image) {
    List<int>? trimRect;

    trimRect ??= img.findTrim(image, mode: img.TrimMode.transparent);
    final trimmed = img.copyCrop(image,
        x: trimRect[0],
        y: trimRect[1],
        width: trimRect[2],
        height: trimRect[3]);

    return trimmed;
  }

  img.Image _centerImage(img.Image image) {
    int size = image.width > image.height ? image.width : image.height;
    img.Image squareImage = img.Image(width: size, height: size);
    img.fill(squareImage, color: img.ColorFloat32.rgb(0, 0, 0));

    int offsetX = (size - image.width) ~/ 2;
    int offsetY = (size - image.height) ~/ 2;

    img.compositeImage(squareImage, image, dstX: offsetX, dstY: offsetY);
    return img.grayscale(squareImage);
  }
}

class DrawingPainter extends CustomPainter {
  final List<Offset> points;

  DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 15.0;
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

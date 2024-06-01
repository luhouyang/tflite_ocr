// import 'package:flutter/material.dart';

// class DrawingPad extends StatefulWidget {
//   const DrawingPad({super.key});

//   @override
//   State<DrawingPad> createState() => _DrawingPadState();
// }

// class _DrawingPadState extends State<DrawingPad> {
//   List<Offset> points = []; // List to store touch points

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Container(
//           decoration: BoxDecoration(
//                       border: Border.all(color: Colors.black),
//                       borderRadius: BorderRadius.circular(8)),
//           height: 300,
//           width: 350,
//           child: GestureDetector(
//             onPanUpdate: (details) =>
//                 setState(() => points.add(details.localPosition)),
//             child: CustomPaint(
//               painter: DrawingPainter(points),
//             ),
//           ),
//         ),
//         ElevatedButton(
//           onPressed: () => setState(() => points.clear()),
//           child: const Text('Clear'),
//         ),
//       ],
//     );
//   }
// }

// class DrawingPainter extends CustomPainter {
//   final List<Offset> points;

//   DrawingPainter(this.points);

//   @override
//   void paint(Canvas canvas, Size size) {
//     Paint paint = Paint()
//       ..color = Colors.black
//       ..strokeWidth = 5.0;
//     for (int i = 0; i < points.length - 1; i++) {
//       canvas.drawLine(points[i], points[i + 1], paint);
//     }
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => true;
// }
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

  GlobalKey _repaintKey = GlobalKey();

  Future<String> predict(input) async {
    final interpreter =
        await tfl.Interpreter.fromAsset('assets/ocr_model.tflite');

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
  Uint8List imageBytes = Uint8List.fromList(img.encodePng(img.Image(width: 28, height: 28)));
  String predTxt = '';

  @override
  Widget build(BuildContext context) {
    // List<int> byteList = [];
    // List<List<List<List<double>>>> data = StaticData().input;

    // for (int i = 0; i < data.length; i++) {
    //   for (int j = 0; j < data[i].length; j++) {
    //     for (int k = 0; k < data[i][j].length; k++) {
    //       for (int l = 0; l < data[i][j][k].length; l++) {
    //         // Scale the double value to the range [0, 255]
    //         int byteValue = (data[i][j][k][l] * 255).round();
    //         byteList.add(byteValue);
    //       }
    //     }
    //   }
    // }

    // Uint8List imageBytes = Uint8List.fromList(byteList);

    return Column(
      children: [
        Image.memory(imageBytes, scale: 0.1,),
        RepaintBoundary(
          key: _repaintKey,
          child: Container(
            decoration: BoxDecoration(
                //border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(8)),
            height: 300,
            width: 350,
            child: GestureDetector(
              onPanUpdate: (details) =>
                  setState(() => points.add(details.localPosition)),
              child: CustomPaint(
                painter: DrawingPainter(points),
              ),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            img.Image processedImage = await _captureAndPreprocessImage();
            List<List<List<List<double>>>> imageArray =
                _convertToNormalizedArray(processedImage);
            debugPrint(imageArray.shape.toString());
            imageBytes = Uint8List.fromList(img.encodePng(processedImage));
            predTxt = await predict(imageArray);
            // You can now use `processedImage` as needed.
            setState(() => points.clear());
          },
          child: const Text('Predict Clear'),
        ),
        const SizedBox(
                  height: 5,
                ),
        Text("Prediction: $predTxt"),    
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

    if (trimRect == null) {
      trimRect = img.findTrim(image, mode: img.TrimMode.transparent);
    }
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

    img.compositeImage(squareImage, image, 
    dstX: offsetX, 
    dstY: offsetY
    );
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

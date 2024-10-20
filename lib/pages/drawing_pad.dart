import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:ocr/utils/static_data.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'dart:math' as math;

class DrawingPad extends StatefulWidget {
  const DrawingPad({super.key});

  @override
  State<DrawingPad> createState() => _DrawingPadState();
}

class _DrawingPadState extends State<DrawingPad> {
  /*
  // drawing pad variable
  */
  List<Offset> points = []; // List to store touch points
  final GlobalKey _repaintKey = GlobalKey();

  /* 
  // model variables
  */
  bool _xxsModel = false;
  List<String> modelPaths = ['assets/ocr_model_q.tflite', 'assets/quantized_model_xxs_v2.tflite'];

  /*
  // prediction variables
  */
  bool _isRunning = false;
  String predTxt = '';
  String predictionTime = "";
  String processingTime = "";
  Stopwatch stopwatch = Stopwatch()..start();

  /*
  // UI/Image Processing variables 
  */
  bool _preprocessingView = false;

  // Convert the image to Uint8List
  Uint8List imageBytes = Uint8List.fromList(img.encodePng(img.Image(width: 28, height: 28)));

  // empty images for initial convert view
  List<Uint8List> imageListBytes = [
    StaticData().uintImg28_28,
    StaticData().uintImg28_28,
    StaticData().uintImg28_28,
    StaticData().uintImg28_28,
    StaticData().uintImg28_28,
    StaticData().uintImg28_28,
    StaticData().uintImg28_28,
    StaticData().uintImg28_28
  ];

  /*
  // predict function
  */
  Future<String> predict(input) async {
    // change model based on switch
    final interpreter = await tfl.Interpreter.fromAsset(modelPaths[_xxsModel ? 1 : 0]);

    // List<List<List<List<double>>>> input = StaticData().input;
    List<String> classes = StaticData().classes;

    var output = List.filled(47, 0).reshape([1, 47]);

    interpreter.run(input, output);

    int maxIndex = 0;
    double maxValue = output[0][0];

    for (int i = 1; i < output[0].length; i++) {
      maxValue = math.max(maxValue, output[0][i]); // Use math.max for comparison
    }

    maxIndex = output[0].indexOf(maxValue);

    debugPrint(classes[maxIndex]);
    interpreter.close();
    return classes[maxIndex];
  }

  /*
  // drawing board/area widget
  */
  Widget drawingBoard() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.4,
      width: MediaQuery.of(context).size.width,
      child: RepaintBoundary(
        key: _repaintKey,
        child: GestureDetector(
          onPanUpdate: (details) {
            // check if in boundries
            if ((details.localPosition.dx <= MediaQuery.of(context).size.width && details.localPosition.dx >= 0) &&
                (details.localPosition.dy <= MediaQuery.of(context).size.height * 0.4 && details.localPosition.dy >= 0)) {
              if (points.isEmpty) {
                setState(() => points.add(details.localPosition));
              } else {
                if ((points.last - details.localPosition).distance > 30) {
                  setState(() {
                    points.addAll([details.localPosition, details.localPosition]);
                  });
                } else {
                  setState(() => points.add(details.localPosition));
                }
              }
            }
          },
          child: CustomPaint(
            painter: DrawingPainter(points),
          ),
        ),
      ),
    );
  }

  /*
  // UI
  */
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _xxsModel
                    ? const Text(
                        "Switch to Normal",
                        style: TextStyle(fontWeight: ui.FontWeight.bold, fontSize: 12),
                      )
                    : const Text(
                        "Switch to XXS",
                        style: TextStyle(fontWeight: ui.FontWeight.bold, fontSize: 12),
                      ),
                Switch(
                    value: _xxsModel,
                    activeColor: const ui.Color.fromARGB(255, 64, 83, 231),
                    activeTrackColor: Colors.blue[200],
                    inactiveThumbColor: Colors.black,
                    inactiveTrackColor: Colors.grey,
                    onChanged: (bool value) {
                      setState(() {
                        _xxsModel = value;
                      });
                    }),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _preprocessingView
                    ? const Text(
                        "Output View",
                        style: TextStyle(fontWeight: ui.FontWeight.bold, fontSize: 12),
                      )
                    : const Text(
                        "Preprocessing View",
                        style: TextStyle(fontWeight: ui.FontWeight.bold, fontSize: 12),
                      ),
                Switch(
                    value: _preprocessingView,
                    activeColor: const ui.Color.fromARGB(255, 64, 83, 231),
                    activeTrackColor: Colors.blue[200],
                    inactiveThumbColor: Colors.black,
                    inactiveTrackColor: Colors.grey,
                    onChanged: (bool value) {
                      setState(() {
                        _preprocessingView = value;
                      });
                    }),
              ],
            ),
          ],
        ),
        Text(
          "Model Size ${_xxsModel ? '12,335' : '147,919'} | Processing ${processingTime}ms | Prediction ${predictionTime}ms",
          style: const TextStyle(fontWeight: ui.FontWeight.bold, fontSize: 12),
        ),
        _preprocessingView
            ? Container(
                decoration: BoxDecoration(color: Colors.grey, border: Border.all(color: Colors.black), borderRadius: BorderRadius.circular(8.0)),
                height: MediaQuery.of(context).size.height * 0.3,
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(5, 30, 5, 0),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: imageListBytes.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisSpacing: 2, mainAxisSpacing: 2, crossAxisCount: 4),
                  itemBuilder: (context, index) {
                    return Image.memory(
                      imageListBytes[index],
                      scale: 0.3,
                    );
                  },
                ),
              )
            : Image.memory(
                imageBytes,
                scale: 0.125,
              ),
        const SizedBox(
          height: 10,
        ),
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.0), border: Border.all(color: Colors.black)),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                    color: Colors.grey[100], borderRadius: const BorderRadius.only(topLeft: Radius.circular(8.0), topRight: Radius.circular(8.0))),
                height: MediaQuery.of(context).size.height * 0.35,
                child: Stack(
                  children: [
                    Positioned(top: 0, left: 0, child: drawingBoard()),
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
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8.0), bottomRight: Radius.circular(8.0))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(ui.Color.fromARGB(255, 64, 83, 231))),
                      onPressed: () async {
                        if (!_isRunning) {
                          Duration t1 = stopwatch.elapsed;
                          _isRunning = true;
                          img.Image processedImage = await _captureAndPreprocessImage();
                          List<List<List<List<double>>>> imageArray = _convertToNormalizedArray(processedImage, 28);

                          imageBytes = Uint8List.fromList(img.encodePng(processedImage));

                          Duration t2 = stopwatch.elapsed;
                          predTxt = await predict(imageArray);
                          Duration t3 = stopwatch.elapsed;

                          processingTime = (t2 - t1).inMilliseconds.toString();
                          predictionTime = (t3 - t2).inMilliseconds.toString();
                          // You can now use `processedImage` as needed.
                          setState(() => points.clear());
                          _isRunning = false;
                        }
                      },
                      child: const Text(
                        'Predict & Clear',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      "Prediction: $predTxt",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  /*
  // Image processing functions
  */
  Future<img.Image> _captureAndPreprocessImage() async {
    // Capture the drawing as an image
    RenderRepaintBoundary boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();
    if (_preprocessingView) imageListBytes[0] = pngBytes;

    // Load the image with the image package
    img.Image capturedImage = img.decodeImage(pngBytes)!;

    // Invert colors
    img.invert(capturedImage);
    if (_preprocessingView) imageListBytes[1] = img.encodePng(capturedImage);

    // Apply Gaussian blur with sigma = 1
    capturedImage = img.gaussianBlur(capturedImage, radius: 1);
    if (_preprocessingView) imageListBytes[2] = img.encodePng(capturedImage);

    // Convert to grayscale
    capturedImage = img.grayscale(capturedImage);
    if (_preprocessingView) imageListBytes[3] = img.encodePng(capturedImage);

    // Extract the region around the character (bounding box)
    img.Image boundingBoxImage = _extractBoundingBox(capturedImage);

    // Center the character in a square image
    img.Image squareImage = _centerImage(boundingBoxImage);
    if (_preprocessingView) imageListBytes[4] = img.encodePng(squareImage);

    // Add a 2-pixel border
    img.Image paddedImage = img.copyResize(squareImage, width: squareImage.width + 4, height: squareImage.height + 4);
    if (_preprocessingView) imageListBytes[5] = img.encodePng(paddedImage);

    // Resize to 28x28
    img.Image resizedImage = img.copyResize(paddedImage, width: 28, height: 28, interpolation: img.Interpolation.cubic);
    if (_preprocessingView) imageListBytes[6] = img.encodePng(resizedImage);

    // Normalize to [0, 1]
    img.Image finalImage = img.adjustColor(resizedImage, contrast: 1.0, brightness: 1.0);
    if (_preprocessingView) imageListBytes[7] = img.encodePng(finalImage);

    // Convert the final image to a byte array
    return finalImage;
  }

  List<List<List<List<double>>>> _convertToNormalizedArray(img.Image image, int dims) {
    List<List<List<List<double>>>> normalizedArray = List.generate(
      1,
      (_) => List.generate(
        dims,
        (_) => List.generate(
          dims,
          (_) => List.filled(1, 0.0),
        ),
      ),
    );

    for (int y = 0; y < dims; y++) {
      for (int x = 0; x < dims; x++) {
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
    final trimmed = img.copyCrop(image, x: trimRect[0], y: trimRect[1], width: trimRect[2], height: trimRect[3]);

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
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 15.0;
    for (int i = 0; i < points.length - 2; i++) {
      if (points[i + 1] == points[i + 2]) {
      } else {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

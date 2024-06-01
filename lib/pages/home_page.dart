import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ocr/pages/drawing_pad.dart';
import 'package:ocr/static_data.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'dart:math' as math;

import 'package:image/image.dart' as img;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Future<String> predict() async {
  //   final interpreter =
  //       await tfl.Interpreter.fromAsset('assets/ocr_model.tflite');

  //   List<List<List<List<double>>>> input = StaticData().input;
  //   List<String> classes = StaticData().classes;

  //   var output = List.filled(47, 0).reshape([1, 47]);

  //   interpreter.run(input, output);

  //   int maxIndex = 0;
  //   double maxValue = output[0][0];

  //   for (int i = 1; i < output[0].length; i++) {
  //     maxValue =
  //         math.max(maxValue, output[0][i]); // Use math.max for comparison
  //   }

  //   maxIndex = output[0].indexOf(maxValue);

  //   debugPrint(classes[maxIndex]);
  //   return classes[maxIndex];
  // }

  // String predTxt = '';

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
    // debugPrint(byteList.shape.toString());

    // // Create the image
    // img.Image image = img.Image(width: 28, height: 28);

    // // Set pixel values
    // for (int y = 0; y < 28; y++) {
    //   for (int x = 0; x < 28; x++) {
    //     int pixelIndex = y * 28 + x;
    //     if (pixelIndex < byteList.length) {
    //       // Ensure pixel value is in the range [0, 255]
    //       int pixelValue = byteList[pixelIndex].clamp(0, 255);
    //       // Set the pixel value
    //       image.setPixel(x, y, img.ColorRgb8(pixelValue, pixelValue, pixelValue));
    //     }
    //   }
    // }

    // Uint8List imageBytes = Uint8List.fromList(img.encodePng(image));

    // debugPrint(imageBytes.toString());

    return Scaffold(
      body: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 35,
                ),
                Container(
                  decoration: BoxDecoration(
                      //border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(8)),
                  height: 700,
                  width: 350,
                  child: DrawingPad(),
                ),
                const SizedBox(
                  height: 10,
                ),
                // Image.memory(imageBytes, scale: 0.1,),
                // Text("Prediction: $predTxt"),
                // const SizedBox(
                //   height: 5,
                // ),
                // ElevatedButton(
                //     onPressed: () async {
                //       predTxt = await predict();
                //       setState(() {

                //       });
                //     },
                //     child: const Text('Predict')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

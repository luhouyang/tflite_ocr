import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:url_launcher/url_launcher.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    Future<void> launchUrlAsync(String urlString) async {
      final Uri url = Uri.parse(urlString);

      if (!await launchUrl(url)) {
        throw Exception('Could not launch $url');
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "OCR DEMO",
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const Text(
              "By: Lu Hou Yang",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(
              height: 48,
              width: 48,
            ),
            const Text(
              "Visit me at",
              style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(ui.Color.fromARGB(255, 64, 83, 231))),
              onPressed: () async {
                launchUrlAsync("https://www.luhouyang.com");
              },
              child: const Padding(
                padding: EdgeInsets.only(left: 36, right: 36),
                child: Text(
                  'Website',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(
              height: 16,
              width: 16,
            ),
            const Text(
              "Get the code at: ",
              style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(ui.Color.fromARGB(255, 64, 83, 231))),
              onPressed: () async {
                launchUrlAsync("https://github.com/luhouyang/tflite_ocr.git");
              },
              child: const Padding(
                padding: EdgeInsets.only(left: 36, right: 36),
                child: Text(
                  'GitHub',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(
              height: 64,
              width: 64,
            ),
          ],
        ),
      ),
    );
  }
}

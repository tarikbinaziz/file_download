import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';

// perfect downloading with dio and flutter_file_dialog
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Downloader',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DownloadScreen(),
    );
  }
}

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  bool isDownloading = false;
  double progress = 0.0;

  Future<void> downloadAndSavePdf() async {
    const url = "https://morth.nic.in/sites/default/files/dd12-13_0.pdf";
      // 🔹 Get file name from URL
    // final fileName = Uri.parse(url).pathSegments.last;
    final fileName = url.split('/').last;

    try {
      setState(() {
        isDownloading = true;
        progress = 0;
      });

      // Get app document directory
      final dir = await getApplicationDocumentsDirectory();
      final filePath = "${dir.path}/$fileName";

      // Download using Dio
      final dio = Dio();
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              progress = received / total;
            });
          }
        },
      );

      final file = File(filePath);
      if (await file.exists()) {
        // Open file dialog to save
        final params = SaveFileDialogParams(sourceFilePath: file.path);
        final savedPath = await FlutterFileDialog.saveFile(params: params);

        if (savedPath != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('File saved to: $savedPath')));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('File save cancelled')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download failed: file not found')),
        );
      }
    } catch (e) {
      print("❌ Download error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressPercent = (progress * 100).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(title: const Text('PDF Downloader')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isDownloading) ...[
              Text("Downloading: $progressPercent%"),
              const SizedBox(height: 20),
              CircularProgressIndicator(value: progress),
            ] else ...[
              ElevatedButton(
                onPressed: downloadAndSavePdf,
                child: const Text("Download & Save PDF"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_media_downloader/flutter_media_downloader.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
  WidgetsFlutterBinding.ensureInitialized();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: DownloadScreen());
  }
}

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  _DownloadScreenState createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  bool isDownloading = false;

  void startDownload() async {
    setState(() => isDownloading = true);

    File? file = await FileDownloader.downloadFile(
      "https://morth.nic.in/sites/default/files/dd12-13_0.pdf",
      "downloaded_document.pdf",
    );

    if (file != null) {
      await FileDownloader.openFile(file);
    } else {
      debugPrint("Download failed");
    }

    setState(() => isDownloading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Download Manager")),
      body: Center(
        child: ElevatedButton(
          onPressed: isDownloading ? null : startDownload,
          child: Text(isDownloading ? "Downloading..." : "Download PDF"),
        ),
      ),
    );
  }
}

class FileDownloader {
  static Future<String?> getDownloadDirectory() async {
    if (Platform.isAndroid) {
      return "/storage/emulated/0/Download"; // Scoped Storage compliant
    } else {
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    }
  }

  static Future<File?> downloadFile(String url, String fileName) async {
    try {
      final directoryPath = await getDownloadDirectory();
      if (directoryPath == null) {
        debugPrint("Failed to get download directory");
        return null;
      }

      final file = File('$directoryPath/$fileName');

      final response = await Dio().download(
        url,
        file.path,
        onReceiveProgress: (received, total) {
          debugPrint("Download Progress: $received/$total");
        },
      );

      if (response.statusCode == 200) {
        debugPrint("File downloaded: ${file.path}");
        return file;
      } else {
        debugPrint("Failed to download file");
        return null;
      }
    } catch (e) {
      debugPrint("Error downloading file: $e");
      return null;
    }
  }

  static Future<void> openFile(File? file) async {
    if (file == null) return;
    final result = await OpenFile.open(file.path);
    debugPrint("Open file result: $result");
  }
}

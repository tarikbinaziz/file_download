import 'dart:async';

import 'package:fl_downloader/fl_downloader.dart';
import 'package:flutter/material.dart';

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
  // final _flutterMediaDownloaderPlugin = MediaDownload();

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
  late StreamSubscription progressStream;
  int progress = 0;

  @override
  void initState() {
    super.initState();
    FlDownloader.initialize();
    progressStream = FlDownloader.progressStream.listen((event) {
      if (event.status == DownloadStatus.successful) {
        setState(() {
          progress = event.progress;
        });
        FlDownloader.openFile(filePath: event.filePath);
      } else if (event.status == DownloadStatus.running) {
        setState(() {
          progress = event.progress;
        });
      } else if (event.status == DownloadStatus.failed) {
        print('Failed');
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    progressStream.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Download Manager")),
      body: Column(
        children: [
          Text("Progress: $progress"),
          SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () async {
                var permission = await FlDownloader.requestPermission();
                print(permission);
                if (permission == StoragePermissionStatus.granted) {
                  FlDownloader.download(
                    "https://morth.nic.in/sites/default/files/dd12-13_0.pdf",
                  );
                }
              },
              child: Text(isDownloading ? "Downloading..." : "Download PDF"),
            ),
          ),
        ],
      ),
    );
  }
}

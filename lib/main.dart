import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fl_downloader/fl_downloader.dart';
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

Future openFile({required String url, String? fileName}) async {
  final name = fileName ?? url.split('/').last;
  final file = await downloadFile(url, name);
  if (file == null) return;
  print('File path: ${file.path}');
  OpenFile.open(file.path);
}

Future<File?> downloadFile(String url, String fileName) async {
  Directory? appStorage;
  try {
    if (Platform.isAndroid) {
      // appStorage = await getExternalStorageDirectory();
      appStorage = Directory('/storage/emulated/0/Download/');
    } else if (Platform.isIOS) {
      appStorage = await getApplicationDocumentsDirectory();
    }

    final file = File('${appStorage!.path}/$fileName');
    if (await file.exists()) {
      return file;
    }

    final response = await Dio().download(
      url,
      file.path,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: false,
        receiveTimeout: Duration.zero,
      ),

      onReceiveProgress: (received, total) {
        print('received: $received, total: $total');
      },
    );
    final raf = file.openSync(mode: FileMode.write);
    raf.writeFromSync(response.data);
    await raf.close();
    return file;
  } catch (e) {
    print('Error: $e');
    return null;
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

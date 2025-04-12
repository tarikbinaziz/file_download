import 'dart:async';
import 'dart:io';

import 'package:fl_downloader/fl_downloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';

// perfect downloading with fl_downloader and flutter_file_dialog
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

    /// save auto sanbox folder
    // progressStream = FlDownloader.progressStream.listen((event) {
    //   if (event.status == DownloadStatus.successful) {
    //     setState(() {
    //       progress = event.progress;
    //     });
    //     FlDownloader.openFile(filePath: event.filePath);
    //   } else if (event.status == DownloadStatus.running) {
    //     setState(() {
    //       progress = event.progress;
    //     });
    //   } else if (event.status == DownloadStatus.failed) {
    //     print('Failed');
    //   }
    // });

    // save custom folder
    progressStream = FlDownloader.progressStream.listen((event) async {
      if (event.status == DownloadStatus.successful) {
        setState(() {
          progress = event.progress;
        });

        try {
          // ✅ Convert URI string (file://...) to a valid file system path
          final path = Uri.parse(event.filePath ?? '').toFilePath();
          final originalFile = File(path);

          // ✅ Check if original file exists
          if (await originalFile.exists()) {
            // ✅ Get application documents directory
            final appDocDir = await getApplicationDocumentsDirectory();

            // ✅ (Optional) Ensure directory exists
            if (!(await appDocDir.exists())) {
              await appDocDir.create(recursive: true);
            }

            final fileName = originalFile.uri.pathSegments.last;
            final targetPath = '${appDocDir.path}/$fileName';

            // ✅ Copy file to app directory
            final copiedFile = await originalFile.copy(targetPath);

            // ✅ Open native save dialog
            final params = SaveFileDialogParams(
              sourceFilePath: copiedFile.path,
            );
            final savedPath = await FlutterFileDialog.saveFile(params: params);

            print("✅ Saved to user-selected path: $savedPath");
          } else {
            print("❌ Original file doesn't exist at: ${event.filePath}");
          }
        } catch (e) {
          print("❌ Error during file handling: $e");
        }
      } else if (event.status == DownloadStatus.running) {
        setState(() {
          progress = event.progress;
        });
      } else if (event.status == DownloadStatus.failed) {
        print('❌ Download Failed');
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

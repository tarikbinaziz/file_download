import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_media_downloader/flutter_media_downloader.dart';
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
  final _flutterMediaDownloaderPlugin = MediaDownload();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              // _flutterMediaDownloaderPlugin.downloadMedia(
              //   context,

              //   // "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf",
              //   // 'https://fastly.picsum.photos/id/893/200/300.jpg?hmac=7jsxm2l6ji-5CBnfrJO7IqDUekLtP4PvA7taLcRW2NI',
              //   // 'https://www.kasandbox.org/programming-images/avatars/spunky-sam-green.png',
              //   "https://morth.nic.in/sites/default/files/dd12-13_0.pdf",
              // );
              openFile(
                url: "https://morth.nic.in/sites/default/files/dd12-13_0.pdf",
              );
            },
            child: const Text('Media Download'),
          ),
        ),
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
  try {
    final appStorage = await getApplicationDocumentsDirectory();
    final file = File('${appStorage.path}/$fileName');
    if (await file.exists()) {
      return file;
    }
    final response = await Dio().get(
      url,
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

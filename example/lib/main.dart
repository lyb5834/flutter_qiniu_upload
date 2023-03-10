import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_qiniu_upload/core/config.dart';
import 'package:flutter_qiniu_upload/core/upload_controller.dart';
import 'package:flutter_qiniu_upload/flutter_qiniu_upload.dart';
import 'package:flutter_qiniu_upload_example/http_base.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  UploadManager? _uploadManager;
  bool _cancel = false;

  logger(String log) {
    if (kDebugMode) {
      print(log);
    }
  }

  @override
  void initState() {
    super.initState();
    getTemporaryDirectory().then((value) {
      String dir = value.path;
      String recorderPath = '$dir/QiNiuUpLoadCache';
      logger('recorderPath = $recorderPath');
      _uploadManager = UploadManager(
          config: Config(
        fixedZone: 'up-qos.storage.shmedia.tech',
        recorderPath: recorderPath,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              onPressed: _selectFile,
              child: const Text('选择资源上传'),
            ),
            OutlinedButton(
              onPressed: () => _cancel = true,
              child: const Text('取消上传'),
            ),
          ],
        ),
      ),
    );
  }

  _selectFile() async {
    final List<AssetEntity>? result = await AssetPicker.pickAssets(context,
        pickerConfig: const AssetPickerConfig(
          maxAssets: 1,
          requestType: RequestType.common,
        ));
    if (result != null && result.isNotEmpty) {
      _upload(result.first);
    }
  }

  _upload(AssetEntity entity) async {
    File? file = await entity.file;
    String path = file?.path ?? '';
    logger('path = $path');

    _step1(path);
  }

  _step1(String filePath) async {
    String fileName = filePath.split('/').last;
    Map<String, dynamic> params = {
      'fileNames': [fileName]
    };
    ServerResponse response =
        await HttpBase().post('/api/app/file/getUploadTokens', params: params);
    List? list = response.data as List?;
    Map<String, dynamic>? map = list?.first;
    logger('step1 = $map');
    if (map != null) {
      _step2(filePath, map);
    }
  }

  _step2(String filePath, Map<String, dynamic> map) async {
    String? uploadToken = map['uploadToken'] as String?;
    String? storageName = map['storageName'] as String?;

    UploadController controller = UploadController(
      progressHandler: (key, percent) {
        logger('key = $key | percent = $percent');
      },
      cancellationSignal: () {
        if (_cancel) {
          _cancel = false;
          return true;
        }
        return false;
      },
    );

    _uploadManager
        ?.upload(
            filePath: filePath,
            token: uploadToken ?? '',
            key: storageName ?? '',
            controller: controller)
        .then((value) {
      Map<String, dynamic> result = Map.from(value);
      logger('七牛上传回调 = $result');
    }).onError((error, stackTrace) {
      logger('七牛上传失败 = ${error.toString()}');
    });
  }
}

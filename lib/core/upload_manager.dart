import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_qiniu_upload/core/config.dart';
import 'package:flutter_qiniu_upload/core/upload_controller.dart';

class UploadManager {
  final _methodChannel = const MethodChannel('flutter_qiniu_upload');
  final _eventChannel = const EventChannel('flutter_qiniu_upload/event');

  final Config config;

  UploadController? _controller;

  late final Stream _stream = _eventChannel.receiveBroadcastStream();

  UploadManager({required this.config}) {
    Map<String, dynamic> configs = config.toJson();
    _methodChannel.invokeMethod('init', configs);
    _addListener();
  }

  _addListener() {
    _stream.listen((event) {
      Map<String, dynamic> data = Map.from(event);
      String? type = data['type'] as String?;
      if (type == 'percent') {
        Map<String, dynamic>? percentInfo = Map.from(data['data']);
        String? uploadKey = percentInfo['key'] as String?;
        double percent = double.parse(percentInfo['percent'] ?? 0);
        _controller?.progressHandler?.call(uploadKey ?? '', percent);
      } else if (type == 'cancel') {
        // bool cancelSignal = _controller?.cancellationSignal?.call() ?? false;
        // _methodChannel.invokeMethod('cancel', cancelSignal);
      }
    });
  }

  Future<Map<String, dynamic>> upload({
    required String filePath,
    required String token,
    required String key,
    required UploadController controller,
  }) async {
    _controller = controller;

    Map<String, dynamic> params = {
      'filePath': filePath,
      'token': token,
      'key': key,
    };

    if (controller.params != null) {
      params['params'] = controller.params;
    }
    if (controller.mimeType != null) {
      params['mimeType'] = controller.mimeType;
    }
    if (controller.checkCrc != null) {
      params['checkCrc'] = controller.checkCrc;
    }

    String jsonString = await _methodChannel.invokeMethod('upload', params);
    Map<String, dynamic> result = json.decode(jsonString);
    return result;
  }

  Future<bool> cancel() async {
    return await _methodChannel.invokeMethod('cancel', true);
  }
}

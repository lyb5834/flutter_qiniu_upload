import 'package:flutter/services.dart';
import 'package:flutter_qiniu_upload/core/config.dart';
import 'package:flutter_qiniu_upload/core/upload_controller.dart';

class UploadManager {
  final _methodChannel = const MethodChannel('flutter_qiniu_upload');
  final _eventChannel = const EventChannel('flutter_qiniu_upload_event');

  final Config config;

  UploadManager({required this.config}) {
    Map<String, dynamic> configs = config.toJson();
    _methodChannel.invokeMethod('init', configs);
  }

  Future upload({
    required String filePath,
    required String token,
    required String key,
    required UploadController controller,
  }) async {
    _eventChannel.receiveBroadcastStream('percent').listen((event) {
      Map<String, dynamic> data = Map.from(event);
      String? uploadKey = data['key'] as String?;
      double percent = double.parse(data['percent']);
      controller.progressHandler?.call(uploadKey ?? '', percent);
    });
    _eventChannel.receiveBroadcastStream('cancelSignal').listen((event) {
      bool cancelSignal = controller.cancellationSignal?.call() ?? false;
      _methodChannel.invokeMethod('cancel', cancelSignal);
    });

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

    return _methodChannel.invokeMethod('upload', params);
  }
}

class UploadController {
  /// 扩展参数，以x:开头的用户自定义参数 可添加网络检测次数：netCheckTime，int类型，默认600，每增加1，检测时间增加500ms
  final Map<String, dynamic>? params;

  /// 指定上传文件的MimeType
  final String? mimeType;

  /// 启用上传内容crc32校验
  final bool? checkCrc;

  /// 上传内容进度处理
  final void Function(String key, double percent)? progressHandler;

  UploadController({
    this.params,
    this.mimeType,
    this.checkCrc = false,
    this.progressHandler,
  });
}

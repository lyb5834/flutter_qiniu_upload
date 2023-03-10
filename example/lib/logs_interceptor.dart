import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LogsInterceptors extends InterceptorsWrapper {
  logger(String log) {
    if (kDebugMode) {
      print(log);
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logger('LogsInterceptors '
        ' ==onRequest path: ${options.baseUrl}${options.path}'
        ' ==onRequest headers: ${options.headers.toString()}'
        ' ==onRequest 请求参数: ${options.data.toString()}');

    return handler.next(options);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    logger(
        'LogsInterceptors ==请求异常 onError: ${err.toString()} message: ${err.message.toString()} ');
    if (err.response != null) {
      logger('LogsInterceptors ==请求异常 err.response:${err.response.toString()}');
    }
    return handler.next(err);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    logger(
        '==onResponse path: ${response.requestOptions.baseUrl}${response.requestOptions.path}  ==onResponse 请求结果: ${response.data.toString()}');
    return handler.next(response); // continue
  }
}

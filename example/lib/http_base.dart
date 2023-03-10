import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_qiniu_upload_example/logs_interceptor.dart';

typedef TFromJson<T> = T Function(dynamic json);

const bool inProduction = bool.fromEnvironment("dart.vm.product");

class HttpBase {
  ///超时时间
  static final HttpBase _instance = HttpBase._internal();

  factory HttpBase() => _instance;

  Dio? _dio;
  final CancelToken _cancelToken = CancelToken();

  HttpBase._internal() {
    if (_dio == null) {
      // BaseOptions、Options、RequestOptions 都可以配置参数，优先级别依次递增，且可以根据优先级别覆盖参数
      BaseOptions options = BaseOptions(
          baseUrl: 'https://test-minhang.easttone.com/media-basic-port',
          connectTimeout: 20 * 1000,
          receiveTimeout: 60 * 1000,
          sendTimeout: 60 * 1000,
          headers: {
            "siteId": '310112',
            "command": "minhang",
            "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJzd"
                "WIiOiJjODE1NmM2MTU4Y2Q0MjQ3YTAzMGExNThk"
                "ZDg1NjZkYzszMTAxMTIiLCJpYXQiOjE2NjIwMjQ0ODAs"
                "ImV4cCI6MjY5ODgyNDQ4MH0.lQqDM3Mb40KNEvT3_buP4mEHp"
                "OSGH6tvgNhxYgWExuZl5C0mFxoSTsgG4fl4zZwDtMCJ6ApVNDXtN5BfOEkg0Q",
          });

      _dio = Dio(options);

      _dio?.interceptors.add(LogsInterceptors());
    }
  }

  ///使用 HttpBase.getInstance('baseUrl').post()
  ///HttpBase.getInstance().post()
  static HttpBase getInstance({String? baseUrl}) {
    if (baseUrl == null) {
      return _instance._normal();
    } else {
      return _instance._baseUrl(baseUrl);
    }
  }

  //用于指定特定域名，比如cdn和kline首次的http请求
  HttpBase _baseUrl(String baseUrl) {
    if (_dio != null) {
      _dio?.options.baseUrl = baseUrl;
    }
    return this;
  }

  //一般请求，默认域名
  HttpBase _normal() {
    if (_dio != null) {
      if (_dio?.options.baseUrl !=
          'https://mhapi.shmedia.tech/media-basic-port') {
        _dio?.options.baseUrl = 'https://mhapi.shmedia.tech/media-basic-port';
      }
    }
    return this;
  }

  void cancelRequests({CancelToken? token}) {
    token ?? _cancelToken.cancel("cancelled");
  }

  /// restful get 操作
  Future get(
    String path, {
    Map<String, dynamic>? params,
    Options? options,
  }) async {
    return _requestHttp(path, 'get', params: params, options: options);
  }

  /// restful post 操作
  Future<ServerResponse> post(
    String path, {
    Map<String, dynamic>? params,
    Options? options,
  }) async {
    return _requestHttp(path, 'post', params: params, options: options);
  }

  /// restful post form 表单提交操作
  Future postForm(
    String path, {
    Map<String, dynamic>? params,
    Options? options,
    CancelToken? cancelToken,
  }) async {}

  Future<ServerResponse> _requestHttp(String path, String method,
      {Map<String, dynamic>? params, Options? options}) async {
    Options requestOptions = options ?? Options();
    try {
      Response<dynamic> response;
      if (method == 'get') {
        response = await _dio!
            .get(path, queryParameters: params, options: requestOptions);
      } else {
        response =
            await _dio!.post(path, data: params, options: requestOptions);
      }
      final ServerResponse serverResponse =
          ServerResponse.fromJson(response.data);
      return serverResponse;
    } on DioError catch (error) {
      return ServerResponse.error('网络请求异常,请稍后操作');
    } catch (error) {
      return ServerResponse.error('网络请求异常,请稍后操作');
    }
  }
}

class ServerResponse {
  int? code = -1;
  String? message;
  dynamic data;

  ServerResponse({this.code, this.message, this.data});

  ServerResponse.fromJson(Map<String, dynamic> json) {
    data = json['data'];
    code = json['code'];
    message = json['message'] ?? json['msg'];
  }

  Map<String, dynamic> toJson() => {
        "data": data,
        "code": -1,
        "msg": message,
      };

  ServerResponse.error(String errorMsg) {
    data = null;
    code = -1;
    message = errorMsg;
  }

  bool isSuccess() {
    return code == 0;
  }

  @override
  String toString() {
    return 'ServerResponse{code: $code, message: $message, data: $data}';
  }
}

/// 接口的code没有返回为true的异常
class NotSuccessException implements Exception {
  String? message;

  NotSuccessException.fromRespData(ServerResponse respData) {
    message = respData.message;
  }

  @override
  String toString() {
    return 'NotExpectedException{respData: $message}';
  }
}

/// 用于未登录等权限不够,需要跳转授权页面
class UnAuthorizedException implements Exception {
  const UnAuthorizedException();

  @override
  String toString() => 'UnAuthorizedException';
}

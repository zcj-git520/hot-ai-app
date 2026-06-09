import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/core/error/app_exception.dart';
import 'package:hot_ai_app/core/network/interceptors/error_interceptor.dart';

Dio _dio() => Dio()..interceptors.add(ErrorInterceptor());

void main() {
  test('响应 code != 0 抛 AppException', () async {
    final dio = _dio();
    dio.httpClientAdapter = _StubAdapter(response: Response(
      requestOptions: RequestOptions(path: '/x'),
      statusCode: 200,
      data: {'code': 1001, 'data': null, 'message': 'err'},
    ));
    expect(
      () => dio.get('/x'),
      throwsA(isA<DioException>()
          .having((e) => e.error, 'error', isA<AppException>()
              .having((e) => e.code, 'code', 1001)
              .having((e) => e.message, 'message', 'err'))),
    );
  });

  test('HTTP 4xx 抛 AppException with status', () async {
    final dio = _dio();
    dio.httpClientAdapter = _StubAdapter(response: Response(
      requestOptions: RequestOptions(path: '/x'),
      statusCode: 500,
      data: 'oops',
    ));
    expect(
      () => dio.get('/x'),
      throwsA(isA<DioException>().having((e) => e.error, 'error', isA<AppException>())),
    );
  });
}

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter({required this.response});
  final Response response;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = response.data is String
        ? response.data as String
        : jsonEncode(response.data);
    return ResponseBody.fromString(
      body,
      response.statusCode ?? 200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
  @override
  void close({bool force = false}) {}
}

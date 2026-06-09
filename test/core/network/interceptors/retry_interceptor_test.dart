import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/core/network/interceptors/retry_interceptor.dart';

void main() {
  test('幂等 GET 失败 1 次后重试 1 次', () async {
    int callCount = 0;
    final dio = Dio();
    dio.httpClientAdapter = _CountingAdapter(
      onCall: () => callCount++,
      shouldFail: (n) => n == 1, // 第 1 次失败
    );
    dio.interceptors.add(RetryInterceptor(dio: dio));
    final r = await dio.get('/x');
    expect(r.statusCode, 200);
    expect(callCount, 2);
  });

  test('POST 不重试', () async {
    int callCount = 0;
    final dio = Dio();
    dio.httpClientAdapter = _CountingAdapter(
      onCall: () => callCount++,
      shouldFail: (_) => true,
    );
    dio.interceptors.add(RetryInterceptor(dio: dio));
    await expectLater(dio.post('/x'), throwsA(isA<DioException>()));
    expect(callCount, 1);
  });
}

class _CountingAdapter implements HttpClientAdapter {
  _CountingAdapter({required this.onCall, required this.shouldFail});
  final void Function() onCall;
  final bool Function(int) shouldFail;
  int _n = 0;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? s, Future<void>? c) async {
    onCall();
    _n++;
    if (shouldFail(_n)) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString('{"code":0,"data":{},"message":"ok"}', 200, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }
  @override
  void close({bool force = false}) {}
}

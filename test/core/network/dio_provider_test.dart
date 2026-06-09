import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/core/network/dio_provider.dart';

void main() {
  test('buildDio 用 --dart-define 注入 base URL', () {
    const url = 'https://example.com/api';
    final dio = buildDio(baseUrl: url);
    expect(dio.options.baseUrl, url);
    expect(dio.options.connectTimeout?.inSeconds, 15);
    expect(dio.options.receiveTimeout?.inSeconds, 30);
  });
}

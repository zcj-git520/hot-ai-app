import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/core/error/app_exception.dart';

void main() {
  group('AppException', () {
    test('toString 包含 code 和 message', () {
      final e = AppException(code: 1001, message: '参数错误');
      expect(e.toString(), contains('1001'));
      expect(e.toString(), contains('参数错误'));
    });

    test('支持任意自定义字段', () {
      final e = AppException(code: 0, message: 'ok', extra: {'traceId': 'abc'});
      expect(e.extra['traceId'], 'abc');
    });
  });
}

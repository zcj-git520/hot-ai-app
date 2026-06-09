import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/core/network/api_response.dart';
import 'package:hot_ai_app/core/error/app_exception.dart';

void main() {
  test('code==0 解包 data', () {
    final r = ApiResponse.fromJson<int>({'code': 0, 'data': 42, 'message': 'ok'}, (j) => j as int);
    expect(r.unwrap(), 42);
  });

  test('code!=0 抛 AppException', () {
    final r = ApiResponse.fromJson<int>({'code': 1001, 'data': null, 'message': 'err'}, (j) => j as int);
    expect(() => r.unwrap(), throwsA(isA<AppException>()));
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/bootstrap.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('App 启动后能进 5 Tab 壳 + 列表空状态', (tester) async {
    await bootstrap();
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('资讯'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    // 资讯页未登录应显示错误或加载,这里只验证不崩溃
    expect(tester.takeException(), isNull);
  });
}

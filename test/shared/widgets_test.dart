import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/shared/widgets/empty_view.dart';
import 'package:hot_ai_app/shared/widgets/error_view.dart';
import 'package:hot_ai_app/shared/widgets/loading_view.dart';

void main() {
  testWidgets('LoadingView 显示 CircularProgressIndicator', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: LoadingView())));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('ErrorView 显示 message + 重试按钮', (tester) async {
    var retried = false;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ErrorView(
      message: 'oops', onRetry: () => retried = true,
    ))));
    expect(find.text('oops'), findsOneWidget);
    await tester.tap(find.text('重试'));
    expect(retried, true);
  });

  testWidgets('EmptyView 显示提示文字', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: EmptyView(text: '暂无数据'))));
    expect(find.text('暂无数据'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/features/tools/domain/tool.dart';
import 'package:hot_ai_app/features/tools/domain/tool_category.dart';
import 'package:hot_ai_app/features/tools/domain/tool_repository.dart';
import 'package:hot_ai_app/features/tools/presentation/tool_detail_page.dart';
import 'package:hot_ai_app/features/tools/presentation/tools_controller.dart';
import 'package:hot_ai_app/shared/models/pagination.dart';

class _FakeRepo implements ToolRepository {
  final Tool t;
  _FakeRepo(this.t);
  @override
  Future<List<ToolCategory>> getCategories() async => const [];
  @override
  Future<Pagination<Tool>> getTools({required int page, int? categoryId, String? search}) async =>
      Pagination(items: [t], page: 1, total: 1);
  @override
  Future<Tool> getTool(String slug) async => t;
  @override
  Future<void> setFavorite(String id, bool f) async {}
  @override
  Future<List<String>> getFavorites() async => [];
}

Tool _t() => Tool(
      id: '1', name: 'Cursor', slug: 'cursor', icon: '🖱',
      description: 'AI IDE',
      officialUrl: 'https://cursor.sh',
      documentationUrl: 'https://docs.cursor.sh',
      pricing: 'freemium', pricingDescription: '免费版 + Pro 订阅',
      categoryId: 1, difficulty: 'beginner',
      rating: 4.8, reviewCount: 1024, viewCount: 50000, popularity: 100,
      tags: const ['AI', 'IDE', '代码'],
      featured: true, isOnline: true, isFavorited: false,
    );

void main() {
  testWidgets('展示工具名称、描述、评分、标签、官方链接', (tester) async {
    final t = _t();
    await tester.pumpWidget(ProviderScope(
      overrides: [toolRepositoryProvider.overrideWith((ref) => _FakeRepo(t))],
      child: const MaterialApp(home: ToolDetailPage(slug: 'cursor')),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Cursor'), findsOneWidget);
    expect(find.text('AI IDE'), findsOneWidget);
    expect(find.text('4.8'), findsOneWidget);
    expect(find.text('1024'), findsOneWidget);
    expect(find.textContaining('AI'), findsAtLeastNWidgets(1));
    expect(find.textContaining('IDE'), findsAtLeastNWidgets(1));
    // 官方链接按钮
    expect(find.text('访问官网'), findsOneWidget);
    expect(find.text('查看文档'), findsOneWidget);
  });
}

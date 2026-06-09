import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/features/tools/domain/tool.dart';
import 'package:hot_ai_app/features/tools/domain/tool_category.dart';
import 'package:hot_ai_app/features/tools/domain/tool_repository.dart';
import 'package:hot_ai_app/features/tools/presentation/tools_controller.dart';
import 'package:hot_ai_app/features/tools/presentation/tools_list_page.dart';
import 'package:hot_ai_app/shared/models/pagination.dart';

class _FakeRepo implements ToolRepository {
  final List<Tool> data;
  final List<ToolCategory> cats;
  _FakeRepo(this.data, {this.cats = const []});
  @override
  Future<List<ToolCategory>> getCategories() async => cats;
  @override
  Future<Pagination<Tool>> getTools({required int page, int? categoryId, String? search}) async =>
      Pagination(items: data, page: page, total: 1);
  @override
  Future<Tool> getTool(String slug) async => data.first;
  @override
  Future<void> setFavorite(String id, bool f) async {}
  @override
  Future<List<String>> getFavorites() async => [];
}

Tool _t(String id, {String name = 't', String slug = 's', String pricing = 'free'}) => Tool(
      id: id, name: name, slug: slug, icon: '🖱', description: 'd',
      officialUrl: 'https://x', documentationUrl: '', pricing: pricing,
      pricingDescription: '', categoryId: 1, difficulty: 'beginner',
      rating: 4.5, reviewCount: 100, viewCount: 1000, popularity: 50,
      tags: const ['AI'], featured: false, isOnline: true, isFavorited: false,
    );

void main() {
  testWidgets('空态:EmptyView', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [toolRepositoryProvider.overrideWith((ref) => _FakeRepo([]))],
      child: const MaterialApp(home: ToolsListPage()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('暂无工具'), findsOneWidget);
  });

  testWidgets('数据态:展示 1 条工具', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [toolRepositoryProvider.overrideWith((ref) => _FakeRepo([
        _t('1', name: 'Cursor'),
      ]))],
      child: const MaterialApp(home: ToolsListPage()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Cursor'), findsOneWidget);
    expect(find.text('免费'), findsOneWidget);
  });

  testWidgets('分类 chip 从 categories 拉取', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [toolRepositoryProvider.overrideWith((ref) => _FakeRepo(
        [_t('1')],
        cats: [
          ToolCategory(id: '1', name: '代码助手', slug: 'code', icon: '💻',
            description: '', sortOrder: 1, featured: true),
          ToolCategory(id: '2', name: '图像生成', slug: 'img', icon: '🎨',
            description: '', sortOrder: 2, featured: false),
        ],
      ))],
      child: const MaterialApp(home: ToolsListPage()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('全部'), findsOneWidget);
    expect(find.textContaining('代码助手'), findsOneWidget);
    expect(find.textContaining('图像生成'), findsOneWidget);
  });
}

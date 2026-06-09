import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/features/tools/domain/tool.dart';
import 'package:hot_ai_app/features/tools/domain/tool_category.dart';
import 'package:hot_ai_app/features/tools/domain/tool_repository.dart';
import 'package:hot_ai_app/features/tools/presentation/tools_controller.dart';
import 'package:hot_ai_app/shared/models/pagination.dart';

class _FakeRepo implements ToolRepository {
  final List<Tool> data;
  int? lastCategory;
  String? lastSearch;
  _FakeRepo(this.data);
  @override
  Future<List<ToolCategory>> getCategories() async => const [];
  @override
  Future<Pagination<Tool>> getTools({required int page, int? categoryId, String? search}) async {
    lastCategory = categoryId;
    lastSearch = search;
    return Pagination(items: data, page: page, total: 1000);
  }
  @override
  Future<Tool> getTool(String slug) async => data.first;
  @override
  Future<void> setFavorite(String id, bool f) async {}
  @override
  Future<List<String>> getFavorites() async => [];
}

Tool _t(String id) => Tool(
      id: id, name: 't$id', slug: 's$id', icon: '🖱', description: 'd',
      officialUrl: 'https://x', documentationUrl: '', pricing: 'free',
      pricingDescription: '', categoryId: 1, difficulty: 'beginner',
      rating: 4, reviewCount: 0, viewCount: 0, popularity: 0,
      tags: const [], featured: false, isOnline: true, isFavorited: false,
    );

void main() {
  test('load 第一页', () async {
    final container = ProviderContainer(overrides: [
      toolRepositoryProvider.overrideWith((ref) => _FakeRepo([_t('1')])),
    ]);
    addTearDown(container.dispose);
    await container.read(toolsControllerProvider.notifier).load();
    expect(container.read(toolsControllerProvider).items.length, 1);
  });

  test('setCategoryId 后 load 用新参数', () async {
    final repo = _FakeRepo([_t('1')]);
    final container = ProviderContainer(overrides: [
      toolRepositoryProvider.overrideWith((ref) => repo),
    ]);
    addTearDown(container.dispose);
    await container.read(toolsControllerProvider.notifier).setCategoryId(2);
    expect(repo.lastCategory, 2);
  });

  test('setSearch 后 load 用新参数', () async {
    final repo = _FakeRepo([_t('1')]);
    final container = ProviderContainer(overrides: [
      toolRepositoryProvider.overrideWith((ref) => repo),
    ]);
    addTearDown(container.dispose);
    await container.read(toolsControllerProvider.notifier).setSearch('cursor');
    expect(repo.lastSearch, 'cursor');
  });

  test('toggleFavorite 失败回滚', () async {
    final container = ProviderContainer(overrides: [
      toolRepositoryProvider.overrideWith((ref) => _ThrowingFavRepo([_t('1')])),
    ]);
    addTearDown(container.dispose);
    await container.read(toolsControllerProvider.notifier).load();
    await container.read(toolsControllerProvider.notifier).toggleFavorite('1');
    expect(container.read(toolsControllerProvider).items.first.isFavorited, false);
  });
}

class _ThrowingFavRepo implements ToolRepository {
  _ThrowingFavRepo(this.data);
  final List<Tool> data;
  @override
  Future<List<ToolCategory>> getCategories() async => const [];
  @override
  Future<Pagination<Tool>> getTools({required int page, int? categoryId, String? search}) async =>
      Pagination(items: data, page: page, total: 1000);
  @override
  Future<Tool> getTool(String slug) async => data.first;
  @override
  Future<void> setFavorite(String id, bool f) async => throw Exception('boom');
  @override
  Future<List<String>> getFavorites() async => [];
}

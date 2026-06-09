import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/features/articles/domain/article.dart';
import 'package:hot_ai_app/features/articles/domain/article_repository.dart';
import 'package:hot_ai_app/features/articles/presentation/articles_controller.dart';
import 'package:hot_ai_app/shared/models/pagination.dart';

class _FakeRepo implements ArticleRepository {
  final List<Article> data;
  _FakeRepo(this.data);
  @override
  Future<Pagination<Article>> getArticles({required int page, String? category}) async {
    // 让 hasMore 保持 true,这样 loadMore 会执行
    return Pagination(items: data, page: page, total: 1000);
  }
  @override
  Future<Article> getArticle(String id) async => data.firstWhere((a) => a.id == id);
  @override
  Future<void> setFavorite(String id, bool f) async {}
  @override
  Future<List<String>> getFavorites() async => [];
}

Article _a(String id) => Article(
      id: id, title: 't$id', summary: '', contentHtml: '', coverUrl: null,
      publishedAt: DateTime(2026), category: '', isFavorited: false,
    );

void main() {
  test('加载第一页', () async {
    final container = ProviderContainer(overrides: [
      articleRepositoryProvider.overrideWith((ref) => _FakeRepo([_a('1')])),
    ]);
    addTearDown(container.dispose);
    await container.read(articlesControllerProvider.notifier).load();
    final state = container.read(articlesControllerProvider);
    expect(state.items.length, 1);
    expect(state.loading, false);
  });

  test('loadMore 追加并清空 loadingMore', () async {
    final container = ProviderContainer(overrides: [
      articleRepositoryProvider.overrideWith((ref) => _FakeRepo([_a('1')])),
    ]);
    addTearDown(container.dispose);
    await container.read(articlesControllerProvider.notifier).load();
    await container.read(articlesControllerProvider.notifier).loadMore();
    final state = container.read(articlesControllerProvider);
    expect(state.items.length, 2);
    expect(state.loadingMore, false);
  });
}

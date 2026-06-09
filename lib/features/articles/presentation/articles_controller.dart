import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hot_ai_app/features/articles/domain/article.dart';
import 'package:hot_ai_app/features/articles/domain/article_repository.dart';

final articleRepositoryProvider = Provider<ArticleRepository>((ref) {
  // 真实实现在 main.dart 通过 override 注入;此处为占位
  throw UnimplementedError('Override in main.dart');
});

class ArticlesState {
  const ArticlesState({
    this.items = const [],
    this.loading = false,
    this.loadingMore = false,
    this.page = 0,
    this.hasMore = true,
    this.error,
  });
  final List<Article> items;
  final bool loading;
  final bool loadingMore;
  final int page;
  final bool hasMore;
  final String? error;

  ArticlesState copyWith({
    List<Article>? items, bool? loading, bool? loadingMore,
    int? page, bool? hasMore, String? error, bool clearError = false,
  }) => ArticlesState(
        items: items ?? this.items,
        loading: loading ?? this.loading,
        loadingMore: loadingMore ?? this.loadingMore,
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
        error: clearError ? null : (error ?? this.error),
      );
}

class ArticlesController extends StateNotifier<ArticlesState> {
  ArticlesController(this._repo) : super(const ArticlesState());
  final ArticleRepository _repo;

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final page = await _repo.getArticles(page: 1, category: null);
      state = state.copyWith(items: page.items, page: 1, hasMore: page.hasMore, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore) return;
    state = state.copyWith(loadingMore: true);
    try {
      final next = state.page + 1;
      final page = await _repo.getArticles(page: next, category: null);
      state = state.copyWith(
        items: [...state.items, ...page.items],
        page: next,
        hasMore: page.hasMore,
        loadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(loadingMore: false, error: e.toString());
    }
  }

  Future<void> toggleFavorite(String id) async {
    final item = state.items.firstWhere((a) => a.id == id);
    final newFav = !item.isFavorited;
    state = state.copyWith(items: [
      for (final a in state.items) a.id == id ? a.copyWith(isFavorited: newFav) : a,
    ]);
    try {
      await _repo.setFavorite(id, newFav);
    } catch (_) {
      // 回滚
      state = state.copyWith(items: [
        for (final a in state.items) a.id == id ? a.copyWith(isFavorited: !newFav) : a,
      ]);
    }
  }
}

final articlesControllerProvider =
    StateNotifierProvider<ArticlesController, ArticlesState>((ref) {
  return ArticlesController(ref.watch(articleRepositoryProvider));
});

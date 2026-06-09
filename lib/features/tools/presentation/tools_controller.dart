import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hot_ai_app/features/tools/domain/tool.dart';
import 'package:hot_ai_app/features/tools/domain/tool_category.dart';
import 'package:hot_ai_app/features/tools/domain/tool_repository.dart';

final toolRepositoryProvider = Provider<ToolRepository>((ref) {
  throw UnimplementedError('Override in main.dart');
});

class ToolsState {
  const ToolsState({
    this.items = const [],
    this.categories = const [],
    this.loading = false,
    this.loadingMore = false,
    this.page = 0,
    this.hasMore = true,
    this.categoryId,
    this.search,
    this.error,
  });
  final List<Tool> items;
  final List<ToolCategory> categories;
  final bool loading;
  final bool loadingMore;
  final int page;
  final bool hasMore;
  final int? categoryId;
  final String? search;
  final String? error;

  ToolsState copyWith({
    List<Tool>? items, List<ToolCategory>? categories,
    bool? loading, bool? loadingMore, int? page, bool? hasMore,
    int? categoryId, bool clearCategory = false,
    String? search, bool clearSearch = false,
    String? error, bool clearError = false,
  }) => ToolsState(
        items: items ?? this.items,
        categories: categories ?? this.categories,
        loading: loading ?? this.loading,
        loadingMore: loadingMore ?? this.loadingMore,
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
        categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
        search: clearSearch ? null : (search ?? this.search),
        error: clearError ? null : (error ?? this.error),
      );
}

class ToolsController extends StateNotifier<ToolsState> {
  ToolsController(this._repo) : super(const ToolsState());
  final ToolRepository _repo;

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final cats = state.categories.isEmpty ? await _repo.getCategories() : state.categories;
      final page = await _repo.getTools(
        page: 1, categoryId: state.categoryId, search: state.search,
      );
      state = state.copyWith(
        items: page.items, categories: cats,
        page: 1, hasMore: page.hasMore, loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore) return;
    state = state.copyWith(loadingMore: true);
    try {
      final next = state.page + 1;
      final page = await _repo.getTools(
        page: next, categoryId: state.categoryId, search: state.search,
      );
      state = state.copyWith(
        items: [...state.items, ...page.items],
        page: next, hasMore: page.hasMore, loadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(loadingMore: false, error: e.toString());
    }
  }

  Future<void> setCategoryId(int? id) async {
    state = state.copyWith(
      categoryId: id, clearCategory: id == null,
      page: 0, items: const [], hasMore: true,
    );
    await load();
  }

  Future<void> setSearch(String? q) async {
    state = state.copyWith(
      search: q, clearSearch: q == null || q.isEmpty,
      page: 0, items: const [], hasMore: true,
    );
    await load();
  }

  Future<void> toggleFavorite(String id) async {
    final item = state.items.firstWhere((t) => t.id == id);
    final newFav = !item.isFavorited;
    state = state.copyWith(items: [
      for (final t in state.items) t.id == id ? t.copyWith(isFavorited: newFav) : t,
    ]);
    try {
      await _repo.setFavorite(id, newFav);
    } catch (_) {
      state = state.copyWith(items: [
        for (final t in state.items) t.id == id ? t.copyWith(isFavorited: !newFav) : t,
      ]);
    }
  }
}

final toolsControllerProvider =
    StateNotifierProvider<ToolsController, ToolsState>((ref) {
  return ToolsController(ref.watch(toolRepositoryProvider));
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hot_ai_app/features/learning_paths/domain/learning_path.dart';
import 'package:hot_ai_app/features/learning_paths/domain/learning_path_repository.dart';

final learningPathRepositoryProvider = Provider<LearningPathRepository>((ref) {
  throw UnimplementedError('Override in main.dart');
});

class LearningPathsState {
  const LearningPathsState({
    this.items = const [],
    this.loading = false,
    this.loadingMore = false,
    this.page = 0,
    this.hasMore = true,
    this.difficulty,
    this.error,
  });
  final List<LearningPath> items;
  final bool loading;
  final bool loadingMore;
  final int page;
  final bool hasMore;
  final String? difficulty;
  final String? error;

  LearningPathsState copyWith({
    List<LearningPath>? items, bool? loading, bool? loadingMore,
    int? page, bool? hasMore, String? difficulty, bool clearDifficulty = false,
    String? error, bool clearError = false,
  }) => LearningPathsState(
        items: items ?? this.items,
        loading: loading ?? this.loading,
        loadingMore: loadingMore ?? this.loadingMore,
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
        difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
        error: clearError ? null : (error ?? this.error),
      );
}

class LearningPathsController extends StateNotifier<LearningPathsState> {
  LearningPathsController(this._repo) : super(const LearningPathsState());
  final LearningPathRepository _repo;

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final page = await _repo.getLearningPaths(page: 1, difficulty: state.difficulty);
      state = state.copyWith(
        items: page.items, page: 1, hasMore: page.hasMore, loading: false,
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
      final page = await _repo.getLearningPaths(page: next, difficulty: state.difficulty);
      state = state.copyWith(
        items: [...state.items, ...page.items],
        page: next, hasMore: page.hasMore, loadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(loadingMore: false, error: e.toString());
    }
  }

  Future<void> setDifficulty(String? d) async {
    state = state.copyWith(
      difficulty: d, clearDifficulty: d == null,
      page: 0, items: const [], hasMore: true,
    );
    await load();
  }

  Future<void> toggleFavorite(String id) async {
    final item = state.items.firstWhere((p) => p.id == id);
    final newFav = !item.isFavorited;
    state = state.copyWith(items: [
      for (final p in state.items) p.id == id ? p.copyWith(isFavorited: newFav) : p,
    ]);
    try {
      await _repo.setFavorite(id, newFav);
    } catch (_) {
      state = state.copyWith(items: [
        for (final p in state.items) p.id == id ? p.copyWith(isFavorited: !newFav) : p,
      ]);
    }
  }
}

final learningPathsControllerProvider =
    StateNotifierProvider<LearningPathsController, LearningPathsState>((ref) {
  return LearningPathsController(ref.watch(learningPathRepositoryProvider));
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hot_ai_app/features/professions/domain/profession.dart';
import 'package:hot_ai_app/features/professions/domain/profession_repository.dart';

final professionRepositoryProvider = Provider<ProfessionRepository>((ref) {
  throw UnimplementedError('Override in main.dart');
});

class ProfessionsState {
  const ProfessionsState({
    this.items = const [],
    this.loading = false,
    this.loadingMore = false,
    this.page = 0,
    this.hasMore = true,
    this.riskLevel,
    this.error,
  });
  final List<Profession> items;
  final bool loading;
  final bool loadingMore;
  final int page;
  final bool hasMore;
  final String? riskLevel;
  final String? error;

  ProfessionsState copyWith({
    List<Profession>? items, bool? loading, bool? loadingMore,
    int? page, bool? hasMore, String? riskLevel, bool clearRiskLevel = false,
    String? error, bool clearError = false,
  }) => ProfessionsState(
        items: items ?? this.items,
        loading: loading ?? this.loading,
        loadingMore: loadingMore ?? this.loadingMore,
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
        riskLevel: clearRiskLevel ? null : (riskLevel ?? this.riskLevel),
        error: clearError ? null : (error ?? this.error),
      );
}

class ProfessionsController extends StateNotifier<ProfessionsState> {
  ProfessionsController(this._repo) : super(const ProfessionsState());
  final ProfessionRepository _repo;

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final page = await _repo.getProfessions(page: 1, riskLevel: state.riskLevel);
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
      final page = await _repo.getProfessions(page: next, riskLevel: state.riskLevel);
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

  Future<void> setRiskLevel(String? risk) async {
    state = state.copyWith(
      riskLevel: risk,
      clearRiskLevel: risk == null,
      page: 0,
      items: const [],
      hasMore: true,
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

final professionsControllerProvider =
    StateNotifierProvider<ProfessionsController, ProfessionsState>((ref) {
  return ProfessionsController(ref.watch(professionRepositoryProvider));
});

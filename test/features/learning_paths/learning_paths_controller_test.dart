import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/features/learning_paths/domain/learning_path.dart';
import 'package:hot_ai_app/features/learning_paths/domain/learning_path_repository.dart';
import 'package:hot_ai_app/features/learning_paths/domain/path_chapter.dart';
import 'package:hot_ai_app/features/learning_paths/presentation/learning_paths_controller.dart';
import 'package:hot_ai_app/shared/models/pagination.dart';

class _FakeRepo implements LearningPathRepository {
  final List<LearningPath> data;
  String? lastDifficulty;
  _FakeRepo(this.data);
  @override
  Future<Pagination<LearningPath>> getLearningPaths({required int page, String? difficulty}) async {
    lastDifficulty = difficulty;
    return Pagination(items: data, page: page, total: 1000);
  }
  @override
  Future<LearningPath> getLearningPath(String id) async => data.first;
  @override
  Future<List<PathChapter>> getChapters(String pathId) async => [];
  @override
  Future<PathChapter> getChapter(String chapterId) async => throw UnimplementedError();
  @override
  Future<void> setFavorite(String id, bool f) async {}
  @override
  Future<List<String>> getFavorites() async => [];
}

LearningPath _p(String id) => LearningPath(
      id: id, title: 'p$id', slug: 's', description: '', icon: null,
      difficulty: 'beginner', levelLabel: '入门', learningGoals: const [],
      targetAudience: const [], estimatedDays: 0, estimatedHours: 0,
      chapterCount: 0, studentCount: 0, coverImage: null, isFavorited: false,
    );

void main() {
  test('load 第一页', () async {
    final container = ProviderContainer(overrides: [
      learningPathRepositoryProvider.overrideWith((ref) => _FakeRepo([_p('1')])),
    ]);
    addTearDown(container.dispose);
    await container.read(learningPathsControllerProvider.notifier).load();
    final s = container.read(learningPathsControllerProvider);
    expect(s.items.length, 1);
    expect(s.loading, false);
  });

  test('loadMore 追加', () async {
    final container = ProviderContainer(overrides: [
      learningPathRepositoryProvider.overrideWith((ref) => _FakeRepo([_p('1')])),
    ]);
    addTearDown(container.dispose);
    await container.read(learningPathsControllerProvider.notifier).load();
    await container.read(learningPathsControllerProvider.notifier).loadMore();
    expect(container.read(learningPathsControllerProvider).items.length, 2);
  });

  test('setDifficulty 后 load 用新参数', () async {
    final repo = _FakeRepo([_p('1')]);
    final container = ProviderContainer(overrides: [
      learningPathRepositoryProvider.overrideWith((ref) => repo),
    ]);
    addTearDown(container.dispose);
    await container.read(learningPathsControllerProvider.notifier).setDifficulty('beginner');
    expect(repo.lastDifficulty, 'beginner');
  });

  test('toggleFavorite 失败回滚', () async {
    final container = ProviderContainer(overrides: [
      learningPathRepositoryProvider.overrideWith((ref) => _ThrowingRepo([_p('1')])),
    ]);
    addTearDown(container.dispose);
    await container.read(learningPathsControllerProvider.notifier).load();
    await container.read(learningPathsControllerProvider.notifier).toggleFavorite('1');
    expect(container.read(learningPathsControllerProvider).items.first.isFavorited, false);
  });
}

class _ThrowingRepo implements LearningPathRepository {
  _ThrowingRepo(this.data);
  final List<LearningPath> data;
  @override
  Future<Pagination<LearningPath>> getLearningPaths({required int page, String? difficulty}) async =>
      Pagination(items: data, page: page, total: 1000);
  @override
  Future<LearningPath> getLearningPath(String id) async => data.first;
  @override
  Future<List<PathChapter>> getChapters(String pathId) async => [];
  @override
  Future<PathChapter> getChapter(String chapterId) async => throw UnimplementedError();
  @override
  Future<void> setFavorite(String id, bool f) async => throw Exception('boom');
  @override
  Future<List<String>> getFavorites() async => [];
}

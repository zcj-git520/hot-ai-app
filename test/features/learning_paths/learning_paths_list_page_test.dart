import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/features/learning_paths/domain/learning_path.dart';
import 'package:hot_ai_app/features/learning_paths/domain/learning_path_repository.dart';
import 'package:hot_ai_app/features/learning_paths/domain/path_chapter.dart';
import 'package:hot_ai_app/features/learning_paths/presentation/learning_paths_controller.dart';
import 'package:hot_ai_app/features/learning_paths/presentation/learning_paths_list_page.dart';
import 'package:hot_ai_app/shared/models/pagination.dart';

class _FakeRepo implements LearningPathRepository {
  final List<LearningPath> data;
  _FakeRepo(this.data);
  @override
  Future<Pagination<LearningPath>> getLearningPaths({required int page, String? difficulty}) async =>
      Pagination(items: data, page: page, total: 1);
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

LearningPath _p(String id, {String title = 'p', String diff = 'beginner'}) {
  String label;
  switch (diff) {
    case 'beginner': label = '入门';
    case 'intermediate': label = '进阶';
    case 'advanced': label = '高级';
    default: label = '入门';
  }
  return LearningPath(
    id: id, title: title, slug: 's', description: 'desc',
    icon: '🤖', difficulty: diff, levelLabel: label,
    learningGoals: const [], targetAudience: const [],
    estimatedDays: 30, estimatedHours: 60,
    chapterCount: 5, studentCount: 100, coverImage: null, isFavorited: false,
  );
}

void main() {
  testWidgets('空态:显示 EmptyView', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [learningPathRepositoryProvider.overrideWith((ref) => _FakeRepo([]))],
      child: const MaterialApp(home: LearningPathsListPage()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('暂无学习路径'), findsOneWidget);
  });

  testWidgets('数据态:展示 1 条路径', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [learningPathRepositoryProvider.overrideWith((ref) => _FakeRepo([
        _p('1', title: 'AI 工程师之路'),
      ]))],
      child: const MaterialApp(home: LearningPathsListPage()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('AI 工程师之路'), findsOneWidget);
    expect(find.text('30 天 · 5 章 · 100 人学习'), findsOneWidget);
  });

  testWidgets('难度 chip 4 个 + 全部', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [learningPathRepositoryProvider.overrideWith((ref) => _FakeRepo([_p('1', diff: 'advanced')]))],
      child: const MaterialApp(home: LearningPathsListPage()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('全部'), findsOneWidget);
    expect(find.text('入门'), findsOneWidget);
    expect(find.text('进阶'), findsOneWidget);
    expect(find.text('高级'), findsNWidgets(2));
  });
}

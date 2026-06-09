import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/features/learning_paths/domain/learning_path.dart';
import 'package:hot_ai_app/features/learning_paths/domain/learning_path_repository.dart';
import 'package:hot_ai_app/features/learning_paths/domain/path_chapter.dart';
import 'package:hot_ai_app/features/learning_paths/presentation/chapter_detail_page.dart';
import 'package:hot_ai_app/features/learning_paths/presentation/learning_paths_controller.dart';
import 'package:hot_ai_app/shared/models/pagination.dart';

class _FakeRepo implements LearningPathRepository {
  final PathChapter c;
  _FakeRepo(this.c);
  @override
  Future<Pagination<LearningPath>> getLearningPaths({required int page, String? difficulty}) async =>
      Pagination(items: const [], page: 1, total: 0);
  @override
  Future<LearningPath> getLearningPath(String id) async => throw UnimplementedError();
  @override
  Future<List<PathChapter>> getChapters(String pathId) async => [c];
  @override
  Future<PathChapter> getChapter(String chapterId) async => c;
  @override
  Future<void> setFavorite(String id, bool f) async {}
  @override
  Future<List<String>> getFavorites() async => [];
}

PathChapter _c() => PathChapter(
      id: '5', pathId: '1', title: 'Prompt 基础', slug: 's',
      description: 'd', contentType: 'article',
      content: '<p>第一章正文</p>', videoUrl: null,
      estimatedHours: 2, orderIndex: 1, isFree: true,
    );

void main() {
  testWidgets('展示章节标题 + HTML 内容(渲染无错)', (tester) async {
    final c = _c();
    await tester.pumpWidget(ProviderScope(
      overrides: [learningPathRepositoryProvider.overrideWith((ref) => _FakeRepo(c))],
      child: const MaterialApp(home: ChapterDetailPage(pathId: '1', chapterId: '5')),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Prompt 基础'), findsOneWidget);
    expect(find.text('第 1 章'), findsOneWidget);
    expect(find.text('免费'), findsOneWidget);
    expect(find.text('2 小时'), findsOneWidget);
    // HtmlWidget 内部用 RichText 渲染,这里只验证不抛异常即可
    expect(tester.takeException(), isNull);
  });
}

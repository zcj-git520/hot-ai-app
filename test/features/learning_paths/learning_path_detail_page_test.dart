import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hot_ai_app/features/learning_paths/domain/learning_path.dart';
import 'package:hot_ai_app/features/learning_paths/domain/learning_path_repository.dart';
import 'package:hot_ai_app/features/learning_paths/domain/path_chapter.dart';
import 'package:hot_ai_app/features/learning_paths/presentation/learning_path_detail_page.dart';
import 'package:hot_ai_app/features/learning_paths/presentation/learning_paths_controller.dart';
import 'package:hot_ai_app/shared/models/pagination.dart';

class _FakeRepo implements LearningPathRepository {
  final LearningPath p;
  _FakeRepo(this.p);
  @override
  Future<Pagination<LearningPath>> getLearningPaths({required int page, String? difficulty}) async =>
      Pagination(items: [p], page: 1, total: 1);
  @override
  Future<LearningPath> getLearningPath(String id) async => p;
  @override
  Future<List<PathChapter>> getChapters(String pathId) async => p.chapters;
  @override
  Future<PathChapter> getChapter(String chapterId) async => p.chapters.first;
  @override
  Future<void> setFavorite(String id, bool f) async {}
  @override
  Future<List<String>> getFavorites() async => [];
}

LearningPath _p() => LearningPath(
      id: '1', title: 'AI 工程师之路', slug: 's', description: 'desc',
      icon: '🤖', difficulty: 'intermediate', levelLabel: '进阶',
      learningGoals: const ['掌握 LLM'], targetAudience: const ['开发者'],
      estimatedDays: 90, estimatedHours: 180,
      chapterCount: 2, studentCount: 1024, coverImage: null, isFavorited: false,
      chapters: [
        PathChapter(id: '5', pathId: '1', title: 'Prompt 基础', slug: 's',
          description: 'd', contentType: 'article', content: '<p>x</p>',
          videoUrl: null, estimatedHours: 2, orderIndex: 1, isFree: true),
        PathChapter(id: '6', pathId: '1', title: 'RAG 入门', slug: 's',
          description: 'd', contentType: 'article', content: '<p>y</p>',
          videoUrl: null, estimatedHours: 3, orderIndex: 2, isFree: false),
      ],
    );

void main() {
  testWidgets('展示基础字段 + 章节列表', (tester) async {
    final p = _p();
    await tester.pumpWidget(ProviderScope(
      overrides: [learningPathRepositoryProvider.overrideWith((ref) => _FakeRepo(p))],
      child: const MaterialApp(home: LearningPathDetailPage(id: '1')),
    ));
    await tester.pumpAndSettle();
    expect(find.text('AI 工程师之路'), findsOneWidget);
    expect(find.text('进阶 · 90 天 · 180 小时'), findsOneWidget);
    expect(find.textContaining('Prompt 基础'), findsOneWidget);
    expect(find.textContaining('RAG 入门'), findsOneWidget);
  });

  testWidgets('点击章节跳转 /learning-paths/1/chapters/5', (tester) async {
    final p = _p();
    final router = GoRouter(
      initialLocation: '/learning-paths/1',
      routes: [
        GoRoute(
          path: '/learning-paths/:id',
          builder: (ctx, state) => LearningPathDetailPage(id: state.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'chapters/:chapterId',
              builder: (ctx, state) => Scaffold(
                appBar: AppBar(title: Text('chapter ${state.pathParameters['chapterId']}')),
              ),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [learningPathRepositoryProvider.overrideWith((ref) => _FakeRepo(p))],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Prompt 基础'));
    await tester.pumpAndSettle();
    expect(find.textContaining('chapter 5'), findsOneWidget);
  });
}

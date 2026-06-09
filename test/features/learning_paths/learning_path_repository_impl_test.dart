import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/core/storage/hive_init.dart';
import 'package:hot_ai_app/features/learning_paths/data/learning_path_repository_impl.dart';

void main() {
  late Directory tmp;
  late AppBoxes boxes;
  late LearningPathRepositoryImpl repo;

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync();
    boxes = await openAppBoxes(path: tmp.path);
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com'))
      ..httpClientAdapter = _StubAdapter();
    repo = LearningPathRepositoryImpl(dio: dio, boxes: boxes);
  });

  tearDown(() async {
    await boxes.closeAll();
    await tmp.delete(recursive: true);
  });

  test('getLearningPaths 解析列表', () async {
    final page = await repo.getLearningPaths(page: 1, difficulty: null);
    expect(page.items.length, 2);
    expect(page.items.first.title, 'AI 工程师');
    expect(page.items.first.difficulty, 'intermediate');
  });

  test('getLearningPaths 写入 learning_paths_cache box', () async {
    await repo.getLearningPaths(page: 1, difficulty: null);
    expect(boxes.learningPathsCache.keys, contains('1'));
  });

  test('getLearningPaths 带 difficulty 过滤', () async {
    final page = await repo.getLearningPaths(page: 1, difficulty: 'beginner');
    expect(page.items.length, 1);
    expect(page.items.first.title, '入门 Prompt');
  });

  test('getLearningPath 详情(包含 chapters)', () async {
    final p = await repo.getLearningPath('1');
    expect(p.title, 'AI 工程师');
    expect(p.chapters.length, 2);
    expect(p.chapters.first.title, 'Prompt 基础');
  });

  test('getChapters 独立拉取', () async {
    final chapters = await repo.getChapters('1');
    expect(chapters.length, 2);
  });

  test('getChapter 单章节', () async {
    final c = await repo.getChapter('5');
    expect(c.title, 'Prompt 基础');
    expect(c.content.contains('<p>'), true);
  });

  test('getLearningPath 命中缓存时立刻返回', () async {
    await boxes.learningPathsCache.put('1', {
      'id': 1, 'title': 'cached', 'slug': 's', 'description': 'd',
      'icon': null, 'difficulty': 'beginner', 'level_label': '入门',
      'learning_goals': [], 'target_audience': [],
      'estimated_days': 0, 'estimated_hours': 0,
      'chapter_count': 0, 'student_count': 0,
      'cover_image': null, 'isFavorited': false, 'chapters': [],
    });
    final p = await repo.getLearningPath('1');
    expect(p.title, 'cached');
  });

  test('setFavorite 写 user_state', () async {
    await repo.setFavorite('1', true);
    expect(await repo.getFavorites(), ['1']);
    await repo.setFavorite('1', false);
    expect(await repo.getFavorites(), isEmpty);
  });
}

class _StubAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<List<int>>? s, Future<void>? c) async {
    if (o.path == '/learning-paths') {
      final diff = o.queryParameters['difficulty'];
      if (diff == 'beginner') {
        return _ok({'page': 1, 'total': 1, 'items': [_pathJson(2, '入门 Prompt', 'beginner', '入门')]});
      }
      return _ok({
        'page': 1, 'total': 25, 'items': [
          _pathJson(1, 'AI 工程师', 'intermediate', '进阶'),
          _pathJson(3, 'RAG 实战', 'advanced', '高级'),
        ],
      });
    }
    if (o.path == '/learning-paths/1') {
      return _ok(_pathJsonWithChapters(1, 'AI 工程师', 'intermediate', '进阶'));
    }
    if (o.path == '/learning-paths/1/chapters') {
      return _ok({'items': [_chapterJson(5), _chapterJson(6)]});
    }
    if (o.path == '/chapters/5') {
      return _ok(_chapterJson(5));
    }
    if (o.path == '/learning-paths/1/favorite') {
      return _ok({'ok': true});
    }
    return _ok({});
  }

  Map<String, dynamic> _pathJson(int id, String title, String diff, String level) => {
        'id': id, 'title': title, 'slug': 's$id', 'description': 'd',
        'icon': '🤖', 'difficulty': diff, 'level_label': level,
        'learning_goals': ['g1'], 'target_audience': ['a1'],
        'estimated_days': 30, 'estimated_hours': 60,
        'chapter_count': 5, 'student_count': 100,
        'cover_image': null, 'isFavorited': false,
      };

  Map<String, dynamic> _pathJsonWithChapters(int id, String title, String diff, String level) => {
        ..._pathJson(id, title, diff, level),
        'chapters': [_chapterJson(5), _chapterJson(6)],
      };

  Map<String, dynamic> _chapterJson(int id) => {
        'id': id, 'path_id': 1,
        'title': id == 5 ? 'Prompt 基础' : 'RAG 入门',
        'slug': 's$id', 'description': 'd',
        'content_type': 'article', 'content': '<p>content $id</p>',
        'video_url': null, 'estimated_hours': 2,
        'order_index': id, 'is_free': 1,
      };

  ResponseBody _ok(dynamic data) => ResponseBody.fromString(
        '{"code":0,"data":${json.encode(data)},"message":"ok"}',
        200,
        headers: {Headers.contentTypeHeader: ['application/json']},
      );

  @override
  void close({bool force = false}) {}
}

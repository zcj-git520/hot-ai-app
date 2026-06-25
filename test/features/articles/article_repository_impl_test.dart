import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/core/storage/hive_init.dart';
import 'package:hot_ai_app/features/articles/data/article_repository_impl.dart';
import 'dart:io';

void main() {
  late Directory tmp;
  late AppBoxes boxes;
  late ArticleRepositoryImpl repo;

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync();
    boxes = await openAppBoxes(path: tmp.path);
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com'))
      ..httpClientAdapter = _StubAdapter();
    repo = ArticleRepositoryImpl(dio: dio, boxes: boxes);
  });

  tearDown(() async {
    await boxes.closeAll();
    await tmp.delete(recursive: true);
  });

  test('getArticles 解析 ApiResponse<Pagination>', () async {
    final page = await repo.getArticles(page: 1, category: null);
    expect(page.items.length, 2);
    expect(page.items.first.title, 'A1');
  });

  test('getArticles 同时写入 articles_meta box', () async {
    await repo.getArticles(page: 1, category: null);
    final ids = boxes.articlesMeta.keys;
    expect(ids, contains('1'));
  });

  test('getArticle 命中缓存时立刻返回', () async {
    await boxes.articleDetails.put('a1', {
      'id': '1', 'title': 'cached', 'summary': '', 'contentHtml': '',
      'coverUrl': null, 'publishedAt': DateTime.now().toIso8601String(),
      'category': '', 'isFavorited': false,
    });
    final a = await repo.getArticle('a1');
    expect(a.title, 'cached');
  });
}

class _StubAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<List<int>>? s, Future<void>? c) async {
    if (o.path == '/articles') {
      return ResponseBody.fromString(
        '{"code":0,"data":{"page":1,"total":2,"articles":[{"id":1,"title":"A1","summary":"s1","content":"c1","cover_url":null,"published_at":"2026-06-09T00:00:00Z","category_name":"x","is_favorited":false},{"id":2,"title":"A2","summary":"s2","content":"c2","cover_url":null,"published_at":"2026-06-09T00:00:00Z","category_name":"x","is_favorited":false}]},"message":"ok"}',
        200,
        headers: {Headers.contentTypeHeader: ['application/json']},
      );
    }
    if (o.path.startsWith('/articles/')) {
      return ResponseBody.fromString(
        '{"code":0,"data":{"id":1,"title":"refreshed","summary":"","content":"<p>c</p>","cover_url":null,"published_at":"2026-06-09T00:00:00Z","category_name":"x","is_favorited":false},"message":"ok"}',
        200,
        headers: {Headers.contentTypeHeader: ['application/json']},
      );
    }
    return ResponseBody.fromString('{"code":0,"data":{},"message":"ok"}', 200, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }
  @override
  void close({bool force = false}) {}
}

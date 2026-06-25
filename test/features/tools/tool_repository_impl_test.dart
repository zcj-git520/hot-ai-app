import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/core/storage/hive_init.dart';
import 'package:hot_ai_app/features/tools/data/tool_repository_impl.dart';

void main() {
  late Directory tmp;
  late AppBoxes boxes;
  late ToolRepositoryImpl repo;

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync();
    boxes = await openAppBoxes(path: tmp.path);
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com'))
      ..httpClientAdapter = _StubAdapter();
    repo = ToolRepositoryImpl(dio: dio, boxes: boxes);
  });

  tearDown(() async {
    await boxes.closeAll();
    await tmp.delete(recursive: true);
  });

  test('getCategories 解析', () async {
    final cats = await repo.getCategories();
    expect(cats.length, 2);
    expect(cats.first.name, '代码助手');
  });

  test('getCategories 写入 tools_cache box(\"__categories__\" key)', () async {
    await repo.getCategories();
    final cached = boxes.toolsCache.get('__categories__');
    expect(cached, isNotNull);
  });

  test('getTools 列表 + 写入 cache', () async {
    final page = await repo.getTools(page: 1);
    expect(page.items.length, 2);
    expect(page.items.first.name, 'Cursor');
    expect(boxes.toolsCache.keys, containsAll(['cursor', 'gpt']));
  });

  test('getTools 带 category_id 过滤', () async {
    final page = await repo.getTools(page: 1, categoryId: 2);
    expect(page.items.length, 1);
    expect(page.items.first.name, 'Midjourney');
  });

  test('getTools 带 search', () async {
    final page = await repo.getTools(page: 1, search: 'cursor');
    expect(page.items.length, 1);
    expect(page.items.first.name, 'Cursor');
  });

  test('getTool 详情(by slug)', () async {
    final t = await repo.getTool('cursor');
    expect(t.name, 'Cursor');
    expect(t.tags.length, 2);
  });

  test('getTool 命中缓存', () async {
    await boxes.toolsCache.put('cursor', _toolJson('Cursor', 'cursor', tags: ['cached']));
    final t = await repo.getTool('cursor');
    expect(t.tags, ['cached']);
  });

  test('setFavorite 写 user_state.tool_favorites', () async {
    await repo.setFavorite('1', true);
    expect(await repo.getFavorites(), ['1']);
    await repo.setFavorite('1', false);
    expect(await repo.getFavorites(), isEmpty);
  });
}

Map<String, dynamic> _toolJson(String name, String slug, {List<String>? tags}) => {
      'id': 1, 'name': name, 'slug': slug, 'description': 'd', 'icon': '🖱',
      'official_url': 'https://x', 'documentation_url': '', 'pricing': 'free',
      'pricing_description': '', 'category_id': 1, 'difficulty': 'beginner',
      'rating': 4.5, 'review_count': 100, 'view_count': 1000, 'popularity': 50,
      'tags': tags ?? ['AI'], 'featured': true, 'status': 1, 'is_online': true,
      'isFavorited': false,
    };

class _StubAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<List<int>>? s, Future<void>? c) async {
    if (o.path == '/tools/categories') {
      return _ok([
        {'id': 1, 'name': '代码助手', 'slug': 'code', 'icon': '💻',
         'description': 'd', 'sort_order': 1, 'featured': true},
        {'id': 2, 'name': '图像生成', 'slug': 'image', 'icon': '🎨',
         'description': 'd', 'sort_order': 2, 'featured': false},
      ]);
    }
    if (o.path == '/tools') {
      final cat = o.queryParameters['category_id'];
      final search = o.queryParameters['search'];
      if (search == 'cursor') {
        return _ok({'page': 1, 'total': 1, 'list': [_toolJson('Cursor', 'cursor', tags: ['AI', 'IDE'])]});
      }
      if (cat == 2 || cat == '2') {
        return _ok({'page': 1, 'total': 1, 'list': [_toolJson('Midjourney', 'mj', tags: ['AI', '图像'])]});
      }
      return _ok({
        'page': 1, 'total': 25, 'list': [
          _toolJson('Cursor', 'cursor', tags: ['AI', 'IDE']),
          _toolJson('ChatGPT', 'gpt', tags: ['AI', '对话']),
        ],
      });
    }
    if (o.path == '/tools/cursor') {
      return _ok(_toolJson('Cursor', 'cursor', tags: ['AI', 'IDE']));
    }
    if (o.path == '/tools/1/favorite') {
      return _ok({'ok': true});
    }
    return _ok({});
  }

  ResponseBody _ok(dynamic data) => ResponseBody.fromString(
        '{"code":0,"data":${json.encode(data)},"message":"ok"}',
        200,
        headers: {Headers.contentTypeHeader: ['application/json']},
      );

  @override
  void close({bool force = false}) {}
}

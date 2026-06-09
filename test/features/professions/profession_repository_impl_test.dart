import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/core/storage/hive_init.dart';
import 'package:hot_ai_app/features/professions/data/profession_repository_impl.dart';

void main() {
  late Directory tmp;
  late AppBoxes boxes;
  late ProfessionRepositoryImpl repo;

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync();
    boxes = await openAppBoxes(path: tmp.path);
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com'))
      ..httpClientAdapter = _StubAdapter();
    repo = ProfessionRepositoryImpl(dio: dio, boxes: boxes);
  });

  tearDown(() async {
    await boxes.closeAll();
    await tmp.delete(recursive: true);
  });

  test('getProfessions 解析 ApiResponse<Pagination>', () async {
    final page = await repo.getProfessions(page: 1, riskLevel: null);
    expect(page.items.length, 2);
    expect(page.items.first.name, '软件工程师');
    expect(page.items.first.riskLevel, 'medium');
    expect(page.hasMore, true);
  });

  test('getProfessions 写入 professions_cache box', () async {
    await repo.getProfessions(page: 1, riskLevel: null);
    expect(boxes.professionsCache.keys, contains('1'));
  });

  test('getProfessions 带 risk_level 参数', () async {
    final page = await repo.getProfessions(page: 1, riskLevel: 'high');
    expect(page.items.length, 1);
    expect(page.items.first.name, '客服');
  });

  test('getProfession 详情返回含 impact/advice/market', () async {
    final p = await repo.getProfession('1');
    expect(p.name, '软件工程师');
    expect(p.impactAnalysis, isNotNull);
    expect(p.impactAnalysis!.affectedTasks, ['CRUD 代码']);
    expect(p.transitionAdvice, isNotNull);
    expect(p.marketData, isNotNull);
  });

  test('getProfession 命中缓存时立刻返回', () async {
    await boxes.professionsCache.put('1', {
      'id': 1, 'name': 'cached', 'slug': 's', 'description': 'd',
      'icon': null, 'category_id': null, 'category_name': null,
      'risk_level': 'low', 'risk_score': 10, 'automation_rate': 5,
      'isFavorited': false,
    });
    final p = await repo.getProfession('1');
    expect(p.name, 'cached');
  });

  test('setFavorite 写 user_state.favorites', () async {
    await repo.setFavorite('1', true);
    final favs = await repo.getFavorites();
    expect(favs, ['1']);
    await repo.setFavorite('1', false);
    expect(await repo.getFavorites(), isEmpty);
  });
}

class _StubAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<List<int>>? s, Future<void>? c) async {
    if (o.path == '/professions') {
      final riskLevel = o.queryParameters['risk_level'];
      if (riskLevel == 'high') {
        return _ok({
          'page': 1, 'total': 1, 'items': [
            {'id': 3, 'name': '客服', 'slug': 'cs', 'description': 'd',
             'icon': null, 'category_id': null, 'category_name': null,
             'risk_level': 'high', 'risk_score': 80, 'automation_rate': 90},
          ],
        });
      }
      return _ok({
        'page': 1, 'total': 25, 'items': [
          {'id': 1, 'name': '软件工程师', 'slug': 'se', 'description': 'd',
           'icon': '💻', 'category_id': 1, 'category_name': '技术',
           'risk_level': 'medium', 'risk_score': 55, 'automation_rate': 60},
          {'id': 2, 'name': '设计师', 'slug': 'd', 'description': 'd',
           'icon': '🎨', 'category_id': 2, 'category_name': '设计',
           'risk_level': 'low', 'risk_score': 20, 'automation_rate': 10},
        ],
      });
    }
    if (o.path == '/professions/1') {
      return _ok({
        'id': 1, 'name': '软件工程师', 'slug': 'se', 'description': 'desc',
        'icon': '💻', 'category_id': 1, 'category_name': '技术',
        'risk_level': 'medium', 'risk_score': 55, 'automation_rate': 60,
        'impact_analysis': {
          'affected_tasks': ['CRUD 代码'],
          'safe_tasks': ['架构'],
          'safe_skills': ['系统设计'],
          'impact_summary': '中级风险',
        },
        'transition_advice': {
          'transition_paths': ['AI 工程师'],
          'recommended_skills': ['Prompt'],
          'recommended_tools': ['Cursor'],
          'advice_summary': '建议',
        },
        'market_data': {
          'market_trend': 'stable',
          'avg_salary': 25000,
          'salary_change_rate': 1.5,
          'job_demand_trend': '持平',
          'supply_demand_ratio': 1.2,
        },
      });
    }
    if (o.path == '/professions/1/favorite') {
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

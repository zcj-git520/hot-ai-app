import 'dart:async';
import 'package:dio/dio.dart';
import 'package:hot_ai_app/core/network/api_response.dart';
import 'package:hot_ai_app/core/storage/hive_init.dart';
import 'package:hot_ai_app/features/tools/domain/tool.dart';
import 'package:hot_ai_app/features/tools/domain/tool_category.dart';
import 'package:hot_ai_app/features/tools/domain/tool_repository.dart';
import 'package:hot_ai_app/shared/models/pagination.dart';

class ToolRepositoryImpl implements ToolRepository {
  ToolRepositoryImpl({required this.dio, required this.boxes});
  final Dio dio;
  final AppBoxes boxes;

  @override
  Future<List<ToolCategory>> getCategories() async {
    final resp = await dio.get('/tools/categories');
    final data = ApiResponse.fromJson<Map<String, dynamic>>(
      resp.data as Map<String, dynamic>, (j) => j as Map<String, dynamic>).unwrap();
    final cats = (data['items'] as List).cast<Map<String, dynamic>>()
      .map(ToolCategory.fromJson).toList();
    await boxes.toolsCache.put('__categories__', cats.map((c) => c.toJson()).toList());
    return cats;
  }

  @override
  Future<Pagination<Tool>> getTools({required int page, int? categoryId, String? search}) async {
    final resp = await dio.get('/tools', queryParameters: {
      'page': page,
      if (categoryId != null) 'category_id': categoryId,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    final data = ApiResponse.fromJson<Map<String, dynamic>>(
      resp.data as Map<String, dynamic>, (j) => j as Map<String, dynamic>).unwrap();
    final items = (data['items'] as List).cast<Map<String, dynamic>>()
      .map(Tool.fromJson).toList();
    for (final t in items) {
      await boxes.toolsCache.put(t.slug, t.toJson());
    }
    return Pagination<Tool>(
      items: items, page: data['page'] as int, total: data['total'] as int,
    );
  }

  @override
  Future<Tool> getTool(String slug) async {
    final cached = boxes.toolsCache.get(slug);
    if (cached != null) {
      unawaited(_refresh(slug));
      return Tool.fromJson((cached as Map).cast<String, dynamic>());
    }
    return _refresh(slug);
  }

  Future<Tool> _refresh(String slug) async {
    final resp = await dio.get('/tools/$slug');
    final data = ApiResponse.fromJson<Map<String, dynamic>>(
      resp.data as Map<String, dynamic>, (j) => j as Map<String, dynamic>).unwrap();
    final t = Tool.fromJson(data);
    await boxes.toolsCache.put(slug, t.toJson());
    return t;
  }

  @override
  Future<void> setFavorite(String id, bool favorite) async {
    try {
      await dio.post('/tools/$id/favorite', data: {'favorite': favorite});
    } on DioException {
      // 后端可能未实现,优雅降级
    }
    final list = (boxes.userState.get('tool_favorites') as List?)?.cast<String>() ?? <String>[];
    final next = favorite
        ? (list.toSet()..add(id)).toList()
        : list.where((x) => x != id).toList();
    await boxes.userState.put('tool_favorites', next);
  }

  @override
  Future<List<String>> getFavorites() async {
    return (boxes.userState.get('tool_favorites') as List?)?.cast<String>() ?? <String>[];
  }
}

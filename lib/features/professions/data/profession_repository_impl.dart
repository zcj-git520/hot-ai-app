import 'dart:async';
import 'package:dio/dio.dart';
import 'package:hot_ai_app/core/network/api_response.dart';
import 'package:hot_ai_app/core/storage/hive_init.dart';
import 'package:hot_ai_app/features/professions/domain/profession.dart';
import 'package:hot_ai_app/features/professions/domain/profession_repository.dart';
import 'package:hot_ai_app/shared/models/pagination.dart';

class ProfessionRepositoryImpl implements ProfessionRepository {
  ProfessionRepositoryImpl({required this.dio, required this.boxes});
  final Dio dio;
  final AppBoxes boxes;

  @override
  Future<Pagination<Profession>> getProfessions({required int page, String? riskLevel}) async {
    final resp = await dio.get('/professions', queryParameters: {
      'page': page,
      if (riskLevel != null) 'risk_level': riskLevel,
    });
    final data = ApiResponse.fromJson<Map<String, dynamic>>(
      resp.data as Map<String, dynamic>, (j) => j as Map<String, dynamic>).unwrap();
    final items = (data['items'] as List).cast<Map<String, dynamic>>()
      .map(Profession.fromJson).toList();
    for (final p in items) {
      await boxes.professionsCache.put(p.id, p.toJson());
    }
    return Pagination<Profession>(
      items: items,
      page: data['page'] as int,
      total: data['total'] as int,
    );
  }

  @override
  Future<Profession> getProfession(String id) async {
    final cached = boxes.professionsCache.get(id);
    if (cached != null) {
      unawaited(_refresh(id));
      return Profession.fromJson((cached as Map).cast<String, dynamic>());
    }
    return _refresh(id);
  }

  Future<Profession> _refresh(String id) async {
    final resp = await dio.get('/professions/$id');
    final data = ApiResponse.fromJson<Map<String, dynamic>>(
      resp.data as Map<String, dynamic>, (j) => j as Map<String, dynamic>).unwrap();
    final p = Profession.fromJson(data);
    await boxes.professionsCache.put(id, p.toJson());
    return p;
  }

  @override
  Future<void> setFavorite(String id, bool favorite) async {
    try {
      await dio.post('/professions/$id/favorite', data: {'favorite': favorite});
    } on DioException {
      // 后端可能尚未实现 /professions/:id/favorite,优雅降级
    }
    final list = (boxes.userState.get('favorites') as List?)?.cast<String>() ?? <String>[];
    final next = favorite
        ? (list.toSet()..add(id)).toList()
        : list.where((x) => x != id).toList();
    await boxes.userState.put('profession_favorites', next);
  }

  @override
  Future<List<String>> getFavorites() async {
    return (boxes.userState.get('profession_favorites') as List?)?.cast<String>() ?? <String>[];
  }
}

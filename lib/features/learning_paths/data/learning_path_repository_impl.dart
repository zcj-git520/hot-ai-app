import 'dart:async';
import 'package:dio/dio.dart';
import 'package:hot_ai_app/core/network/api_response.dart';
import 'package:hot_ai_app/core/storage/hive_init.dart';
import 'package:hot_ai_app/features/learning_paths/domain/learning_path.dart';
import 'package:hot_ai_app/features/learning_paths/domain/learning_path_repository.dart';
import 'package:hot_ai_app/features/learning_paths/domain/path_chapter.dart';
import 'package:hot_ai_app/shared/models/pagination.dart';

class LearningPathRepositoryImpl implements LearningPathRepository {
  LearningPathRepositoryImpl({required this.dio, required this.boxes});
  final Dio dio;
  final AppBoxes boxes;

  @override
  Future<Pagination<LearningPath>> getLearningPaths({required int page, String? difficulty}) async {
    final resp = await dio.get('/learning-paths', queryParameters: {
      'page': page,
      if (difficulty != null) 'difficulty': difficulty,
    });
    final data = ApiResponse.fromJson<Map<String, dynamic>>(
      resp.data as Map<String, dynamic>, (j) => j as Map<String, dynamic>).unwrap();
    final items = (data['items'] as List).cast<Map<String, dynamic>>()
      .map(LearningPath.fromJson).toList();
    for (final p in items) {
      await boxes.learningPathsCache.put(p.id, p.toJson());
    }
    return Pagination<LearningPath>(
      items: items, page: data['page'] as int, total: data['total'] as int,
    );
  }

  @override
  Future<LearningPath> getLearningPath(String id) async {
    final cached = boxes.learningPathsCache.get(id);
    if (cached != null) {
      unawaited(_refresh(id));
      return LearningPath.fromJson((cached as Map).cast<String, dynamic>());
    }
    return _refresh(id);
  }

  Future<LearningPath> _refresh(String id) async {
    final resp = await dio.get('/learning-paths/$id');
    final data = ApiResponse.fromJson<Map<String, dynamic>>(
      resp.data as Map<String, dynamic>, (j) => j as Map<String, dynamic>).unwrap();
    final p = LearningPath.fromJson(data);
    await boxes.learningPathsCache.put(id, p.toJson());
    return p;
  }

  @override
  Future<List<PathChapter>> getChapters(String pathId) async {
    final resp = await dio.get('/learning-paths/$pathId/chapters');
    final data = ApiResponse.fromJson<Map<String, dynamic>>(
      resp.data as Map<String, dynamic>, (j) => j as Map<String, dynamic>).unwrap();
    return (data['items'] as List).cast<Map<String, dynamic>>()
      .map(PathChapter.fromJson).toList();
  }

  @override
  Future<PathChapter> getChapter(String chapterId) async {
    final resp = await dio.get('/chapters/$chapterId');
    final data = ApiResponse.fromJson<Map<String, dynamic>>(
      resp.data as Map<String, dynamic>, (j) => j as Map<String, dynamic>).unwrap();
    return PathChapter.fromJson(data);
  }

  @override
  Future<void> setFavorite(String id, bool favorite) async {
    try {
      await dio.post('/learning-paths/$id/favorite', data: {'favorite': favorite});
    } on DioException {
      // 后端可能尚未实现
    }
    final list = (boxes.userState.get('learning_path_favorites') as List?)?.cast<String>() ?? <String>[];
    final next = favorite
        ? (list.toSet()..add(id)).toList()
        : list.where((x) => x != id).toList();
    await boxes.userState.put('learning_path_favorites', next);
  }

  @override
  Future<List<String>> getFavorites() async {
    return (boxes.userState.get('learning_path_favorites') as List?)?.cast<String>() ?? <String>[];
  }
}

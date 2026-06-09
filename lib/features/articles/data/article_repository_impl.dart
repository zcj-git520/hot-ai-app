import 'dart:async';
import 'package:dio/dio.dart';
import 'package:hot_ai_app/core/network/api_response.dart';
import 'package:hot_ai_app/core/storage/hive_init.dart';
import 'package:hot_ai_app/features/articles/domain/article.dart';
import 'package:hot_ai_app/features/articles/domain/article_repository.dart';
import 'package:hot_ai_app/shared/models/pagination.dart';

class ArticleRepositoryImpl implements ArticleRepository {
  ArticleRepositoryImpl({required this.dio, required this.boxes});
  final Dio dio;
  final AppBoxes boxes;

  @override
  Future<Pagination<Article>> getArticles({required int page, String? category}) async {
    final resp = await dio.get('/articles', queryParameters: {
      'page': page, if (category != null) 'category': category,
    });
    final data = ApiResponse.fromJson<Map<String, dynamic>>(
      resp.data as Map<String, dynamic>, (j) => j as Map<String, dynamic>).unwrap();
    final items = (data['items'] as List).cast<Map<String, dynamic>>()
      .map(Article.fromJson).toList();
    for (final a in items) {
      await boxes.articlesMeta.put(a.id, a.toJson());
    }
    return Pagination<Article>(
      items: items,
      page: data['page'] as int,
      total: data['total'] as int,
    );
  }

  @override
  Future<Article> getArticle(String id) async {
    final cached = boxes.articleDetails.get(id);
    if (cached != null) {
      // 后台异步刷新
      unawaited(_refresh(id));
      return Article.fromJson((cached as Map).cast<String, dynamic>());
    }
    return _refresh(id);
  }

  Future<Article> _refresh(String id) async {
    final resp = await dio.get('/articles/$id');
    final data = ApiResponse.fromJson<Map<String, dynamic>>(
      resp.data as Map<String, dynamic>, (j) => j as Map<String, dynamic>).unwrap();
    final article = Article.fromJson(data);
    await boxes.articleDetails.put(id, article.toJson());
    return article;
  }

  @override
  Future<void> setFavorite(String id, bool favorite) async {
    await dio.post('/articles/$id/favorite', data: {'favorite': favorite});
    final list = (boxes.userState.get('favorites') as List?)?.cast<String>() ?? <String>[];
    final next = favorite
        ? (list.toSet()..add(id)).toList()
        : (list.where((x) => x != id).toList());
    await boxes.userState.put('favorites', next);
  }

  @override
  Future<List<String>> getFavorites() async {
    return (boxes.userState.get('favorites') as List?)?.cast<String>() ?? <String>[];
  }
}

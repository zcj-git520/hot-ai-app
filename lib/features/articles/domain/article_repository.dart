import 'package:hot_ai_app/features/articles/domain/article.dart';
import 'package:hot_ai_app/shared/models/pagination.dart';

abstract class ArticleRepository {
  Future<Pagination<Article>> getArticles({required int page, String? category});
  Future<Article> getArticle(String id);
  Future<void> setFavorite(String id, bool favorite);
  Future<List<String>> getFavorites();
}

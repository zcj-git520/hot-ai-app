import 'package:hot_ai_app/features/tools/domain/tool.dart';
import 'package:hot_ai_app/features/tools/domain/tool_category.dart';
import 'package:hot_ai_app/shared/models/pagination.dart';

abstract class ToolRepository {
  Future<List<ToolCategory>> getCategories();
  Future<Pagination<Tool>> getTools({required int page, int? categoryId, String? search});
  Future<Tool> getTool(String slug);
  Future<void> setFavorite(String id, bool favorite);
  Future<List<String>> getFavorites();
}

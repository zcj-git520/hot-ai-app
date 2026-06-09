import 'package:hot_ai_app/features/learning_paths/domain/learning_path.dart';
import 'package:hot_ai_app/features/learning_paths/domain/path_chapter.dart';
import 'package:hot_ai_app/shared/models/pagination.dart';

abstract class LearningPathRepository {
  Future<Pagination<LearningPath>> getLearningPaths({required int page, String? difficulty});
  Future<LearningPath> getLearningPath(String id);
  Future<List<PathChapter>> getChapters(String pathId);
  Future<PathChapter> getChapter(String chapterId);
  Future<void> setFavorite(String id, bool favorite);
  Future<List<String>> getFavorites();
}

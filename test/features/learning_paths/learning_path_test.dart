import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/features/learning_paths/domain/learning_path.dart';
import 'package:hot_ai_app/features/learning_paths/domain/path_chapter.dart';

void main() {
  test('LearningPath.fromJson 解析基础字段', () {
    final p = LearningPath.fromJson({
      'id': 1, 'title': 'AI 工程师之路', 'slug': 'ai-engineer',
      'description': '从零到 AI 工程师', 'icon': '🤖',
      'difficulty': 'intermediate', 'level_label': '进阶',
      'learning_goals': ['掌握 LLM', '会做 RAG'],
      'target_audience': ['后端开发', '3 年+'],
      'estimated_days': 90, 'estimated_hours': 180,
      'chapter_count': 12, 'student_count': 1024,
      'cover_image': 'https://example.com/cover.png',
    });
    expect(p.id, '1');
    expect(p.title, 'AI 工程师之路');
    expect(p.difficulty, 'intermediate');
    expect(p.levelLabel, '进阶');
    expect(p.learningGoals, ['掌握 LLM', '会做 RAG']);
    expect(p.chapterCount, 12);
    expect(p.coverImage, 'https://example.com/cover.png');
  });

  test('LearningPath 缺省字段容错', () {
    final p = LearningPath.fromJson({
      'id': 1, 'title': 'x', 'slug': 's', 'description': 'd',
      'difficulty': 'beginner',
    });
    expect(p.icon, isNull);
    expect(p.levelLabel, '入门');
    expect(p.learningGoals, isEmpty);
    expect(p.chapterCount, 0);
    expect(p.coverImage, isNull);
    expect(p.isFavorited, false);
  });

  test('PathChapter.fromJson 解析', () {
    final c = PathChapter.fromJson({
      'id': 5, 'path_id': 1,
      'title': 'Prompt 基础', 'slug': 'prompt-basics',
      'description': '入门', 'content_type': 'article',
      'content': '<p>html</p>',
      'video_url': null, 'estimated_hours': 2,
      'order_index': 1, 'is_free': 1,
    });
    expect(c.id, '5');
    expect(c.title, 'Prompt 基础');
    expect(c.contentType, 'article');
    expect(c.content, '<p>html</p>');
    expect(c.isFree, true);
  });

  test('PathChapter.isFree 兼容布尔 0/1', () {
    expect(PathChapter.fromJson({'id': 1, 'path_id': 1, 'title': 't', 'slug': 's', 'content_type': 'article', 'is_free': 0}).isFree, false);
    expect(PathChapter.fromJson({'id': 1, 'path_id': 1, 'title': 't', 'slug': 's', 'content_type': 'article', 'is_free': 1}).isFree, true);
  });
}

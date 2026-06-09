import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/features/tools/domain/tool.dart';
import 'package:hot_ai_app/features/tools/domain/tool_category.dart';

void main() {
  test('ToolCategory.fromJson', () {
    final c = ToolCategory.fromJson({
      'id': 1, 'name': '代码助手', 'slug': 'code', 'icon': '💻',
      'description': 'd', 'sort_order': 1, 'featured': true,
    });
    expect(c.id, '1');
    expect(c.name, '代码助手');
    expect(c.featured, true);
  });

  test('Tool.fromJson 解析基础字段', () {
    final t = Tool.fromJson({
      'id': 1, 'name': 'Cursor', 'slug': 'cursor',
      'icon': '🖱', 'description': 'AI IDE',
      'official_url': 'https://cursor.sh',
      'documentation_url': 'https://docs.cursor.sh',
      'pricing': 'freemium', 'pricing_description': '免费 + 付费',
      'category_id': 1, 'difficulty': 'beginner',
      'rating': 4.8, 'review_count': 1024, 'view_count': 5000,
      'popularity': 100, 'tags': ['AI', 'IDE', '代码'],
      'featured': true, 'status': 1, 'is_online': true,
    });
    expect(t.id, '1');
    expect(t.name, 'Cursor');
    expect(t.officialUrl, 'https://cursor.sh');
    expect(t.pricing, 'freemium');
    expect(t.rating, 4.8);
    expect(t.tags, ['AI', 'IDE', '代码']);
    expect(t.featured, true);
    expect(t.isFavorited, false);
  });

  test('Tool 缺省字段', () {
    final t = Tool.fromJson({
      'id': 1, 'name': 'x', 'slug': 's', 'description': 'd',
      'official_url': '', 'documentation_url': '', 'pricing': 'free',
      'category_id': 1, 'difficulty': 'beginner',
    });
    expect(t.rating, 0);
    expect(t.tags, isEmpty);
    expect(t.featured, false);
  });
}

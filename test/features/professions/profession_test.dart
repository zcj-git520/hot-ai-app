import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/features/professions/domain/profession.dart';

void main() {
  test('fromJson 解析列表形态(基础字段)', () {
    final j = {
      'id': 1,
      'name': '软件工程师',
      'slug': 'software-engineer',
      'icon': '💻',
      'category_id': 1,
      'category_name': '技术',
      'description': '写代码的',
      'risk_level': 'medium',
      'risk_score': 55,
      'automation_rate': 60,
      'sort_order': 1,
    };
    final p = Profession.fromJson(j);
    expect(p.id, '1');
    expect(p.name, '软件工程师');
    expect(p.slug, 'software-engineer');
    expect(p.icon, '💻');
    expect(p.categoryName, '技术');
    expect(p.riskLevel, 'medium');
    expect(p.riskScore, 55);
    expect(p.automationRate, 60);
    expect(p.description, '写代码的');
  });

  test('fromJson 缺省字段容错', () {
    final p = Profession.fromJson({
      'id': 2,
      'name': '设计师',
      'risk_level': 'high',
      'risk_score': 80,
    });
    expect(p.id, '2');
    expect(p.icon, isNull);
    expect(p.categoryName, isNull);
    expect(p.description, '');
    expect(p.automationRate, 0);
  });

  test('fromJson 解析详情形态(含 impact/advice/market)', () {
    final j = {
      'id': 1,
      'name': '软件工程师',
      'slug': 'se',
      'description': 'desc',
      'risk_level': 'medium',
      'risk_score': 55,
      'automation_rate': 60,
      'impact_analysis': {
        'affected_tasks': ['CRUD 代码', '单元测试'],
        'safe_tasks': ['架构设计'],
        'safe_skills': ['系统设计', '业务理解'],
        'impact_summary': '中级风险,日常编码可能被 AI 辅助',
      },
      'transition_advice': {
        'transition_paths': ['AI 工程师', '技术管理'],
        'recommended_skills': ['Prompt 工程', 'RAG'],
        'recommended_tools': ['Cursor', 'Claude'],
        'advice_summary': '建议补充 AI 工程能力',
      },
      'market_data': {
        'market_trend': 'stable',
        'avg_salary': 25000.0,
        'salary_change_rate': 1.5,
        'job_demand_trend': '持平',
        'supply_demand_ratio': 1.2,
        'data_update_date': '2026-05-01',
      },
    };
    final p = Profession.fromJson(j);
    expect(p.impactAnalysis, isNotNull);
    expect(p.impactAnalysis!.affectedTasks, ['CRUD 代码', '单元测试']);
    expect(p.impactAnalysis!.safeSkills, ['系统设计', '业务理解']);
    expect(p.impactAnalysis!.summary, '中级风险,日常编码可能被 AI 辅助');
    expect(p.transitionAdvice, isNotNull);
    expect(p.transitionAdvice!.transitionPaths, ['AI 工程师', '技术管理']);
    expect(p.transitionAdvice!.recommendedSkills, ['Prompt 工程', 'RAG']);
    expect(p.marketData, isNotNull);
    expect(p.marketData!.avgSalary, 25000.0);
    expect(p.marketData!.marketTrend, 'stable');
  });

  test('copyWith isFavorited 不变其他字段', () {
    final p = Profession.fromJson({
      'id': 1, 'name': 'x', 'risk_level': 'low', 'risk_score': 20,
    });
    final p2 = p.copyWith(isFavorited: true);
    expect(p2.id, p.id);
    expect(p2.name, p.name);
    expect(p2.isFavorited, true);
    expect(p.isFavorited, false);
  });
}

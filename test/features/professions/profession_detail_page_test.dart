import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/features/professions/domain/profession.dart';
import 'package:hot_ai_app/features/professions/domain/profession_repository.dart';
import 'package:hot_ai_app/features/professions/presentation/profession_detail_page.dart';
import 'package:hot_ai_app/features/professions/presentation/professions_controller.dart';
import 'package:hot_ai_app/shared/models/pagination.dart';

class _FakeRepo implements ProfessionRepository {
  final Profession p;
  _FakeRepo(this.p);
  @override
  Future<Pagination<Profession>> getProfessions({required int page, String? riskLevel}) async {
    return Pagination(items: [p], page: 1, total: 1);
  }
  @override
  Future<Profession> getProfession(String id) async => p;
  @override
  Future<void> setFavorite(String id, bool f) async {}
  @override
  Future<List<String>> getFavorites() async => [];
}

Profession _full(String id) => Profession(
      id: id, name: '软件工程师', slug: 'se', description: '写代码',
      icon: '💻', categoryId: 1, categoryName: '技术',
      riskLevel: 'medium', riskScore: 55, automationRate: 60,
      isFavorited: false,
      impactAnalysis: ProfessionImpactAnalysis(
        affectedTasks: ['CRUD 代码', '单元测试'],
        safeTasks: ['架构设计'],
        safeSkills: ['系统设计', '业务理解'],
        summary: '中级风险',
      ),
      transitionAdvice: ProfessionTransitionAdvice(
        transitionPaths: ['AI 工程师'],
        recommendedSkills: ['Prompt 工程'],
        recommendedTools: ['Cursor'],
        summary: '建议补 AI 能力',
      ),
      marketData: ProfessionMarketData(
        marketTrend: 'stable', avgSalary: 25000, salaryChangeRate: 1.5,
        jobDemandTrend: '持平', supplyDemandRatio: 1.2,
      ),
    );

Widget _wrap(Widget child, Profession p) => ProviderScope(
      overrides: [
        professionRepositoryProvider.overrideWith((ref) => _FakeRepo(p)),
      ],
      child: MaterialApp(home: child),
    );

void main() {
  testWidgets('展示基本字段 + 影响分析 + 转型建议', (tester) async {
    final p = _full('1');
    await tester.pumpWidget(_wrap(ProfessionDetailPage(id: '1'), p));
    await tester.pumpAndSettle();
    expect(find.text('软件工程师'), findsOneWidget);
    expect(find.text('写代码'), findsOneWidget);
    expect(find.text('技术'), findsOneWidget);
    expect(find.text('影响分析'), findsOneWidget);
    expect(find.text('CRUD 代码'), findsOneWidget);
    expect(find.text('架构设计'), findsOneWidget);
    expect(find.text('系统设计'), findsOneWidget);
    expect(find.text('转型建议'), findsOneWidget);
    expect(find.text('AI 工程师'), findsOneWidget);
    expect(find.text('Prompt 工程'), findsOneWidget);
    expect(find.text('市场数据'), findsOneWidget);
    expect(find.text('¥25000'), findsOneWidget);
  });

  testWidgets('收藏按钮点击调 setFavorite', (tester) async {
    bool? lastFav;
    final p = _full('1');
    final repo = _SpyFavRepo(p, (id, f) => lastFav = f);
    await tester.pumpWidget(ProviderScope(
      overrides: [professionRepositoryProvider.overrideWith((ref) => repo)],
      child: MaterialApp(home: ProfessionDetailPage(id: '1')),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();
    expect(lastFav, true);
  });
}

class _SpyFavRepo implements ProfessionRepository {
  _SpyFavRepo(this.p, this.onFav);
  final Profession p;
  final void Function(String, bool) onFav;
  @override
  Future<Pagination<Profession>> getProfessions({required int page, String? riskLevel}) async =>
      Pagination(items: [p], page: 1, total: 1);
  @override
  Future<Profession> getProfession(String id) async => p;
  @override
  Future<void> setFavorite(String id, bool f) async => onFav(id, f);
  @override
  Future<List<String>> getFavorites() async => [];
}

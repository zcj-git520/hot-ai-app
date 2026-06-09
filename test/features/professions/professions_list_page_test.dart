import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/features/professions/domain/profession.dart';
import 'package:hot_ai_app/features/professions/domain/profession_repository.dart';
import 'package:hot_ai_app/features/professions/presentation/professions_controller.dart';
import 'package:hot_ai_app/features/professions/presentation/professions_list_page.dart';
import 'package:hot_ai_app/shared/models/pagination.dart';

class _FakeRepo implements ProfessionRepository {
  final List<Profession> data;
  _FakeRepo(this.data);
  @override
  Future<Pagination<Profession>> getProfessions({required int page, String? riskLevel}) async {
    return Pagination(items: data, page: page, total: 1);
  }
  @override
  Future<Profession> getProfession(String id) async => data.first;
  @override
  Future<void> setFavorite(String id, bool f) async {}
  @override
  Future<List<String>> getFavorites() async => [];
}

Profession _p(String id, {String name = 'p', String risk = 'medium'}) => Profession(
      id: id, name: name, slug: 's', description: '', icon: '💼',
      categoryId: 1, categoryName: '技术', riskLevel: risk, riskScore: 50,
      automationRate: 30, isFavorited: false,
    );

Widget _wrap(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('空态:items 为空且无错误时显示 EmptyView', (tester) async {
    await tester.pumpWidget(_wrap(
      const ProfessionsListPage(),
      overrides: [
        professionRepositoryProvider.overrideWith((ref) => _FakeRepo([])),
      ],
    ));
    await tester.pumpAndSettle();
    expect(find.text('暂无职业'), findsOneWidget);
  });

  testWidgets('数据态:展示 1 条职业', (tester) async {
    await tester.pumpWidget(_wrap(
      const ProfessionsListPage(),
      overrides: [
        professionRepositoryProvider.overrideWith((ref) => _FakeRepo([
          _p('1', name: '软件工程师'),
        ])),
      ],
    ));
    await tester.pumpAndSettle();
    expect(find.text('软件工程师'), findsOneWidget);
    expect(find.text('技术'), findsOneWidget);
    expect(find.textContaining('中 · 50'), findsOneWidget);
  });

  testWidgets('风险等级 chip 5 个 + 全部分类', (tester) async {
    await tester.pumpWidget(_wrap(
      const ProfessionsListPage(),
      overrides: [
        professionRepositoryProvider.overrideWith((ref) => _FakeRepo([_p('1')])),
      ],
    ));
    await tester.pumpAndSettle();
    expect(find.text('全部'), findsOneWidget);
    expect(find.text('极高'), findsOneWidget);
    expect(find.text('高'), findsOneWidget);
    expect(find.text('中'), findsOneWidget);
    expect(find.text('低'), findsOneWidget);
  });
}

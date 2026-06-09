import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/features/professions/domain/profession.dart';
import 'package:hot_ai_app/features/professions/domain/profession_repository.dart';
import 'package:hot_ai_app/features/professions/presentation/professions_controller.dart';
import 'package:hot_ai_app/shared/models/pagination.dart';

class _FakeRepo implements ProfessionRepository {
  final List<Profession> data;
  _FakeRepo(this.data);
  @override
  Future<Pagination<Profession>> getProfessions({required int page, String? riskLevel}) async {
    return Pagination(items: data, page: page, total: 1000);
  }
  @override
  Future<Profession> getProfession(String id) async => data.firstWhere((p) => p.id == id);
  @override
  Future<void> setFavorite(String id, bool f) async {}
  @override
  Future<List<String>> getFavorites() async => [];
}

Profession _p(String id, {String risk = 'medium'}) => Profession(
      id: id, name: 'p$id', slug: 's$id', description: '', icon: null,
      categoryId: null, categoryName: null, riskLevel: risk, riskScore: 50,
      automationRate: 0, isFavorited: false,
    );

void main() {
  test('load 第一页', () async {
    final container = ProviderContainer(overrides: [
      professionRepositoryProvider.overrideWith((ref) => _FakeRepo([_p('1')])),
    ]);
    addTearDown(container.dispose);
    await container.read(professionsControllerProvider.notifier).load();
    final s = container.read(professionsControllerProvider);
    expect(s.items.length, 1);
    expect(s.loading, false);
    expect(s.page, 1);
  });

  test('loadMore 追加并清空 loadingMore', () async {
    final container = ProviderContainer(overrides: [
      professionRepositoryProvider.overrideWith((ref) => _FakeRepo([_p('1')])),
    ]);
    addTearDown(container.dispose);
    await container.read(professionsControllerProvider.notifier).load();
    await container.read(professionsControllerProvider.notifier).loadMore();
    final s = container.read(professionsControllerProvider);
    expect(s.items.length, 2);
    expect(s.loadingMore, false);
    expect(s.page, 2);
  });

  test('setRiskLevel 后 load 用新参数', () async {
    String? lastRisk;
    final repo = _CapturingRepo((risk) => lastRisk = risk);
    final container = ProviderContainer(overrides: [
      professionRepositoryProvider.overrideWith((ref) => repo),
    ]);
    addTearDown(container.dispose);
    await container.read(professionsControllerProvider.notifier).setRiskLevel('high');
    expect(lastRisk, 'high');
  });

  test('toggleFavorite 失败回滚', () async {
    final repo = _ThrowingFavRepo();
    final container = ProviderContainer(overrides: [
      professionRepositoryProvider.overrideWith((ref) => repo),
    ]);
    addTearDown(container.dispose);
    await container.read(professionsControllerProvider.notifier).load();
    await container.read(professionsControllerProvider.notifier).toggleFavorite('1');
    final s = container.read(professionsControllerProvider);
    expect(s.items.first.isFavorited, false);
  });
}

class _CapturingRepo implements ProfessionRepository {
  _CapturingRepo(this.onCall);
  final void Function(String?) onCall;
  @override
  Future<Pagination<Profession>> getProfessions({required int page, String? riskLevel}) async {
    onCall(riskLevel);
    return Pagination(items: [_p('1')], page: page, total: 1000);
  }
  @override
  Future<Profession> getProfession(String id) async => _p('1');
  @override
  Future<void> setFavorite(String id, bool f) async {}
  @override
  Future<List<String>> getFavorites() async => [];
}

class _ThrowingFavRepo implements ProfessionRepository {
  @override
  Future<Pagination<Profession>> getProfessions({required int page, String? riskLevel}) async {
    return Pagination(items: [_p('1')], page: page, total: 1000);
  }
  @override
  Future<Profession> getProfession(String id) async => _p('1');
  @override
  Future<void> setFavorite(String id, bool f) async {
    throw Exception('boom');
  }
  @override
  Future<List<String>> getFavorites() async => [];
}

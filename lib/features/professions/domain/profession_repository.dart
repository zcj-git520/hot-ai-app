import 'package:hot_ai_app/features/professions/domain/profession.dart';
import 'package:hot_ai_app/shared/models/pagination.dart';

abstract class ProfessionRepository {
  Future<Pagination<Profession>> getProfessions({required int page, String? riskLevel});
  Future<Profession> getProfession(String id);
  Future<void> setFavorite(String id, bool favorite);
  Future<List<String>> getFavorites();
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppBoxes {
  AppBoxes({
    required this.appMeta,
    required this.articlesMeta,
    required this.articleDetails,
    required this.professionsCache,
    required this.learningPathsCache,
    required this.toolsCache,
    required this.userState,
  });

  final Box appMeta;
  final Box articlesMeta;
  final Box articleDetails;
  final Box professionsCache;
  final Box learningPathsCache;
  final Box toolsCache;
  final Box userState;

  Future<void> closeAll() async {
    for (final b in [
      appMeta, articlesMeta, articleDetails, professionsCache,
      learningPathsCache, toolsCache, userState,
    ]) {
      await b.close();
    }
  }
}

Future<AppBoxes> openAppBoxes({String? path}) async {
  if (path != null) {
    Hive.init(path);
  } else {
    await Hive.initFlutter();
  }
  return AppBoxes(
    appMeta: await Hive.openBox('app_meta'),
    articlesMeta: await Hive.openBox('articles_meta'),
    articleDetails: await Hive.openBox('article_details'),
    professionsCache: await Hive.openBox('professions_cache'),
    learningPathsCache: await Hive.openBox('learning_paths_cache'),
    toolsCache: await Hive.openBox('tools_cache'),
    userState: await Hive.openBox('user_state'),
  );
}

final appBoxesProvider = Provider<AppBoxes>((ref) {
  throw UnimplementedError('Override in main.dart');
});

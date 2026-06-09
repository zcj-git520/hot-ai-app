import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hot_ai_app/app.dart';
import 'package:hot_ai_app/core/network/dio_provider.dart';
import 'package:hot_ai_app/core/network/interceptors/auth_interceptor.dart';
import 'package:hot_ai_app/core/network/interceptors/error_interceptor.dart';
import 'package:hot_ai_app/core/network/interceptors/log_interceptor.dart';
import 'package:hot_ai_app/core/network/interceptors/retry_interceptor.dart';
import 'package:hot_ai_app/core/storage/hive_init.dart';
import 'package:hot_ai_app/core/storage/secure_storage.dart';
import 'package:hot_ai_app/features/articles/data/article_repository_impl.dart';
import 'package:hot_ai_app/features/articles/domain/article_repository.dart';
import 'package:hot_ai_app/features/articles/presentation/articles_controller.dart';
import 'package:hot_ai_app/features/profile/data/auth_storage.dart';
import 'package:hot_ai_app/features/profile/data/user_repository_impl.dart';
import 'package:hot_ai_app/features/profile/domain/user_repository.dart';
import 'package:hot_ai_app/features/profile/presentation/auth_controller.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final boxes = await openAppBoxes();
  const secure = FlutterSecureStorage();
  final tokenStorage = SecureTokenStorage(secure);
  final authStorage = AuthStorage(FlutterSecureStorageAdapter(secure));

  // 1. 先建 dio,装上不依赖自身的拦截器
  final dio = buildDio();
  // 2. 装上需要 dio 自身引用的拦截器(RetryInterceptor)
  dio.interceptors.addAll([
    LogInterceptor(),
    AuthInterceptor(storage: tokenStorage),
    RetryInterceptor(dio: dio),
    ErrorInterceptor(),
  ]);

  final userRepo = UserRepositoryImpl(dio: dio, storage: authStorage);
  final articleRepo = ArticleRepositoryImpl(dio: dio, boxes: boxes);

  runApp(ProviderScope(
    overrides: [
      appBoxesProvider.overrideWithValue(boxes),
      articleRepositoryProvider.overrideWithValue(articleRepo),
      userRepositoryProvider.overrideWithValue(userRepo),
    ],
    child: const HotAiApp(),
  ));
}

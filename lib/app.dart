import 'package:flutter/material.dart';
import 'package:hot_ai_app/core/router/app_router.dart';
import 'package:hot_ai_app/core/theme/app_theme.dart';

class HotAiApp extends StatelessWidget {
  const HotAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AI 热点追踪',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: buildAppRouter(),
    );
  }
}

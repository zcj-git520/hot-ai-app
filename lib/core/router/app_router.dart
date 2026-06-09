import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hot_ai_app/features/articles/presentation/article_detail_page.dart';

GoRouter buildAppRouter() {
  return GoRouter(
    initialLocation: '/articles',
    routes: [
      GoRoute(
        path: '/articles',
        builder: (_, _) => const _StubPage(title: '资讯'),
        routes: [
          GoRoute(
            path: ':id',
            builder: (ctx, state) => ArticleDetailPage(id: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(path: '/professions', builder: (_, _) => const _StubPage(title: '职业')),
      GoRoute(path: '/learning-paths', builder: (_, _) => const _StubPage(title: '学习')),
      GoRoute(path: '/tools', builder: (_, _) => const _StubPage(title: '工具')),
      GoRoute(path: '/profile', builder: (_, _) => const _StubPage(title: '我的')),
    ],
  );
}

class _StubPage extends StatelessWidget {
  const _StubPage({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text('$title 占位')),
      );
}

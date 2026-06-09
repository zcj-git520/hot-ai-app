import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

GoRouter buildAppRouter() {
  return GoRouter(
    initialLocation: '/articles',
    routes: [
      GoRoute(path: '/articles', builder: (_, __) => const _StubPage(title: '资讯')),
      GoRoute(path: '/professions', builder: (_, __) => const _StubPage(title: '职业')),
      GoRoute(path: '/learning-paths', builder: (_, __) => const _StubPage(title: '学习')),
      GoRoute(path: '/tools', builder: (_, __) => const _StubPage(title: '工具')),
      GoRoute(path: '/profile', builder: (_, __) => const _StubPage(title: '我的')),
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

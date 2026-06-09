import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hot_ai_app/features/articles/presentation/article_detail_page.dart';
import 'package:hot_ai_app/features/articles/presentation/articles_list_page.dart';
import 'package:hot_ai_app/features/home/home_shell.dart';
import 'package:hot_ai_app/features/profile/presentation/login_page.dart';
import 'package:hot_ai_app/features/profile/presentation/profile_page.dart';
import 'package:hot_ai_app/features/profile/presentation/register_page.dart';

GoRouter buildAppRouter() {
  return GoRouter(
    initialLocation: '/articles',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (ctx, state, shell) => HomeShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/articles',
              builder: (_, _) => const ArticlesListPage(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (ctx, state) => ArticleDetailPage(id: state.pathParameters['id']!),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/professions', builder: (_, _) => const _StubPage('职业')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/learning-paths', builder: (_, _) => const _StubPage('学习')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/tools', builder: (_, _) => const _StubPage('工具')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (_, _) => const ProfilePage()),
          ]),
        ],
      ),
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterPage()),
    ],
  );
}

class _StubPage extends StatelessWidget {
  const _StubPage(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text('$title (M2 待实现)')),
      );
}

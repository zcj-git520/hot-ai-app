import 'package:go_router/go_router.dart';
import 'package:hot_ai_app/features/articles/presentation/article_detail_page.dart';
import 'package:hot_ai_app/features/articles/presentation/articles_list_page.dart';
import 'package:hot_ai_app/features/home/home_shell.dart';
import 'package:hot_ai_app/features/learning_paths/presentation/chapter_detail_page.dart';
import 'package:hot_ai_app/features/learning_paths/presentation/learning_path_detail_page.dart';
import 'package:hot_ai_app/features/learning_paths/presentation/learning_paths_list_page.dart';
import 'package:hot_ai_app/features/professions/presentation/profession_detail_page.dart';
import 'package:hot_ai_app/features/professions/presentation/professions_list_page.dart';
import 'package:hot_ai_app/features/tools/presentation/tool_detail_page.dart';
import 'package:hot_ai_app/features/tools/presentation/tools_list_page.dart';
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
            GoRoute(
              path: '/professions',
              builder: (_, _) => const ProfessionsListPage(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (ctx, state) => ProfessionDetailPage(id: state.pathParameters['id']!),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/learning-paths',
              builder: (_, _) => const LearningPathsListPage(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (ctx, state) => LearningPathDetailPage(id: state.pathParameters['id']!),
                  routes: [
                    GoRoute(
                      path: 'chapters/:chapterId',
                      builder: (ctx, state) => ChapterDetailPage(
                        pathId: state.pathParameters['id']!,
                        chapterId: state.pathParameters['chapterId']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/tools',
              builder: (_, _) => const ToolsListPage(),
              routes: [
                GoRoute(
                  path: ':slug',
                  builder: (ctx, state) => ToolDetailPage(slug: state.pathParameters['slug']!),
                ),
              ],
            ),
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

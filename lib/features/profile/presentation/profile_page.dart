import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hot_ai_app/core/theme/app_theme.dart';
import 'package:hot_ai_app/features/profile/presentation/auth_controller.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    final user = state.user;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: CategoryColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        user?.nickname.substring(0, 1).toUpperCase() ?? '未登录',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: CategoryColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.nickname ?? '游客',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (user != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (user == null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('登录后可查看收藏等内容'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.push('/login'),
                      child: const Text('登录'),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.article, color: CategoryColors.primary),
                        title: const Text('我的收藏'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.history, color: CategoryColors.primary),
                        title: const Text('浏览历史'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: CategoryColors.danger),
                    title: const Text('退出登录'),
                    onTap: () => ref.read(authControllerProvider.notifier).logout(),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

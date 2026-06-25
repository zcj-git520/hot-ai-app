import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hot_ai_app/core/theme/app_theme.dart';
import 'package:hot_ai_app/features/articles/domain/article.dart';
import 'package:hot_ai_app/features/articles/presentation/articles_controller.dart';
import 'package:hot_ai_app/shared/widgets/empty_view.dart';
import 'package:hot_ai_app/shared/widgets/error_view.dart';
import 'package:hot_ai_app/shared/widgets/loading_view.dart';

class ArticlesListPage extends ConsumerStatefulWidget {
  const ArticlesListPage({super.key});

  @override
  ConsumerState<ArticlesListPage> createState() => _ArticlesListPageState();
}

class _ArticlesListPageState extends ConsumerState<ArticlesListPage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(articlesControllerProvider.notifier).load();
    });
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent * 0.8) {
      ref.read(articlesControllerProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(articlesControllerProvider);
    if (state.loading && state.items.isEmpty) return const LoadingView();
    if (state.error != null && state.items.isEmpty) {
      return ErrorView(
        message: state.error!,
        onRetry: () => ref.read(articlesControllerProvider.notifier).load(),
      );
    }
    if (state.items.isEmpty) return const EmptyView(text: '暂无资讯');

    return RefreshIndicator(
      onRefresh: () => ref.read(articlesControllerProvider.notifier).load(),
      color: CategoryColors.primary,
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.all(16),
        itemCount: state.items.length + (state.hasMore ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          return _ArticleCard(
            article: state.items[i],
            onTap: () => context.push('/articles/${state.items[i].id}'),
          );
        },
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article, required this.onTap});

  final Article article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final categoryColor = CategoryColors.getColor(article.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFFF1F5F9),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: article.coverUrl != null && article.coverUrl!.isNotEmpty
                    ? Image.network(
                        article.coverUrl!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _PlaceholderImg(color: categoryColor),
                      )
                    : _PlaceholderImg(color: categoryColor),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: categoryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            article.category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(article.publishedAt),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      article.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.summary,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${date.month}/${date.day}';
  }
}

class _PlaceholderImg extends StatelessWidget {
  const _PlaceholderImg({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      color: color.withOpacity(0.1),
      child: Icon(Icons.article, color: color, size: 32),
    );
  }
}

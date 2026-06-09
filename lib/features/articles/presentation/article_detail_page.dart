import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:hot_ai_app/features/articles/domain/article.dart';
import 'package:hot_ai_app/features/articles/presentation/articles_controller.dart';
import 'package:hot_ai_app/shared/widgets/error_view.dart';
import 'package:hot_ai_app/shared/widgets/loading_view.dart';

final _detailProvider = FutureProvider.family<Article, String>((ref, id) async {
  return ref.watch(articleRepositoryProvider).getArticle(id);
});

class ArticleDetailPage extends ConsumerWidget {
  const ArticleDetailPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_detailProvider(id));
    return Scaffold(
      appBar: AppBar(
        title: const Text('文章详情'),
        actions: [
          async.maybeWhen(
            data: (a) => IconButton(
              icon: Icon(a.isFavorited ? Icons.favorite : Icons.favorite_border),
              onPressed: () {
                ref.read(articlesControllerProvider.notifier).toggleFavorite(a.id);
                ref.invalidate(_detailProvider(id));
              },
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (a) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(a.publishedAt.toLocal().toString().split('.').first,
                  style: Theme.of(context).textTheme.bodySmall),
              if (a.coverUrl != null) ...[
                const SizedBox(height: 12),
                Image.network(a.coverUrl!),
              ],
              const SizedBox(height: 16),
              HtmlWidget(a.contentHtml),
            ],
          ),
        ),
      ),
    );
  }
}

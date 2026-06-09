import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      child: ListView.separated(
        controller: _scroll,
        itemCount: state.items.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          if (i >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final a = state.items[i];
          return ListTile(
            title: Text(a.title),
            subtitle: Text(a.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: Icon(a.isFavorited ? Icons.favorite : Icons.favorite_border),
            onTap: () => context.push('/articles/${a.id}'),
          );
        },
      ),
    );
  }
}

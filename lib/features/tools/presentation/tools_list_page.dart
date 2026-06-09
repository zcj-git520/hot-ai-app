import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hot_ai_app/features/tools/domain/tool.dart';
import 'package:hot_ai_app/features/tools/presentation/tools_controller.dart';
import 'package:hot_ai_app/shared/widgets/empty_view.dart';
import 'package:hot_ai_app/shared/widgets/error_view.dart';
import 'package:hot_ai_app/shared/widgets/loading_view.dart';

class ToolsListPage extends ConsumerStatefulWidget {
  const ToolsListPage({super.key});

  @override
  ConsumerState<ToolsListPage> createState() => _ToolsListPageState();
}

class _ToolsListPageState extends ConsumerState<ToolsListPage> {
  final _scroll = ScrollController();
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(toolsControllerProvider.notifier).load();
    });
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent * 0.8) {
      ref.read(toolsControllerProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(toolsControllerProvider);
    final controller = ref.read(toolsControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('AI 工具库')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: '搜索工具...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                suffixIcon: state.search != null && state.search!.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchCtrl.clear();
                          controller.setSearch(null);
                        },
                      )
                    : null,
              ),
              onSubmitted: controller.setSearch,
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: state.categories.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                if (i == 0) {
                  final selected = state.categoryId == null;
                  return ChoiceChip(
                    label: const Text('全部'),
                    selected: selected,
                    onSelected: (_) => controller.setCategoryId(null),
                  );
                }
                final c = state.categories[i - 1];
                final selected = state.categoryId?.toString() == c.id;
                return ChoiceChip(
                  label: Text('${c.icon ?? ''} ${c.name}'.trim()),
                  selected: selected,
                  onSelected: (_) => controller.setCategoryId(int.parse(c.id)),
                );
              },
            ),
          ),
          Expanded(child: _body(state, controller)),
        ],
      ),
    );
  }

  Widget _body(ToolsState state, ToolsController controller) {
    if (state.loading && state.items.isEmpty) return const LoadingView();
    if (state.error != null && state.items.isEmpty) {
      return ErrorView(message: state.error!, onRetry: () => controller.load());
    }
    if (state.items.isEmpty) return const EmptyView(text: '暂无工具');
    return RefreshIndicator(
      onRefresh: () => controller.load(),
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
          return _ToolTile(t: state.items[i]);
        },
      ),
    );
  }
}

class _ToolTile extends ConsumerWidget {
  const _ToolTile({required this.t});
  final Tool t;

  String get _pricingLabel {
    switch (t.pricing) {
      case 'free': return '免费';
      case 'freemium': return '免费+付费';
      case 'paid': return '付费';
      case 'subscription': return '订阅';
      default: return t.pricing;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Text(t.icon ?? '🛠', style: const TextStyle(fontSize: 28)),
      title: Text(t.name),
      subtitle: Row(
        children: [
          const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
          const SizedBox(width: 2),
          Text('${t.rating}', style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF0891B2).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(_pricingLabel,
                style: const TextStyle(color: Color(0xFF0891B2), fontSize: 12)),
          ),
        ],
      ),
      trailing: IconButton(
        icon: Icon(t.isFavorited ? Icons.favorite : Icons.favorite_border),
        onPressed: () => ref.read(toolsControllerProvider.notifier).toggleFavorite(t.id),
      ),
      onTap: () => context.push('/tools/${t.slug}'),
    );
  }
}

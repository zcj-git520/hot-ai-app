import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hot_ai_app/features/tools/domain/tool.dart';
import 'package:hot_ai_app/features/tools/presentation/tools_controller.dart';
import 'package:hot_ai_app/shared/widgets/error_view.dart';
import 'package:hot_ai_app/shared/widgets/loading_view.dart';

final _detailProvider = FutureProvider.family<Tool, String>((ref, slug) async {
  return ref.watch(toolRepositoryProvider).getTool(slug);
});

class ToolDetailPage extends ConsumerWidget {
  const ToolDetailPage({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_detailProvider(slug));
    return Scaffold(
      appBar: AppBar(
        title: const Text('工具详情'),
        actions: [
          async.maybeWhen(
            data: (t) => IconButton(
              icon: Icon(t.isFavorited ? Icons.favorite : Icons.favorite_border),
              onPressed: () async {
                await ref.read(toolRepositoryProvider).setFavorite(t.id, !t.isFavorited);
                ref.invalidate(_detailProvider(slug));
              },
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (t) => _Body(t: t),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.t});
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

  Color get _pricingColor {
    switch (t.pricing) {
      case 'free': return const Color(0xFF16A34A);
      case 'freemium': return const Color(0xFF0891B2);
      case 'paid': return const Color(0xFFEA580C);
      default: return const Color(0xFF7C3AED);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(t.icon ?? '🛠', style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(t.name, style: Theme.of(context).textTheme.headlineSmall),
                        ),
                        if (t.featured)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBBF24).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('推荐', style: TextStyle(color: Color(0xFFB45309), fontSize: 11)),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Color(0xFFF59E0B)),
                        Text(t.rating.toString(), style: const TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(width: 8),
                        Text('(${t.reviewCount} 评测)', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _pricingColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_pricingLabel, style: TextStyle(color: _pricingColor)),
              ),
              if (!t.isOnline) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('维护中', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ],
          ),
          if (t.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(t.description, style: Theme.of(context).textTheme.bodyMedium),
          ],
          if (t.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 6, runSpacing: 4,
              children: t.tags
                  .map((tag) => Chip(
                        label: Text(tag),
                        backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
                        side: BorderSide.none,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(label: '浏览', value: '${t.viewCount}'),
                _Stat(label: '收藏', value: '${t.popularity}'),
                _Stat(label: '评测', value: '${t.reviewCount}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (t.pricingDescription.isNotEmpty) ...[
            Text(t.pricingDescription, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              if (t.officialUrl.isNotEmpty)
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('访问官网'),
                    onPressed: () {
                      // 实际打开浏览器 — M2 暂不集成 url_launcher,留 M5 polish
                    },
                  ),
                ),
              if (t.officialUrl.isNotEmpty && t.documentationUrl.isNotEmpty)
                const SizedBox(width: 8),
              if (t.documentationUrl.isNotEmpty)
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.menu_book, size: 18),
                    label: const Text('查看文档'),
                    onPressed: () {},
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ]);
}

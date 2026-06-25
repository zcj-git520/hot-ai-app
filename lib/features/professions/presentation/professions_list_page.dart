import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hot_ai_app/core/theme/app_theme.dart';
import 'package:hot_ai_app/features/professions/domain/profession.dart';
import 'package:hot_ai_app/features/professions/presentation/professions_controller.dart';
import 'package:hot_ai_app/shared/widgets/empty_view.dart';
import 'package:hot_ai_app/shared/widgets/error_view.dart';
import 'package:hot_ai_app/shared/widgets/loading_view.dart';

const _riskFilters = <(String?, String, Color)>[
  (null, '全部', Color(0xFF64748B)),
  ('extreme', '极高', Color(0xFFDC2626)),
  ('high', '高', Color(0xFFEA580C)),
  ('medium', '中', Color(0xFFD97706)),
  ('low', '低', Color(0xFF16A34A)),
];

class ProfessionsListPage extends ConsumerStatefulWidget {
  const ProfessionsListPage({super.key});

  @override
  ConsumerState<ProfessionsListPage> createState() => _ProfessionsListPageState();
}

class _ProfessionsListPageState extends ConsumerState<ProfessionsListPage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(professionsControllerProvider.notifier).load();
    });
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent * 0.8) {
      ref.read(professionsControllerProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(professionsControllerProvider);
    final controller = ref.read(professionsControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('职业风险')),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: _riskFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final (level, label, color) = _riskFilters[i];
                final selected = state.riskLevel == level;
                return ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  selectedColor: color.withValues(alpha: 0.2),
                  side: BorderSide(color: selected ? color : Colors.transparent),
                  onSelected: (_) => controller.setRiskLevel(level),
                );
              },
            ),
          ),
          Expanded(child: _body(state, controller)),
        ],
      ),
    );
  }

  Widget _body(ProfessionsState state, ProfessionsController controller) {
    if (state.loading && state.items.isEmpty) return const LoadingView();
    if (state.error != null && state.items.isEmpty) {
      return ErrorView(
        message: state.error!,
        onRetry: () => controller.load(),
      );
    }
    if (state.items.isEmpty) return const EmptyView(text: '暂无职业');
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
          final p = state.items[i];
          return _ProfessionTile(p: p);
        },
      ),
    );
  }
}

class _ProfessionTile extends ConsumerWidget {
  const _ProfessionTile({required this.p});
  final Profession p;

  Color get _riskColor {
    switch (p.riskLevel) {
      case 'extreme': return const Color(0xFFDC2626);
      case 'high': return const Color(0xFFEA580C);
      case 'low': return const Color(0xFF16A34A);
      default: return const Color(0xFFD97706);
    }
  }

  String get _riskLabel {
    switch (p.riskLevel) {
      case 'extreme': return '极高风险';
      case 'high': return '高风险';
      case 'low': return '低风险';
      default: return '中等风险';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: const Color(0xFFF1F5F9),
      elevation: 0,
      child: InkWell(
        onTap: () => context.push('/professions/${p.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 大数字风险指数
              Container(
                width: 72,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _riskColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '${p.riskScore}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: _riskColor,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _riskColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _riskLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (p.categoryName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        p.categoryName!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    if (p.description != null && p.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        p.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(p.isFavorited ? Icons.favorite : Icons.favorite_border,
                  color: p.isFavorited ? Colors.red : const Color(0xFFCBD5E1)),
                onPressed: () =>
                    ref.read(professionsControllerProvider.notifier).toggleFavorite(p.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

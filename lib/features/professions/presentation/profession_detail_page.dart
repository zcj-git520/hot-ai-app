import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hot_ai_app/features/professions/domain/profession.dart';
import 'package:hot_ai_app/features/professions/presentation/professions_controller.dart';
import 'package:hot_ai_app/shared/widgets/error_view.dart';
import 'package:hot_ai_app/shared/widgets/loading_view.dart';

final _detailProvider = FutureProvider.family<Profession, String>((ref, id) async {
  return ref.watch(professionRepositoryProvider).getProfession(id);
});

class ProfessionDetailPage extends ConsumerWidget {
  const ProfessionDetailPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_detailProvider(id));
    return Scaffold(
      appBar: AppBar(
        title: const Text('职业详情'),
        actions: [
          async.maybeWhen(
            data: (p) => IconButton(
              icon: Icon(p.isFavorited ? Icons.favorite : Icons.favorite_border),
              onPressed: () async {
                await ref.read(professionRepositoryProvider).setFavorite(p.id, !p.isFavorited);
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
        data: (p) => _Body(p: p),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.p});
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
      case 'extreme': return '极高';
      case 'high': return '高';
      case 'low': return '低';
      default: return '中';
    }
  }

  String _marketLabel(String trend) {
    switch (trend) {
      case 'growing': return '增长';
      case 'declining': return '下降';
      default: return '平稳';
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
              Text(p.icon ?? '💼', style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: Theme.of(context).textTheme.headlineSmall),
                    if (p.categoryName != null)
                      Text(p.categoryName!, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _riskColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(label: '风险等级', value: _riskLabel, color: _riskColor),
                _Stat(label: '风险评分', value: '${p.riskScore}', color: _riskColor),
                _Stat(label: '自动化率', value: '${p.automationRate}%', color: _riskColor),
              ],
            ),
          ),
          if (p.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(p.description, style: Theme.of(context).textTheme.bodyMedium),
          ],
          if (p.impactAnalysis != null) ...[
            const SizedBox(height: 24),
            Text('影响分析', style: Theme.of(context).textTheme.titleMedium),
            if (p.impactAnalysis!.summary.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(p.impactAnalysis!.summary,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            const SizedBox(height: 8),
            if (p.impactAnalysis!.affectedTasks.isNotEmpty)
              _ListGroup(
                title: '将被 AI 影响的',
                color: const Color(0xFFDC2626),
                items: p.impactAnalysis!.affectedTasks,
              ),
            if (p.impactAnalysis!.safeTasks.isNotEmpty)
              _ListGroup(
                title: '相对安全的',
                color: const Color(0xFF16A34A),
                items: p.impactAnalysis!.safeTasks,
              ),
            if (p.impactAnalysis!.safeSkills.isNotEmpty)
              _ListGroup(
                title: '可迁移能力',
                color: const Color(0xFF2563EB),
                items: p.impactAnalysis!.safeSkills,
              ),
          ],
          if (p.transitionAdvice != null) ...[
            const SizedBox(height: 24),
            Text('转型建议', style: Theme.of(context).textTheme.titleMedium),
            if (p.transitionAdvice!.summary.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(p.transitionAdvice!.summary,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            const SizedBox(height: 8),
            if (p.transitionAdvice!.transitionPaths.isNotEmpty)
              _ListGroup(
                title: '转型方向',
                color: const Color(0xFF7C3AED),
                items: p.transitionAdvice!.transitionPaths,
              ),
            if (p.transitionAdvice!.recommendedSkills.isNotEmpty)
              _ListGroup(
                title: '推荐技能',
                color: const Color(0xFF0891B2),
                items: p.transitionAdvice!.recommendedSkills,
              ),
            if (p.transitionAdvice!.recommendedTools.isNotEmpty)
              _ListGroup(
                title: '推荐工具',
                color: const Color(0xFFEA580C),
                items: p.transitionAdvice!.recommendedTools,
              ),
          ],
          if (p.marketData != null) ...[
            const SizedBox(height: 24),
            Text('市场数据', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _MarketRow(label: '市场趋势', value: _marketLabel(p.marketData!.marketTrend)),
                  _MarketRow(label: '平均薪资', value: '¥${p.marketData!.avgSalary.toStringAsFixed(0)}'),
                  _MarketRow(label: '薪资变化', value: '${p.marketData!.salaryChangeRate.toStringAsFixed(1)}%'),
                  _MarketRow(label: '岗位需求', value: p.marketData!.jobDemandTrend),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ]);
}

class _ListGroup extends StatelessWidget {
  const _ListGroup({required this.title, required this.color, required this.items});
  final String title;
  final Color color;
  final List<String> items;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: items
                  .map((t) => Chip(
                        label: Text(t, style: const TextStyle(fontSize: 12)),
                        backgroundColor: color.withValues(alpha: 0.1),
                        side: BorderSide.none,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ],
        ),
      );
}

class _MarketRow extends StatelessWidget {
  const _MarketRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.w500))],
        ),
      );
}

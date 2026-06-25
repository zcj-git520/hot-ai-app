import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hot_ai_app/features/learning_paths/domain/learning_path.dart';
import 'package:hot_ai_app/features/learning_paths/presentation/learning_paths_controller.dart';
import 'package:hot_ai_app/shared/widgets/empty_view.dart';
import 'package:hot_ai_app/shared/widgets/error_view.dart';
import 'package:hot_ai_app/shared/widgets/loading_view.dart';

const _difficultyFilters = <(String?, String, Color)>[
  (null, '全部', Color(0xFF64748B)),
  ('beginner', '入门', Color(0xFF16A34A)),
  ('intermediate', '进阶', Color(0xFFD97706)),
  ('advanced', '高级', Color(0xFFDC2626)),
];

class LearningPathsListPage extends ConsumerStatefulWidget {
  const LearningPathsListPage({super.key});

  @override
  ConsumerState<LearningPathsListPage> createState() => _LearningPathsListPageState();
}

class _LearningPathsListPageState extends ConsumerState<LearningPathsListPage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(learningPathsControllerProvider.notifier).load();
    });
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent * 0.8) {
      ref.read(learningPathsControllerProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(learningPathsControllerProvider);
    final controller = ref.read(learningPathsControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('学习路径')),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: _difficultyFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final (level, label, color) = _difficultyFilters[i];
                final selected = state.difficulty == level;
                return ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  selectedColor: color.withValues(alpha: 0.2),
                  side: BorderSide(color: selected ? color : Colors.transparent),
                  onSelected: (_) => controller.setDifficulty(level),
                );
              },
            ),
          ),
          Expanded(child: _body(state, controller)),
        ],
      ),
    );
  }

  Widget _body(LearningPathsState state, LearningPathsController controller) {
    if (state.loading && state.items.isEmpty) return const LoadingView();
    if (state.error != null && state.items.isEmpty) {
      return ErrorView(message: state.error!, onRetry: () => controller.load());
    }
    if (state.items.isEmpty) return const EmptyView(text: '暂无学习路径');
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
          return _PathTile(p: state.items[i]);
        },
      ),
    );
  }
}

class _PathTile extends ConsumerWidget {
  const _PathTile({required this.p});
  final LearningPath p;

  Color get _color {
    switch (p.difficulty) {
      case 'advanced': return const Color(0xFFDC2626);
      case 'intermediate': return const Color(0xFFD97706);
      default: return const Color(0xFF16A34A);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: const Color(0xFFF1F5F9),
      elevation: 0,
      child: InkWell(
        onTap: () => context.push('/learning-paths/${p.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 72,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '${(p.progressPercent * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: _color,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        p.levelLabel,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${p.estimatedDays} 天 · ${p.chapterCount} 章 · ${p.studentCount} 人学习',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: p.progressPercent,
                        backgroundColor: Colors.white,
                        valueColor: AlwaysStoppedAnimation<Color>(_color),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(p.isFavorited ? Icons.favorite : Icons.favorite_border,
                  color: p.isFavorited ? Colors.red : const Color(0xFFCBD5E1)),
                onPressed: () =>
                    ref.read(learningPathsControllerProvider.notifier).toggleFavorite(p.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

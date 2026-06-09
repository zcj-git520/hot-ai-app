import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hot_ai_app/features/learning_paths/domain/learning_path.dart';
import 'package:hot_ai_app/features/learning_paths/domain/path_chapter.dart';
import 'package:hot_ai_app/features/learning_paths/presentation/learning_paths_controller.dart';
import 'package:hot_ai_app/shared/widgets/error_view.dart';
import 'package:hot_ai_app/shared/widgets/loading_view.dart';

final _detailProvider = FutureProvider.family<LearningPath, String>((ref, id) async {
  return ref.watch(learningPathRepositoryProvider).getLearningPath(id);
});

class LearningPathDetailPage extends ConsumerWidget {
  const LearningPathDetailPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_detailProvider(id));
    return Scaffold(
      appBar: AppBar(
        title: const Text('学习路径'),
        actions: [
          async.maybeWhen(
            data: (p) => IconButton(
              icon: Icon(p.isFavorited ? Icons.favorite : Icons.favorite_border),
              onPressed: () async {
                await ref.read(learningPathRepositoryProvider).setFavorite(p.id, !p.isFavorited);
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
        data: (p) => _Body(path: p),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.path});
  final LearningPath path;

  Color get _color {
    switch (path.difficulty) {
      case 'advanced': return const Color(0xFFDC2626);
      case 'intermediate': return const Color(0xFFD97706);
      default: return const Color(0xFF16A34A);
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
              Text(path.icon ?? '📚', style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(path.title, style: Theme.of(context).textTheme.headlineSmall),
                    Text('${path.levelLabel} · ${path.estimatedDays} 天 · ${path.estimatedHours} 小时',
                        style: TextStyle(color: _color, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          if (path.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(path.description, style: Theme.of(context).textTheme.bodyMedium),
          ],
          if (path.learningGoals.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('学习目标', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6, runSpacing: 4,
              children: path.learningGoals
                  .map((g) => Chip(label: Text(g), backgroundColor: _color.withValues(alpha: 0.1), side: BorderSide.none))
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(label: '章节', value: '${path.chapterCount}'),
              _Stat(label: '学员', value: '${path.studentCount}'),
              _Stat(label: '时长', value: '${path.estimatedHours}h'),
            ],
          ),
          const SizedBox(height: 24),
          Text('章节列表 (${path.chapters.length})', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (path.chapters.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('暂无章节', style: Theme.of(context).textTheme.bodySmall),
            )
          else
            ...path.chapters.map((c) => _ChapterTile(chapter: c, pathId: path.id)),
        ],
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({required this.chapter, required this.pathId});
  final PathChapter chapter;
  final String pathId;

  IconData get _typeIcon {
    switch (chapter.contentType) {
      case 'video': return Icons.play_circle_outline;
      case 'practice': return Icons.code;
      case 'external': return Icons.open_in_new;
      default: return Icons.article_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(_typeIcon, color: Theme.of(context).colorScheme.primary),
        title: Text('${chapter.orderIndex}. ${chapter.title}'),
        subtitle: Text('${chapter.estimatedHours} 小时${chapter.isFree ? " · 免费" : ""}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/learning-paths/$pathId/chapters/${chapter.id}'),
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

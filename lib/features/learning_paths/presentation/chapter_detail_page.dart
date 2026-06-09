import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:hot_ai_app/features/learning_paths/domain/path_chapter.dart';
import 'package:hot_ai_app/features/learning_paths/presentation/learning_paths_controller.dart';
import 'package:hot_ai_app/shared/widgets/error_view.dart';
import 'package:hot_ai_app/shared/widgets/loading_view.dart';

final _chapterProvider = FutureProvider.family<PathChapter, (String, String)>((ref, args) async {
  return ref.watch(learningPathRepositoryProvider).getChapter(args.$2);
});

class ChapterDetailPage extends ConsumerWidget {
  const ChapterDetailPage({super.key, required this.pathId, required this.chapterId});
  final String pathId;
  final String chapterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_chapterProvider((pathId, chapterId)));
    return Scaffold(
      appBar: AppBar(title: const Text('章节')),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (c) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('第 ${c.orderIndex} 章', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 8),
                  if (c.isFree)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('免费', style: TextStyle(color: Color(0xFF16A34A), fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(c.title, style: Theme.of(context).textTheme.headlineSmall),
              if (c.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(c.description, style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: 8),
              Text('${c.estimatedHours} 小时', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              if (c.contentType == 'article' && c.content.isNotEmpty)
                HtmlWidget(c.content)
              else if (c.contentType == 'video' && c.videoUrl != null)
                Center(child: Text('视频: ${c.videoUrl}'))
              else
                Center(child: Text('${c.contentType} 类型内容')),
            ],
          ),
        ),
      ),
    );
  }
}

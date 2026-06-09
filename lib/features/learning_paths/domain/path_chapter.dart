class PathChapter {
  PathChapter({
    required this.id,
    required this.pathId,
    required this.title,
    required this.slug,
    required this.description,
    required this.contentType,
    required this.content,
    required this.videoUrl,
    required this.estimatedHours,
    required this.orderIndex,
    required this.isFree,
  });

  final String id;
  final String pathId;
  final String title;
  final String slug;
  final String description;
  final String contentType; // article / video / practice / external
  final String content;
  final String? videoUrl;
  final int estimatedHours;
  final int orderIndex;
  final bool isFree;

  Map<String, dynamic> toJson() => {
        'id': id,
        'path_id': pathId,
        'title': title,
        'slug': slug,
        'description': description,
        'content_type': contentType,
        'content': content,
        'video_url': videoUrl,
        'estimated_hours': estimatedHours,
        'order_index': orderIndex,
        'is_free': isFree ? 1 : 0,
      };

  factory PathChapter.fromJson(Map<String, dynamic> j) => PathChapter(
        id: j['id'].toString(),
        pathId: j['path_id'].toString(),
        title: j['title'] as String,
        slug: j['slug'] as String? ?? '',
        description: j['description'] as String? ?? '',
        contentType: j['content_type'] as String? ?? 'article',
        content: j['content'] as String? ?? '',
        videoUrl: j['video_url'] as String?,
        estimatedHours: j['estimated_hours'] as int? ?? 0,
        orderIndex: j['order_index'] as int? ?? 0,
        isFree: (j['is_free'] is bool)
            ? j['is_free'] as bool
            : (j['is_free'] as int? ?? 0) == 1,
      );
}

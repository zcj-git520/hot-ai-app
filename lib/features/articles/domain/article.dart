class Article {
  Article({
    required this.id,
    required this.title,
    required this.summary,
    required this.contentHtml,
    required this.coverUrl,
    required this.publishedAt,
    required this.category,
    required this.isFavorited,
  });

  final String id;
  final String title;
  final String summary;
  final String contentHtml;
  final String? coverUrl;
  final DateTime publishedAt;
  final String category;
  final bool isFavorited;

  Article copyWith({bool? isFavorited}) => Article(
        id: id,
        title: title,
        summary: summary,
        contentHtml: contentHtml,
        coverUrl: coverUrl,
        publishedAt: publishedAt,
        category: category,
        isFavorited: isFavorited ?? this.isFavorited,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'contentHtml': contentHtml,
        'coverUrl': coverUrl,
        'publishedAt': publishedAt.toIso8601String(),
        'category': category,
        'isFavorited': isFavorited,
      };

  factory Article.fromJson(Map<String, dynamic> j) => Article(
        id: j['id'] as String,
        title: j['title'] as String,
        summary: j['summary'] as String? ?? '',
        contentHtml: j['contentHtml'] as String? ?? '',
        coverUrl: j['coverUrl'] as String?,
        publishedAt: DateTime.parse(j['publishedAt'] as String),
        category: j['category'] as String? ?? '',
        isFavorited: j['isFavorited'] as bool? ?? false,
      );

  /// 从 API 响应创建（API 使用 snake_case 字段名，id 为 int）
  factory Article.fromApiJson(Map<String, dynamic> j) => Article(
        id: (j['id'] as int).toString(),
        title: j['title'] as String? ?? '',
        summary: j['summary'] as String? ?? '',
        contentHtml: j['content'] as String? ?? '',
        coverUrl: j['cover_url'] as String?,
        publishedAt: DateTime.tryParse(j['published_at'] as String? ?? '') ?? DateTime.now(),
        category: j['category_name'] as String? ?? '',
        isFavorited: j['is_favorited'] as bool? ?? false,
      );
}

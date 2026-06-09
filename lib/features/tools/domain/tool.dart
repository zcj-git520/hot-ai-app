class Tool {
  Tool({
    required this.id,
    required this.name,
    required this.slug,
    required this.icon,
    required this.description,
    required this.officialUrl,
    required this.documentationUrl,
    required this.pricing,
    required this.pricingDescription,
    required this.categoryId,
    required this.difficulty,
    required this.rating,
    required this.reviewCount,
    required this.viewCount,
    required this.popularity,
    required this.tags,
    required this.featured,
    required this.isOnline,
    required this.isFavorited,
  });

  final String id;
  final String name;
  final String slug;
  final String? icon;
  final String description;
  final String officialUrl;
  final String documentationUrl;
  final String pricing;
  final String pricingDescription;
  final int categoryId;
  final String difficulty;
  final double rating;
  final int reviewCount;
  final int viewCount;
  final int popularity;
  final List<String> tags;
  final bool featured;
  final bool isOnline;
  final bool isFavorited;

  Tool copyWith({bool? isFavorited}) => Tool(
        id: id, name: name, slug: slug, icon: icon, description: description,
        officialUrl: officialUrl, documentationUrl: documentationUrl,
        pricing: pricing, pricingDescription: pricingDescription,
        categoryId: categoryId, difficulty: difficulty,
        rating: rating, reviewCount: reviewCount, viewCount: viewCount,
        popularity: popularity, tags: tags, featured: featured,
        isOnline: isOnline, isFavorited: isFavorited ?? this.isFavorited,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'icon': icon,
        'description': description,
        'official_url': officialUrl,
        'documentation_url': documentationUrl,
        'pricing': pricing,
        'pricing_description': pricingDescription,
        'category_id': categoryId,
        'difficulty': difficulty,
        'rating': rating,
        'review_count': reviewCount,
        'view_count': viewCount,
        'popularity': popularity,
        'tags': tags,
        'featured': featured,
        'is_online': isOnline,
        'isFavorited': isFavorited,
      };

  factory Tool.fromJson(Map<String, dynamic> j) => Tool(
        id: j['id'].toString(),
        name: j['name'] as String,
        slug: j['slug'] as String? ?? '',
        icon: j['icon'] as String?,
        description: j['description'] as String? ?? '',
        officialUrl: j['official_url'] as String? ?? '',
        documentationUrl: j['documentation_url'] as String? ?? '',
        pricing: j['pricing'] as String? ?? 'free',
        pricingDescription: j['pricing_description'] as String? ?? '',
        categoryId: j['category_id'] as int? ?? 0,
        difficulty: j['difficulty'] as String? ?? 'beginner',
        rating: (j['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: j['review_count'] as int? ?? 0,
        viewCount: j['view_count'] as int? ?? 0,
        popularity: j['popularity'] as int? ?? 0,
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
        featured: j['featured'] as bool? ?? false,
        isOnline: j['is_online'] as bool? ?? true,
        isFavorited: j['isFavorited'] as bool? ?? false,
      );
}

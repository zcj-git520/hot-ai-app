class ToolCategory {
  ToolCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.icon,
    required this.description,
    required this.sortOrder,
    required this.featured,
  });

  final String id;
  final String name;
  final String slug;
  final String? icon;
  final String description;
  final int sortOrder;
  final bool featured;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'icon': icon,
        'description': description,
        'sort_order': sortOrder,
        'featured': featured,
      };

  factory ToolCategory.fromJson(Map<String, dynamic> j) => ToolCategory(
        id: j['id'].toString(),
        name: j['name'] as String,
        slug: j['slug'] as String? ?? '',
        icon: j['icon'] as String?,
        description: j['description'] as String? ?? '',
        sortOrder: j['sort_order'] as int? ?? 0,
        featured: j['featured'] as bool? ?? false,
      );
}

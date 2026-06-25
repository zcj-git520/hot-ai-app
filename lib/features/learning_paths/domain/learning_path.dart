import 'dart:convert';
import 'package:hot_ai_app/features/learning_paths/domain/path_chapter.dart';

List<String> _parseStringList(dynamic value) {
  if (value == null) return [];
  if (value is List) return value.cast<String>();
  if (value is String && value.isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) return decoded.cast<String>();
    } catch (_) {}
  }
  return [];
}

class LearningPath {
  LearningPath({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.icon,
    required this.difficulty,
    required this.levelLabel,
    required this.learningGoals,
    required this.targetAudience,
    required this.estimatedDays,
    required this.estimatedHours,
    required this.chapterCount,
    required this.studentCount,
    required this.coverImage,
    required this.isFavorited,
    this.progressPercent = 0,
    this.chapters = const [],
  });

  final String id;
  final String title;
  final String slug;
  final String description;
  final String? icon;
  final String difficulty;
  final String levelLabel;
  final List<String> learningGoals;
  final List<String> targetAudience;
  final int estimatedDays;
  final int estimatedHours;
  final int chapterCount;
  final int studentCount;
  final String? coverImage;
  final bool isFavorited;
  final double progressPercent;
  final List<PathChapter> chapters;

  LearningPath copyWith({bool? isFavorited, double? progressPercent, List<PathChapter>? chapters}) => LearningPath(
        id: id,
        title: title,
        slug: slug,
        description: description,
        icon: icon,
        difficulty: difficulty,
        levelLabel: levelLabel,
        learningGoals: learningGoals,
        targetAudience: targetAudience,
        estimatedDays: estimatedDays,
        estimatedHours: estimatedHours,
        chapterCount: chapterCount,
        studentCount: studentCount,
        coverImage: coverImage,
        isFavorited: isFavorited ?? this.isFavorited,
        progressPercent: progressPercent ?? this.progressPercent,
        chapters: chapters ?? this.chapters,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'slug': slug,
        'description': description,
        'icon': icon,
        'difficulty': difficulty,
        'level_label': levelLabel,
        'learning_goals': learningGoals,
        'target_audience': targetAudience,
        'estimated_days': estimatedDays,
        'estimated_hours': estimatedHours,
        'chapter_count': chapterCount,
        'student_count': studentCount,
        'cover_image': coverImage,
        'isFavorited': isFavorited,
        'progress_percent': progressPercent,
        'chapters': chapters.map((c) => c.toJson()).toList(),
      };

  factory LearningPath.fromJson(Map<String, dynamic> j) {
    final chaptersJson = j['chapters'];
    final chapters = chaptersJson == null
        ? <PathChapter>[]
        : (chaptersJson as List)
            .cast<Map<String, dynamic>>()
            .map(PathChapter.fromJson)
            .toList();
    return LearningPath(
      id: j['id'].toString(),
      title: j['title'] as String,
      slug: j['slug'] as String? ?? '',
      description: j['description'] as String? ?? '',
      icon: j['icon'] as String?,
      difficulty: j['difficulty'] as String? ?? 'beginner',
      levelLabel: j['level_label'] as String? ?? '入门',
      learningGoals: _parseStringList(j['learning_goals']),
      targetAudience: _parseStringList(j['target_audience']),
      estimatedDays: j['estimated_days'] as int? ?? 0,
      estimatedHours: j['estimated_hours'] as int? ?? 0,
      chapterCount: j['chapter_count'] as int? ?? chapters.length,
      studentCount: j['student_count'] as int? ?? 0,
      coverImage: j['cover_image'] as String?,
      isFavorited: j['isFavorited'] as bool? ?? false,
      progressPercent: (j['progress_percent'] as num?)?.toDouble() ?? 0,
      chapters: chapters,
    );
  }
}

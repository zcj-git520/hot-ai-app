class Profession {
  Profession({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.icon,
    required this.categoryId,
    required this.categoryName,
    required this.riskLevel,
    required this.riskScore,
    required this.automationRate,
    required this.isFavorited,
    this.impactAnalysis,
    this.transitionAdvice,
    this.marketData,
  });

  final String id;
  final String name;
  final String slug;
  final String description;
  final String? icon;
  final int? categoryId;
  final String? categoryName;
  final String riskLevel;
  final int riskScore;
  final int automationRate;
  final bool isFavorited;
  final ProfessionImpactAnalysis? impactAnalysis;
  final ProfessionTransitionAdvice? transitionAdvice;
  final ProfessionMarketData? marketData;

  Profession copyWith({bool? isFavorited}) => Profession(
        id: id,
        name: name,
        slug: slug,
        description: description,
        icon: icon,
        categoryId: categoryId,
        categoryName: categoryName,
        riskLevel: riskLevel,
        riskScore: riskScore,
        automationRate: automationRate,
        isFavorited: isFavorited ?? this.isFavorited,
        impactAnalysis: impactAnalysis,
        transitionAdvice: transitionAdvice,
        marketData: marketData,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'description': description,
        'icon': icon,
        'category_id': categoryId,
        'category_name': categoryName,
        'risk_level': riskLevel,
        'risk_score': riskScore,
        'automation_rate': automationRate,
        'isFavorited': isFavorited,
        if (impactAnalysis != null) 'impact_analysis': impactAnalysis!.toJson(),
        if (transitionAdvice != null) 'transition_advice': transitionAdvice!.toJson(),
        if (marketData != null) 'market_data': marketData!.toJson(),
      };

  factory Profession.fromJson(Map<String, dynamic> j) => Profession(
        id: j['id'].toString(),
        name: j['name'] as String,
        slug: j['slug'] as String? ?? '',
        description: j['description'] as String? ?? '',
        icon: j['icon'] as String?,
        categoryId: j['category_id'] as int?,
        categoryName: j['category_name'] as String?,
        riskLevel: j['risk_level'] as String? ?? 'medium',
        riskScore: j['risk_score'] as int? ?? 50,
        automationRate: j['automation_rate'] as int? ?? 0,
        isFavorited: j['isFavorited'] as bool? ?? false,
        impactAnalysis: j['impact_analysis'] == null
            ? null
            : ProfessionImpactAnalysis.fromJson(
                (j['impact_analysis'] as Map).cast<String, dynamic>()),
        transitionAdvice: j['transition_advice'] == null
            ? null
            : ProfessionTransitionAdvice.fromJson(
                (j['transition_advice'] as Map).cast<String, dynamic>()),
        marketData: j['market_data'] == null
            ? null
            : ProfessionMarketData.fromJson(
                (j['market_data'] as Map).cast<String, dynamic>()),
      );
}

class ProfessionImpactAnalysis {
  ProfessionImpactAnalysis({
    required this.affectedTasks,
    required this.safeTasks,
    required this.safeSkills,
    required this.summary,
  });

  final List<String> affectedTasks;
  final List<String> safeTasks;
  final List<String> safeSkills;
  final String summary;

  Map<String, dynamic> toJson() => {
        'affected_tasks': affectedTasks,
        'safe_tasks': safeTasks,
        'safe_skills': safeSkills,
        'impact_summary': summary,
      };

  factory ProfessionImpactAnalysis.fromJson(Map<String, dynamic> j) =>
      ProfessionImpactAnalysis(
        affectedTasks: (j['affected_tasks'] as List?)?.cast<String>() ?? const [],
        safeTasks: (j['safe_tasks'] as List?)?.cast<String>() ?? const [],
        safeSkills: (j['safe_skills'] as List?)?.cast<String>() ?? const [],
        summary: j['impact_summary'] as String? ?? '',
      );
}

class ProfessionTransitionAdvice {
  ProfessionTransitionAdvice({
    required this.transitionPaths,
    required this.recommendedSkills,
    required this.recommendedTools,
    required this.summary,
  });

  final List<String> transitionPaths;
  final List<String> recommendedSkills;
  final List<String> recommendedTools;
  final String summary;

  Map<String, dynamic> toJson() => {
        'transition_paths': transitionPaths,
        'recommended_skills': recommendedSkills,
        'recommended_tools': recommendedTools,
        'advice_summary': summary,
      };

  factory ProfessionTransitionAdvice.fromJson(Map<String, dynamic> j) =>
      ProfessionTransitionAdvice(
        transitionPaths: (j['transition_paths'] as List?)?.cast<String>() ?? const [],
        recommendedSkills: (j['recommended_skills'] as List?)?.cast<String>() ?? const [],
        recommendedTools: (j['recommended_tools'] as List?)?.cast<String>() ?? const [],
        summary: j['advice_summary'] as String? ?? '',
      );
}

class ProfessionMarketData {
  ProfessionMarketData({
    required this.marketTrend,
    required this.avgSalary,
    required this.salaryChangeRate,
    required this.jobDemandTrend,
    required this.supplyDemandRatio,
  });

  final String marketTrend;
  final double avgSalary;
  final double salaryChangeRate;
  final String jobDemandTrend;
  final double supplyDemandRatio;

  Map<String, dynamic> toJson() => {
        'market_trend': marketTrend,
        'avg_salary': avgSalary,
        'salary_change_rate': salaryChangeRate,
        'job_demand_trend': jobDemandTrend,
        'supply_demand_ratio': supplyDemandRatio,
      };

  factory ProfessionMarketData.fromJson(Map<String, dynamic> j) => ProfessionMarketData(
        marketTrend: j['market_trend'] as String? ?? 'stable',
        avgSalary: (j['avg_salary'] as num?)?.toDouble() ?? 0.0,
        salaryChangeRate: (j['salary_change_rate'] as num?)?.toDouble() ?? 0.0,
        jobDemandTrend: j['job_demand_trend'] as String? ?? '',
        supplyDemandRatio: (j['supply_demand_ratio'] as num?)?.toDouble() ?? 0.0,
      );
}

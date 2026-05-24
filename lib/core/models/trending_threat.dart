enum Severity { low, medium, high }

class TrendingThreat {
  final String id;
  final String title;
  final String description;
  final Severity severity;
  final String category;
  final int reportCount;
  final String? imageUrl;
  final String? articleUrl;
  final String? articleSource; // nama media sumber

  const TrendingThreat({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.category,
    required this.reportCount,
    this.imageUrl,
    this.articleUrl,
    this.articleSource,
  });
}

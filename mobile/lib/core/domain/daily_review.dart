class DailyReviewEntity {
  final String id;
  final String userId;
  final DateTime reviewDate;
  final int? productivityRating; // 1..5
  final int? energyRating;       // 1..5
  final int? focusRating;        // 1..5
  final String? wentWell;
  final String? blockedBy;
  final DateTime createdAt;

  const DailyReviewEntity({
    required this.id,
    required this.userId,
    required this.reviewDate,
    required this.productivityRating,
    required this.energyRating,
    required this.focusRating,
    required this.wentWell,
    required this.blockedBy,
    required this.createdAt,
  });

  bool get isEmpty =>
      productivityRating == null &&
      energyRating == null &&
      focusRating == null &&
      (wentWell == null || wentWell!.isEmpty) &&
      (blockedBy == null || blockedBy!.isEmpty);
}
class Promotion {
  final String ownerId;
  final String orgId;
  final String businessUnitId;
  final String createdOn;
  final String updatedOn;
  final String createdBy;
  final String updatedBy;
  final String id;
  final String promotionCode;
  final String title;
  final String description;
  final String imageUrl;
  final PromotionReward reward;
  final String ctaText;
  final String ctaAction;
  final String startFrom;
  final String endsBy;
  final String frequency;
  final bool isActive;

  Promotion({
    required this.ownerId,
    required this.orgId,
    required this.businessUnitId,
    required this.createdOn,
    required this.updatedOn,
    required this.createdBy,
    required this.updatedBy,
    required this.id,
    required this.promotionCode,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.reward,
    required this.ctaText,
    required this.ctaAction,
    required this.startFrom,
    required this.endsBy,
    required this.frequency,
    required this.isActive,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      ownerId: json['ownerId'] ?? '',
      orgId: json['orgId'] ?? '',
      businessUnitId: json['businessUnitId'] ?? '',
      createdOn: json['createdOn'] ?? '',
      updatedOn: json['updatedOn'] ?? '',
      createdBy: json['createdBy'] ?? '',
      updatedBy: json['updatedBy'] ?? '',
      id: json['id'] ?? '',
      promotionCode: json['promotionCode'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      reward: PromotionReward.fromJson(json['reward'] ?? {}),
      ctaText: json['ctaText'] ?? '',
      ctaAction: json['ctaAction'] ?? '',
      startFrom: json['startFrom'] ?? '',
      endsBy: json['endsBy'] ?? '',
      frequency: json['frequency'] ?? '',
      isActive: json['isActive'] ?? false,
    );
  }
}

class PromotionReward {
  final String type;
  final RewardEligibility eligibility;
  final double value;
  final double? maxBonusAmount;
  final int? bonusValidityDays;

  PromotionReward({
    required this.type,
    required this.eligibility,
    required this.value,
    this.maxBonusAmount,
    this.bonusValidityDays,
  });

  factory PromotionReward.fromJson(Map<String, dynamic> json) {
    return PromotionReward(
      type: json['type'] ?? '',
      eligibility: RewardEligibility.fromJson(json['eligibility'] ?? {}),
      value: (json['value'] ?? 0.0).toDouble(),
      maxBonusAmount: json['maxBonusAmount']?.toDouble(),
      bonusValidityDays: json['bonusValidityDays'],
    );
  }
}

class RewardEligibility {
  final double minValue;

  RewardEligibility({
    required this.minValue,
  });

  factory RewardEligibility.fromJson(Map<String, dynamic> json) {
    return RewardEligibility(
      minValue: (json['minvalue'] ?? 0.0).toDouble(),
    );
  }
}

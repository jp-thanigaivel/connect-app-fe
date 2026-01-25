class Expert {
  final String expertId;
  final String userId;
  final String displayName;
  final String? photoUrl;
  final String gender;
  final int age;
  final List<String> expertiseTags;
  final List<String> languages;
  final PricePerMinute pricePerMinute;
  final bool isActive;
  final bool isVerified;
  final String status; // online, busy, offline
  final String createdOn;
  final String updatedOn;
  final String createdBy;
  final String updatedBy;

  Expert({
    required this.expertId,
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.gender,
    required this.age,
    required this.expertiseTags,
    required this.languages,
    required this.pricePerMinute,
    required this.isActive,
    required this.isVerified,
    this.status = 'offline',
    required this.createdOn,
    required this.updatedOn,
    required this.createdBy,
    required this.updatedBy,
  });

  factory Expert.fromJson(Map<String, dynamic> json) {
    return Expert(
      expertId: json['expertId'] ?? '',
      userId: json['userId'] ?? '',
      displayName: json['displayName'] ?? '',
      photoUrl: json['photoUrl'],
      gender: json['gender'] ?? '',
      age: json['age'] ?? 0,
      expertiseTags: List<String>.from(json['expertiseTags'] ?? []),
      languages: List<String>.from(json['languages'] ?? []),
      pricePerMinute: PricePerMinute.fromJson(json['pricePerMinute'] ?? {}),
      isActive: json['isActive'] ?? false,
      isVerified: json['isVerified'] ?? false,
      status: json['status'] ?? 'offline',
      createdOn: json['createdOn'] ?? '',
      updatedOn: json['updatedOn'] ?? '',
      createdBy: json['createdBy'] ?? '',
      updatedBy: json['updatedBy'] ?? '',
    );
  }

  String get initials {
    if (displayName.isEmpty) return 'U';
    final parts = displayName.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}

class PricePerMinute {
  final double price;
  final String currency;

  PricePerMinute({
    required this.price,
    required this.currency,
  });

  factory PricePerMinute.fromJson(Map<String, dynamic> json) {
    return PricePerMinute(
      price: (json['price'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'INR',
    );
  }
}

import 'package:connect/models/expert.dart';

enum CallSessionStatusEnum { ongoing, ended, missed, endInitiated, unknown }

enum DurationUnitEnum { seconds, minutes, hours }

class DurationModel {
  final double value;
  final DurationUnitEnum unit;

  DurationModel({
    required this.value,
    this.unit = DurationUnitEnum.seconds,
  });

  factory DurationModel.fromJson(Map<String, dynamic> json) {
    return DurationModel(
      value: (json['value'] ?? 0).toDouble(),
      unit: DurationUnitEnum.values.firstWhere(
        (e) =>
            e.name.toUpperCase() ==
            (json['unit'] as String? ?? 'SECONDS').toUpperCase(),
        orElse: () => DurationUnitEnum.seconds,
      ),
    );
  }
}

class CallSession {
  final String callSessionId;
  final String callerId;
  final String calleeId;
  final String calleeDisplayName;
  final CallSessionStatusEnum status;
  final PricePerMinute ratePerMinute;
  final PricePerMinute totalBilledAmount;
  final double billedDurationMinutes;
  final double actualDurationSeconds;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? createdOn;
  final DateTime? lastBilledAt;
  final String? settlementId;

  CallSession({
    required this.callSessionId,
    required this.callerId,
    required this.calleeId,
    this.calleeDisplayName = '',
    this.status = CallSessionStatusEnum.unknown,
    required this.ratePerMinute,
    required this.totalBilledAmount,
    required this.billedDurationMinutes,
    required this.actualDurationSeconds,
    this.startTime,
    this.endTime,
    this.createdOn,
    this.lastBilledAt,
    this.settlementId,
  });

  factory CallSession.fromJson(Map<String, dynamic> json) {
    final references = json['references'] as Map<String, dynamic>? ?? {};
    final billing = json['billing'] as Map<String, dynamic>? ?? {};
    final ratePerMinute =
        billing['ratePerMinute'] as Map<String, dynamic>? ?? {};
    final totalBilledAmount =
        billing['totalBilledAmount'] as Map<String, dynamic>? ?? {};
    final horizon = billing['horizon'] as Map<String, dynamic>? ?? {};

    final createdOn =
        json['createdOn'] != null ? DateTime.tryParse(json['createdOn']) : null;
    final startTime = horizon['startTime'] != null
        ? DateTime.tryParse(horizon['startTime'])
        : createdOn;

    return CallSession(
      callSessionId: references['callSessionId'] ?? '',
      callerId: references['callerId'] ?? '',
      calleeId: references['calleeId'] ?? '',
      calleeDisplayName: references['calleeDisplayName'] ?? '',
      status: _mapStatus(billing['status'] as String?),
      ratePerMinute: PricePerMinute.fromJson(ratePerMinute),
      totalBilledAmount: PricePerMinute.fromJson(totalBilledAmount),
      billedDurationMinutes: (billing['billedDurationMinutes'] ?? 0).toDouble(),
      actualDurationSeconds: (billing['actualDurationSeconds'] ?? 0).toDouble(),
      startTime: startTime,
      endTime: horizon['endTime'] != null
          ? DateTime.tryParse(horizon['endTime'])
          : null,
      createdOn: createdOn,
      lastBilledAt: horizon['lastBilledAt'] != null
          ? DateTime.tryParse(horizon['lastBilledAt'])
          : null,
      settlementId: billing['settlementId'],
    );
  }

  static CallSessionStatusEnum _mapStatus(String? status) {
    if (status == null) return CallSessionStatusEnum.unknown;

    switch (status.toUpperCase()) {
      case 'INITIATED':
      case 'MISSED':
        return CallSessionStatusEnum.missed;
      case 'ACTIVE':
        return CallSessionStatusEnum.ongoing;
      case 'ENDED':
      case 'FORCE_TERMINATE_ENDED':
        return CallSessionStatusEnum.ended;
      case 'FORCE_TERMINATE_INITIATED':
        return CallSessionStatusEnum.endInitiated;
      default:
        return CallSessionStatusEnum.unknown;
    }
  }
}

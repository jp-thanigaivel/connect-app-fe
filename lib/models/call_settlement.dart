import 'package:connect/models/expert.dart';

class CallSettlement {
  final String id;
  final String settlementStatus;
  final PricePerMinute? settlementAmount;
  final PricePerMinute? totalBilledAmount;
  final PricePerMinute ratePerMin;
  final String? settlementDate;
  final String createdOn;
  final String? billingStart;
  final String? billingEnd;
  final String callSessionId;
  final String callStatus;
  final String? remarks;

  CallSettlement({
    required this.id,
    required this.settlementStatus,
    this.settlementAmount,
    required this.totalBilledAmount,
    required this.ratePerMin,
    this.settlementDate,
    required this.createdOn,
    this.billingStart,
    this.billingEnd,
    required this.callSessionId,
    required this.callStatus,
    this.remarks,
  });

  factory CallSettlement.fromJson(Map<String, dynamic> json) {
    return CallSettlement(
      id: json['_id'] ?? '',
      settlementStatus: json['settlementStatus'] ?? '',
      settlementAmount: json['settlementAmount'] != null
          ? PricePerMinute.fromJson(json['settlementAmount'])
          : null,
      totalBilledAmount:
          PricePerMinute.fromJson(json['totalBilledAmount'] ?? {}),
      ratePerMin: PricePerMinute.fromJson(json['ratePerMin'] ?? {}),
      settlementDate: json['settlementDate'],
      createdOn: json['createdOn'] ?? '',
      billingStart: json['billingStart'],
      billingEnd: json['billingEnd'],
      callSessionId: json['callSessionId'] ?? '',
      callStatus: json['callStatus'] ?? '',
      remarks: json['remarks'],
    );
  }
}

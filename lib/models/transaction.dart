import 'package:connect/core/config/currency_config.dart';

class Transaction {
  final String id;
  final String userId;
  final String status;
  final String gatewayOrderId;
  final String receipt;
  final String createdOn;
  final String provider;
  final double requestAmount;
  final String requestCurrency;
  final double requestedUnit;
  final String requestedUnitCurrency;
  final double creditedAmount;
  final String creditedCurrency;
  final double creditedUnit;
  final String creditedUnitCurrency;
  final double? conversionRate;
  final String description;
  final Map<String, dynamic>? gatewayResponse;

  Transaction({
    required this.id,
    required this.userId,
    required this.status,
    required this.gatewayOrderId,
    required this.receipt,
    required this.createdOn,
    this.provider = '',
    required this.requestAmount,
    required this.requestCurrency,
    required this.requestedUnit,
    required this.requestedUnitCurrency,
    required this.creditedAmount,
    required this.creditedCurrency,
    required this.creditedUnit,
    required this.creditedUnitCurrency,
    this.conversionRate,
    this.description = '',
    this.gatewayResponse,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final requestAmountData = json['requestAmount'] as Map<String, dynamic>?;
    final requestedUnitData = json['requestedUnit'] as Map<String, dynamic>?;
    final creditedAmountData = json['creditedAmount'] as Map<String, dynamic>?;
    final creditedUnitData = json['creditedUnit'] as Map<String, dynamic>?;

    return Transaction(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      status: json['status'] ?? '',
      gatewayOrderId: json['gatewayOrderId'] ?? '',
      receipt: json['receipt'] ?? '',
      createdOn: json['createdOn'] ?? '',
      provider: json['provider'] ?? '',
      requestAmount: (requestAmountData?['price'] ?? 0.0).toDouble(),
      requestCurrency: requestAmountData?['currency'] ?? 'INR',
      requestedUnit: (requestedUnitData?['price'] ?? 0.0).toDouble(),
      requestedUnitCurrency: requestedUnitData?['currency'] ?? 'COIN',
      creditedAmount: (creditedAmountData?['price'] ?? 0.0).toDouble(),
      creditedCurrency: creditedAmountData?['currency'] ?? 'INR',
      creditedUnit: (creditedUnitData?['price'] ?? 0.0).toDouble(),
      creditedUnitCurrency: creditedUnitData?['currency'] ?? 'COIN',
      conversionRate: (json['conversionRate'] as num?)?.toDouble(),
      description: json['description'] ?? '',
      gatewayResponse: json['gatewayResponse'],
    );
  }

  String get requestCurrencySymbol => CurrencyConfig.getSymbol(requestCurrency);
  String get requestedUnitCurrencySymbol =>
      CurrencyConfig.getSymbol(requestedUnitCurrency);
  String get creditedCurrencySymbol =>
      CurrencyConfig.getSymbol(creditedCurrency);
  String get creditedUnitCurrencySymbol =>
      CurrencyConfig.getSymbol(creditedUnitCurrency);

  String get formattedRequestAmount =>
      CurrencyConfig.formatAmount(requestAmount, requestCurrency);
  String get formattedRequestedUnit =>
      CurrencyConfig.formatAmount(requestedUnit, requestedUnitCurrency);
  String get formattedCreditedAmount =>
      CurrencyConfig.formatAmount(creditedAmount, creditedCurrency);
  String get formattedCreditedUnit =>
      CurrencyConfig.formatAmount(creditedUnit, creditedUnitCurrency);

  // Backward compatibility for UI
  String get currencySymbol => requestedUnitCurrencySymbol;
  String get formattedAmount => formattedRequestedUnit;
}

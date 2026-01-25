import 'package:connect/core/config/currency_config.dart';

class WalletBalance {
  final String userId;
  final double balance;
  final String currency;

  WalletBalance({
    required this.userId,
    required this.balance,
    required this.currency,
  });

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    final balanceData = json['balance'] as Map<String, dynamic>?;
    return WalletBalance(
      userId: json['userId'] ?? '',
      balance: (balanceData?['price'] ?? 0.0).toDouble(),
      currency: balanceData?['currency'] ?? 'INR',
    );
  }

  String get currencySymbol => CurrencyConfig.getSymbol(currency);

  String get formattedBalance => CurrencyConfig.formatAmount(balance, currency);
}

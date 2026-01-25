import 'package:flutter/material.dart';

class CurrencyConfig {
  static const String coinName = 'COIN';
  static const String coinIconText = '🪙';
  static const IconData coinIcon = Icons.monetization_on;

  static String getSymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'INR':
        return '₹';
      case 'COIN':
        return '🪙';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return currencyCode;
    }
  }

  static String formatAmount(double amount, String currencyCode) {
    if (currencyCode.toUpperCase() == 'COIN') {
      return '$coinIconText ${amount.toStringAsFixed(0)}';
    }
    return '${getSymbol(currencyCode)} ${amount.toStringAsFixed(2)}';
  }
}

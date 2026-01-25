class PaymentOrder {
  final int amount;
  final int amountDue;
  final int amountPaid;
  final int attempts;
  final int createdAt;
  final String currency;
  final String entity;
  final String id;
  final Map<String, dynamic> notes;
  final String? offerId;
  final String receipt;
  final String status;

  PaymentOrder({
    required this.amount,
    required this.amountDue,
    required this.amountPaid,
    required this.attempts,
    required this.createdAt,
    required this.currency,
    required this.entity,
    required this.id,
    required this.notes,
    this.offerId,
    required this.receipt,
    required this.status,
  });

  factory PaymentOrder.fromJson(Map<String, dynamic> json) {
    return PaymentOrder(
      amount: json['amount'] ?? 0,
      amountDue: json['amount_due'] ?? 0,
      amountPaid: json['amount_paid'] ?? 0,
      attempts: json['attempts'] ?? 0,
      createdAt: json['created_at'] ?? 0,
      currency: json['currency'] ?? '',
      entity: json['entity'] ?? '',
      id: json['id'] ?? '',
      notes: json['notes'] ?? {},
      offerId: json['offer_id'],
      receipt: json['receipt'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

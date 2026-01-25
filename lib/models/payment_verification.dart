class PaymentVerification {
  final String gatewayOrderId;
  final String? gatewayPaymentId;
  final String? gatewaySignature;

  PaymentVerification({
    required this.gatewayOrderId,
    this.gatewayPaymentId,
    this.gatewaySignature,
  });

  Map<String, dynamic> toJson() {
    return {
      'gatewayOrderId': gatewayOrderId,
      if (gatewayPaymentId != null) 'gatewayPaymentId': gatewayPaymentId,
      if (gatewaySignature != null) 'gatewaySignature': gatewaySignature,
    };
  }
}

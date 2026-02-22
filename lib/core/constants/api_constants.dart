class ApiConstants {
  static String get baseUrl => 'https://backend.iwoodtechnologies.com';
  // static String get baseUrl => 'http://10.0.2.2:8000';
  static const String googleSignIn = '/connect/app/api/v1/auth/google-signin';
  static const String zegoTokenRefresh = '/connect/app/api/v1/auth/zego-token';
  static const String heartbeat = '/connect/app/api/v1/auth/heartbeat';
  static const String experts = '/connect/app/api/v1/experts';
  static const String userProfile = '/connect/app/api/v1/users';
  static const String createOrder = '/connect/app/api/v1/payment/order';
  static const String verifyPayment = '/connect/app/api/v1/payment/verify';
  static const String razorpayKey = 'rzp_test_S5oNmjMKNRtcLJ';
  static const String conversionRate =
      '/connect/app/api/v1/payment/conversion-rate';
  static const String walletBalance = '/connect/app/api/v1/payment/wallet';
  static const String paymentHistory = '/connect/app/api/v1/payment/history';
  static const String paymentSearchConfig =
      '/connect/app/api/v1/payment/history/search-config';
  static const String initiateCall = '/connect/app/api/v1/call/initiate';
  static const String callHeartbeat = '/connect/app/api/v1/call/heartbeat';
  static const String callHistory = '/connect/app/api/v1/call/history';
  static const String callSettlements = '/connect/app/api/v1/call/settlements';
  static const String searchConfig =
      '/connect/app/api/v1/experts/search-config';
  static const String expertByUserId = '/connect/app/api/v1/experts/user';
  static const String expertLanguages = '/connect/app/api/v1/experts/languages';
  static const String expertExpertiseTags =
      '/connect/app/api/v1/experts/expertise-tags';
  static const String documentsPresign =
      '/connect/app/api/v1/documents/presign';
  static const String supportTickets = '/connect/app/api/v1/support/tickets';
  static const String adminLogin = '/connect/app/api/v1/admin/login';
  static const bool enableAdminLogin = false;
  static const String adminPhone = '9876543210';
  static const String adminPassword = '';
  static const String promotion = '/connect/app/api/v1/promotion';
  static const String legalPolicies =
      'https://connect.iwoodtechnologies.com/connect-app.html';
}

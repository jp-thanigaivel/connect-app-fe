/// Configuration for API retry behavior
class RetryConfig {
  /// Maximum number of retry attempts (0 means no retries)
  final int maxRetries;

  /// Base delay between retries
  final Duration baseDelay;

  /// Whether to use exponential backoff (delay doubles each retry)
  final bool useExponentialBackoff;

  const RetryConfig({
    this.maxRetries = 0,
    this.baseDelay = const Duration(seconds: 2),
    this.useExponentialBackoff = true,
  });

  /// No retry configuration
  static const RetryConfig none = RetryConfig(maxRetries: 0);

  /// Standard retry configuration (3 retries with exponential backoff)
  static const RetryConfig standard = RetryConfig(
    maxRetries: 3,
    baseDelay: Duration(seconds: 2),
    useExponentialBackoff: true,
  );

  /// Aggressive retry configuration (5 retries with exponential backoff)
  static const RetryConfig aggressive = RetryConfig(
    maxRetries: 5,
    baseDelay: Duration(seconds: 1),
    useExponentialBackoff: true,
  );

  /// Calculate delay for a specific retry attempt
  Duration getDelayForAttempt(int attemptNumber) {
    if (useExponentialBackoff) {
      // Exponential backoff: baseDelay * 2^(attemptNumber-1)
      return baseDelay * (1 << (attemptNumber - 1));
    }
    return baseDelay;
  }
}

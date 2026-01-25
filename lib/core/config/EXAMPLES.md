# Heartbeat Configuration Examples

## Basic Usage

### Using Default Configuration

```dart
// User heartbeat with default settings (25s interval, 3 retries)
UserHeartbeatManager.instance.start();

// Call heartbeat with default settings (30s interval, 3 retries)
CallHeartbeatManager.instance.start(callSessionId);
```

### Custom Heartbeat Interval

```dart
import 'package:connect/core/config/heartbeat_config.dart';

// Custom user heartbeat: 15 seconds interval
UserHeartbeatManager.instance.start(
  config: HeartbeatConfig.custom(
    interval: Duration(seconds: 15),
  ),
);

// Custom call heartbeat: 20 seconds interval
CallHeartbeatManager.instance.start(
  callSessionId,
  config: HeartbeatConfig.custom(
    interval: Duration(seconds: 20),
  ),
);
```

### Custom Retry Configuration

```dart
import 'package:connect/core/config/heartbeat_config.dart';
import 'package:connect/core/config/retry_config.dart';

// Aggressive retry: 5 retries with 1s base delay
UserHeartbeatManager.instance.start(
  config: HeartbeatConfig.custom(
    retryConfig: RetryConfig.aggressive,
  ),
);

// No retries
UserHeartbeatManager.instance.start(
  config: HeartbeatConfig.custom(
    retryConfig: RetryConfig.none,
  ),
);

// Custom retry: 2 retries with 5s delay, no exponential backoff
UserHeartbeatManager.instance.start(
  config: HeartbeatConfig.custom(
    retryConfig: RetryConfig(
      maxRetries: 2,
      baseDelay: Duration(seconds: 5),
      useExponentialBackoff: false,
    ),
  ),
);
```

### Full Custom Configuration

```dart
// Complete custom configuration
UserHeartbeatManager.instance.start(
  config: HeartbeatConfig(
    interval: Duration(seconds: 20),
    retryConfig: RetryConfig(
      maxRetries: 4,
      baseDelay: Duration(seconds: 3),
      useExponentialBackoff: true,
    ),
  ),
);
```

### Updating Configuration at Runtime

```dart
// Update configuration without restarting
final newConfig = HeartbeatConfig.custom(
  interval: Duration(seconds: 30),
  retryConfig: RetryConfig.aggressive,
);

UserHeartbeatManager.instance.updateConfig(newConfig);

// To apply immediately, restart
UserHeartbeatManager.instance.stop();
UserHeartbeatManager.instance.start(config: newConfig);
```

## Using RetryConfig with API Calls

### Direct API Calls with Retry

```dart
import 'package:connect/core/config/retry_config.dart';

// API call with standard retry (3 retries, exponential backoff)
final response = await apiClient.post(
  '/some/endpoint',
  data: {'key': 'value'},
  retryConfig: RetryConfig.standard,
);

// API call with no retry
final response = await apiClient.post(
  '/some/endpoint',
  data: {'key': 'value'},
  retryConfig: RetryConfig.none,
);

// API call with custom retry
final response = await apiClient.get(
  '/some/endpoint',
  retryConfig: RetryConfig(
    maxRetries: 5,
    baseDelay: Duration(milliseconds: 500),
    useExponentialBackoff: true,
  ),
);
```

## Predefined Configurations

### RetryConfig Presets

```dart
// No retries
RetryConfig.none
// maxRetries: 0

// Standard retry (default for heartbeats)
RetryConfig.standard
// maxRetries: 3
// baseDelay: 2s
// useExponentialBackoff: true
// Delays: 2s, 4s, 8s

// Aggressive retry
RetryConfig.aggressive
// maxRetries: 5
// baseDelay: 1s
// useExponentialBackoff: true
// Delays: 1s, 2s, 4s, 8s, 16s
```

### HeartbeatConfig Presets

```dart
// User heartbeat default
HeartbeatConfig.userDefault
// interval: 25s
// retryConfig: RetryConfig.standard

// Call heartbeat default
HeartbeatConfig.callDefault
// interval: 30s
// retryConfig: RetryConfig.standard
```

## Architecture Overview

```
┌─────────────────────────────────────┐
│      HeartbeatManager               │
│  (User/Call)                        │
│  - Uses HeartbeatConfig             │
│  - Manages Timer                    │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│      ApiService                     │
│  (Auth/Call)                        │
│  - Accepts RetryConfig parameter    │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│      ApiClient                      │
│  - Generic retry mechanism          │
│  - _executeWithRetry()              │
│  - Exponential backoff              │
└─────────────────────────────────────┘
```

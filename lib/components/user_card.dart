import 'package:flutter/material.dart';
import 'package:connect/models/expert.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:connect/services/call_api_service.dart';
import 'package:connect/services/call_heartbeat_manager.dart';
import 'package:connect/core/utils/ui_utils.dart';
import 'package:connect/core/config/currency_config.dart';
import 'dart:developer' as developer;

@NowaGenerated()
class UserCard extends StatelessWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const UserCard({
    super.key,
    required this.expert,
  });

  final Expert expert;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: expert.photoUrl != null
                              ? Image.network(
                                  '${expert.photoUrl!}${expert.photoUrl!.contains('?') ? '&' : '?'}v=${DateTime.now().millisecondsSinceEpoch}',
                                  fit: BoxFit.cover,
                                  // Optimization: Downsample to save memory.
                                  // 200px is sufficient for a 64px avatar with 3x pixel density.
                                  cacheWidth: 200,
                                  cacheHeight: 200,
                                  errorBuilder: (context, error, stackTrace) {
                                    // Log validation error but fallback UI handles it gracefully
                                    // developer.log('Image failed: $error', name: 'UserCard');
                                    return Center(
                                      child: Text(
                                        expert.initials,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimaryContainer,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    );
                                  },
                                )
                              : Center(
                                  child: Text(
                                    expert.initials,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: expert.status == 'busy'
                                  ? const Color(0xffef4444) // Red for busy
                                  : expert.status == 'online'
                                      ? const Color(
                                          0xff10b981) // Green for online
                                      : Colors.grey, // Grey for offline
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.surface,
                                width: 2,
                              ),
                            ),
                            child: expert.status != 'online' &&
                                    expert.status != 'busy'
                                ? const Icon(Icons.close,
                                    size: 10, color: Colors.white)
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${CurrencyConfig.getSymbol(expert.pricePerMinute.currency)} ${expert.pricePerMinute.price}/min',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 12,
                              ),
                        )
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              expert.displayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (expert.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              color: Colors.blue,
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${expert.gender} • ${expert.age} y',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      if (expert.expertiseTags.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: expert.expertiseTags
                              .map(
                                (tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    tag,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSecondaryContainer,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 10,
                                        ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (expert.languages.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          alignment: WrapAlignment.center,
                          children: expert.languages
                              .map(
                                (lang) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    lang,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSecondaryContainer,
                                        ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: expert.status == 'online'
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .disabledColor
                                .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: _buildCallButton(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallButton(BuildContext context) {
    if (expert.status != 'online') {
      return IconButton(
        onPressed: null,
        icon: Icon(
          Icons.phone,
          color: Theme.of(context).disabledColor,
          size: 20,
        ),
        padding: EdgeInsets.zero,
      );
    }

    return IconButton(
      onPressed: () async {
        try {
          if (context.mounted) {
            UiUtils.showInfoSnackBar('Initiating call...');
          }

          final callSessionId =
              await CallApiService().initiateCall(expert.userId);

          if (callSessionId != null && callSessionId.isNotEmpty) {
            developer.log(
                'Call session initiated: $callSessionId. Starting heartbeat...',
                name: 'UserCard');
            CallHeartbeatManager.instance.start(callSessionId);

            final isSuccess =
                await ZegoUIKitPrebuiltCallInvitationService().send(
              invitees: [
                ZegoCallUser(
                  expert.userId,
                  expert.displayName,
                ),
              ],
              isVideoCall: false,
              callID: callSessionId,
              resourceID: "connect_app",
            );

            if (!isSuccess) {
              developer.log('Zego invitation failed to send', name: 'UserCard');
              if (context.mounted) {
                UiUtils.showErrorSnackBar(
                    'Failed to connect. Please check your network and try again.');
              }
            }
          }
        } catch (e) {
          developer.log('Call initiation failed: $e', name: 'UserCard');
          // Global error handler in ApiClient handles API-related SnackBars
        }
      },
      icon: Icon(
        Icons.phone,
        color: Theme.of(context).colorScheme.onPrimary,
        size: 20,
      ),
      padding: EdgeInsets.zero,
    );
  }
}

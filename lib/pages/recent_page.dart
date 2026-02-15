import 'package:flutter/material.dart';
import 'package:connect/core/api/token_manager.dart';
import 'package:connect/core/utils/jwt_utils.dart';
import 'package:connect/models/call_session.dart';
import 'package:connect/services/call_api_service.dart';
import 'package:flutter/services.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:connect/core/utils/ui_utils.dart';
import 'package:connect/components/bottom_sheet_wrapper.dart';
import 'package:connect/core/config/currency_config.dart';

@NowaGenerated()
class RecentPage extends StatefulWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const RecentPage({super.key});

  @override
  State<RecentPage> createState() => _RecentPageState();
}

class _RecentPageState extends State<RecentPage> {
  final CallApiService _callApiService = CallApiService();
  List<CallSession> _recentCalls = [];
  bool _isLoading = true;
  String? _currentUserId;
  String? _userType;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final token = await TokenManager.getAccessToken();
    if (token != null) {
      _currentUserId = JwtUtils.getUserId(token);
    }
    _userType = await TokenManager.getUserType();
    _fetchCallHistory();
  }

  Future<void> _fetchCallHistory() async {
    try {
      final history = await _callApiService.getCallHistory();
      if (mounted) {
        setState(() {
          _recentCalls = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Recent',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchCallHistory,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _recentCalls.isEmpty
                ? LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history_rounded,
                                size: 80,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.2),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No recent calls found',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _fetchCallHistory,
                                child: const Text('Pull down to refresh'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    itemCount: _recentCalls.length,
                    itemBuilder: (context, index) {
                      final call = _recentCalls[index];
                      return _CallCard(
                        call: call,
                        currentUserId: _currentUserId,
                        userType: _userType,
                        onSettlementTriggered: () async {
                          try {
                            final response = await _callApiService
                                .createSettlement(call.callSessionId);
                            if (response.status.isSuccess) {
                              UiUtils.showSuccessSnackBar(
                                  response.status.statusDesc);
                            }
                            _fetchCallHistory();
                          } catch (e) {
                            // Error likely handled by global interceptor or logged
                          }
                        },
                      );
                    },
                  ),
      ),
    );
  }
}

class _CallCard extends StatelessWidget {
  final CallSession call;
  final String? currentUserId;
  final String? userType;
  final VoidCallback onSettlementTriggered;

  const _CallCard({
    required this.call,
    this.currentUserId,
    this.userType,
    required this.onSettlementTriggered,
  });

  @override
  Widget build(BuildContext context) {
    // Logic:
    // If logged in user == callerId -> Outgoing -> Show calleeId
    // If logged in user == calleeId -> Incoming -> Show callerId

    final isOutgoing = currentUserId != null && call.callerId == currentUserId;
    String displayName = call.calleeDisplayName;
    if (displayName.isEmpty) {
      displayName = isOutgoing ? call.calleeId : call.callerId;
    }

    final statusColor = _getCallColor(context, call.status);
    final totalCost = call.totalBilledAmount.price;
    final hasCost = totalCost > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showCallDetails(context, displayName, isOutgoing),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getCallIcon(call.status, isOutgoing),
                    size: 20,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            isOutgoing ? 'Outgoing' : 'Incoming',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                          if (hasCost) ...[
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(
                              CurrencyConfig.formatAmount(
                                  -totalCost, call.totalBilledAmount.currency),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDate(call.startTime),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                if (userType == 'EXPERT' &&
                    call.settlementId == null &&
                    (call.status == CallSessionStatusEnum.ended ||
                        call.status == CallSessionStatusEnum.endInitiated)) ...[
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: onSettlementTriggered,
                    icon: Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Trigger Settlement',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCallDetails(
      BuildContext context, String displayName, bool isOutgoing) {
    final statusColor = _getCallColor(context, call.status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BottomSheetWrapper(
        title: displayName,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCallIcon(call.status, isOutgoing),
                size: 48,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${call.status == CallSessionStatusEnum.missed ? 'Missed Call' : (isOutgoing ? 'Outgoing Call' : 'Incoming Call')}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            if (call.totalBilledAmount.price > 0) ...[
              const SizedBox(height: 16),
              Text(
                CurrencyConfig.formatAmount(-call.totalBilledAmount.price,
                    call.totalBilledAmount.currency),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Status',
                    value: call.status.name.toUpperCase(),
                    context: context,
                    valueColor: statusColor,
                  ),
                  const Divider(height: 32),
                  _DetailRow(
                    label: 'Start Time',
                    value:
                        '${_formatFullDate(call.startTime)} • ${_formatTime(call.startTime)}',
                    context: context,
                  ),
                  const Divider(height: 32),
                  _DetailRow(
                    label: 'End Time',
                    value:
                        '${_formatFullDate(call.endTime)} • ${_formatTime(call.endTime)}',
                    context: context,
                  ),
                  const Divider(height: 32),
                  _DetailRow(
                    label: 'Duration',
                    value: _formatDuration(call.actualDurationSeconds),
                    context: context,
                  ),
                  const Divider(height: 32),
                  _DetailRow(
                    label: 'Rate',
                    value: CurrencyConfig.formatAmount(
                        call.ratePerMinute.price, call.ratePerMinute.currency),
                    context: context,
                  ),
                  const Divider(height: 32),
                  _DetailRow(
                    label: 'Call ID',
                    value: call.callSessionId,
                    context: context,
                    isCopyable: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCallIcon(CallSessionStatusEnum status, bool isOutgoing) {
    if (status == CallSessionStatusEnum.missed) {
      return Icons.call_missed;
    }
    if (status == CallSessionStatusEnum.endInitiated) {
      return Icons.call_end;
    }

    switch (status) {
      case CallSessionStatusEnum.ongoing:
        return isOutgoing ? Icons.call_made : Icons.call_received;
      case CallSessionStatusEnum.ended:
        return isOutgoing ? Icons.call_made : Icons.call_received;
      default:
        return isOutgoing ? Icons.call_made : Icons.call_received;
    }
  }

  Color _getCallColor(BuildContext context, CallSessionStatusEnum status) {
    if (status == CallSessionStatusEnum.missed ||
        status == CallSessionStatusEnum.endInitiated) {
      return const Color(0xffef4444);
    }
    return const Color(0xff10b981);
  }

  String _formatDuration(double seconds) {
    if (seconds <= 0) return '0s';
    final int sec = seconds.toInt();
    final int min = sec ~/ 60;
    final int s = sec % 60;
    if (min > 0) {
      return '${min}m ${s}s';
    }
    return '${s}s';
  }

  String _formatFullDate(DateTime? date) {
    if (date == null) return '';
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month]}, ${date.year}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '--:--';
    final hour =
        date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $ampm';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final BuildContext context;
  final bool isCopyable;
  final Color? valueColor;
  final IconData? icon;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.context,
    this.isCopyable = false,
    this.valueColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: isCopyable
                ? () {
                    Clipboard.setData(ClipboardData(text: value));
                    UiUtils.showInfoSnackBar('Copied to clipboard');
                  }
                : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: valueColor ??
                              Theme.of(context).colorScheme.onSurface,
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (isCopyable) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.copy_rounded,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

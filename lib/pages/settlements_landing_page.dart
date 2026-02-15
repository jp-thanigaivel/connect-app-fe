import 'package:flutter/material.dart';
import 'package:connect/services/call_api_service.dart';
import 'package:connect/models/call_settlement.dart';
import 'package:connect/core/api/api_client.dart';
import 'package:connect/components/bottom_sheet_wrapper.dart';
import 'package:connect/core/config/currency_config.dart';
import 'package:connect/core/utils/ui_utils.dart';
import 'package:flutter/services.dart';

class SettlementsLandingPage extends StatefulWidget {
  const SettlementsLandingPage({super.key});

  @override
  State<SettlementsLandingPage> createState() => _SettlementsLandingPageState();
}

class _SettlementsLandingPageState extends State<SettlementsLandingPage> {
  final CallApiService _callApiService = CallApiService();
  final ScrollController _scrollController = ScrollController();
  List<CallSettlement> _settlements = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSettlements();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchSettlements() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _callApiService.getCallSettlements();
      if (mounted) {
        setState(() {
          _settlements = response.data ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = ApiClient.getErrorMessage(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Settlements',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchSettlements,
        child: _isLoading && _settlements.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorView()
                : _settlements.isEmpty
                    ? _buildEmptyView()
                    : _buildSettlementsList(),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text(_errorMessage!),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: _fetchSettlements, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 84,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'No settlements found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _fetchSettlements,
            child: const Text('Pull down to refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementsList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      itemCount: _settlements.length,
      itemBuilder: (context, index) {
        return _SettlementCard(settlement: _settlements[index]);
      },
    );
  }
}

class _SettlementCard extends StatelessWidget {
  final CallSettlement settlement;

  const _SettlementCard({required this.settlement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(theme, settlement.settlementStatus);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetails(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getSettlementIcon(settlement.settlementStatus),
                    color: statusColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session: ${settlement.callSessionId.substring(0, 8).toUpperCase()}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatFullDate(settlement.createdOn),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      settlement.settlementAmount != null
                          ? CurrencyConfig.formatAmount(
                              settlement.settlementAmount!.price,
                              settlement.settlementAmount!.currency,
                            )
                          : '-',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        settlement.settlementStatus.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getSettlementIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Icons.access_time_filled_rounded;
      case 'SUCCESS':
      case 'SETTLED':
        return Icons.check_circle_rounded;
      case 'FAILED':
        return Icons.error_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  Color _getStatusColor(ThemeData theme, String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return const Color(0xffFFAB00); // Premium Amber
      case 'SUCCESS':
      case 'SETTLED':
        return const Color(0xff00875A); // Premium Green
      case 'FAILED':
        return const Color(0xffDE350B); // Premium Red
      default:
        return theme.colorScheme.primary;
    }
  }

  String _formatFullDate(String dateStr) {
    try {
      final dateTime = DateTime.parse(dateStr);
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
      return '${dateTime.day} ${months[dateTime.month]}, ${dateTime.year} • ${_formatTime(dateTime)}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $ampm';
  }

  void _showDetails(BuildContext context) {
    final statusColor =
        _getStatusColor(Theme.of(context), settlement.settlementStatus);

    // Determine main amount to show
    String mainAmount = '-';
    if (settlement.settlementAmount != null) {
      mainAmount = CurrencyConfig.formatAmount(
        settlement.settlementAmount!.price,
        settlement.settlementAmount!.currency,
      );
    }

    final icon = _getSettlementIcon(settlement.settlementStatus);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BottomSheetWrapper(
        title: 'Settlement Details',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: statusColor,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              mainAmount,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Call Session ID',
                    value: settlement.callSessionId,
                    context: context,
                    isCopyable: true,
                  ),
                  const Divider(height: 32),
                  _DetailRow(
                    label: 'Status',
                    value: settlement.settlementStatus,
                    context: context,
                    valueColor: statusColor,
                  ),
                  const Divider(height: 32),
                  _DetailRow(
                    label: 'Call Status',
                    value: settlement.callStatus,
                    context: context,
                  ),
                  const Divider(height: 32),
                  _DetailRow(
                    label: 'Rate/Min',
                    value: CurrencyConfig.formatAmount(
                      settlement.ratePerMin.price,
                      settlement.ratePerMin.currency,
                    ),
                    context: context,
                  ),
                  const Divider(height: 32),
                  _DetailRow(
                    label: 'Total Billed',
                    value: settlement.totalBilledAmount != null
                        ? CurrencyConfig.formatAmount(
                            settlement.totalBilledAmount!.price,
                            settlement.totalBilledAmount!.currency,
                          )
                        : '-',
                    context: context,
                  ),
                  const Divider(height: 32),
                  _DetailRow(
                    label: 'Settled Amount',
                    value: settlement.settlementAmount != null
                        ? CurrencyConfig.formatAmount(
                            settlement.settlementAmount!.price,
                            settlement.settlementAmount!.currency,
                          )
                        : '-',
                    context: context,
                  ),
                  const Divider(height: 32),
                  _DetailRow(
                    label: 'Billing Start',
                    value: settlement.billingStart ?? '-',
                    context: context,
                  ),
                  const Divider(height: 32),
                  _DetailRow(
                    label: 'Billing End',
                    value: settlement.billingEnd ?? '-',
                    context: context,
                  ),
                  const Divider(height: 32),
                  _DetailRow(
                    label: 'Settled Date',
                    value: settlement.settlementDate ?? '-',
                    context: context,
                  ),
                  if (settlement.remarks != null) ...[
                    const Divider(height: 32),
                    _DetailRow(
                      label: 'Remarks',
                      value: settlement.remarks!,
                      context: context,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final BuildContext context;
  final bool isCopyable;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.context,
    this.isCopyable = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

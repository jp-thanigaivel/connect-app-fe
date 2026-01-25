import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nowa_runtime/nowa_runtime.dart';

import 'package:connect/services/payment_api_service.dart';
import 'package:connect/components/bottom_sheet_wrapper.dart';
import 'package:connect/models/transaction.dart';
import 'package:connect/models/payment_verification.dart';
import 'package:connect/core/utils/ui_utils.dart';

@NowaGenerated()
class PaymentHistoryPage extends StatefulWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  final PaymentApiService _paymentApiService = PaymentApiService();
  final ScrollController _scrollController = ScrollController();
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _nextCursor;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _fetchHistory();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _nextCursor != null) {
        _fetchHistory(isLoadMore: true);
      }
    }
  }

  Future<void> _fetchHistory({bool isLoadMore = false}) async {
    if (isLoadMore) {
      setState(() {
        _isLoadingMore = true;
      });
    } else {
      setState(() {
        _isLoading = true;
        _nextCursor = null;
      });
    }

    try {
      final response = await _paymentApiService.getPaymentHistory(
        nextCursor: isLoadMore ? _nextCursor : null,
      );
      if (mounted) {
        setState(() {
          if (isLoadMore) {
            _transactions.addAll(response.data ?? []);
          } else {
            _transactions = response.data ?? [];
          }
          _nextCursor = response.pagination?.nextPage;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
        UiUtils.showErrorSnackBar('Error fetching history: $e');
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Transactions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? RefreshIndicator(
                  onRefresh: () => _fetchHistory(),
                  child: LayoutBuilder(
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
                                Icons.receipt_long_rounded,
                                size: 80,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.2),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No transactions found',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => _fetchHistory(),
                                child: const Text('Pull down to refresh'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _fetchHistory(),
                  child: ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    itemCount:
                        _transactions.length + (_nextCursor != null ? 1 : 0),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index < _transactions.length) {
                        final transaction = _transactions[index];
                        return _TransactionCard(
                          transaction: transaction,
                          onRefresh: _fetchHistory,
                          paymentApiService: _paymentApiService,
                        );
                      } else {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                    },
                  ),
                ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onRefresh;
  final PaymentApiService paymentApiService;

  const _TransactionCard({
    required this.transaction,
    required this.onRefresh,
    required this.paymentApiService,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(transaction.status);
    final statusLower = transaction.status.toLowerCase();
    final isSuccess = statusLower == 'success' || statusLower == 'paid';
    final isFailed = statusLower == 'failed';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
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
          onTap: () => _showTransactionDetails(context),
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
                    isSuccess
                        ? Icons.check_circle_rounded
                        : isFailed
                            ? Icons.close_rounded
                            : Icons.access_time_filled_rounded,
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
                        transaction.description.isEmpty
                            ? 'Wallet Top-up'
                            : transaction.description,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(transaction.createdOn),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
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
                      transaction.formattedAmount,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (statusLower == 'initiated') ...[
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: IconButton(
                              onPressed: () async {
                                try {
                                  UiUtils.showInfoSnackBar(
                                      'Verifying payment status...');
                                  final verifyResponse = await paymentApiService
                                      .verifyPayment(PaymentVerification(
                                          gatewayOrderId:
                                              transaction.gatewayOrderId));
                                  if (verifyResponse.status.statusCode ==
                                      '200') {
                                    final response =
                                        await paymentApiService.getOrderStatus(
                                            transaction.gatewayOrderId);
                                    if (response.status.isSuccess) {
                                      UiUtils.showSuccessSnackBar(
                                          'Status: ${response.data?.status ?? 'Updated'}');
                                      onRefresh();
                                    }
                                  }
                                } catch (e) {
                                  // Global error handler in ApiClient will show the snackbar
                                }
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              padding: EdgeInsets.zero,
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    statusColor.withValues(alpha: 0.1),
                                foregroundColor: statusColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            transaction.status.toUpperCase(),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'paid':
        return const Color(0xff00875A); // Premium Green
      case 'failed':
        return const Color(0xffDE350B); // Premium Red
      case 'initiated':
        return const Color(0xffFFAB00); // Premium Amber
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
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
      return dateString;
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $ampm';
  }

  void _showTransactionDetails(BuildContext context) {
    final statusColor = _getStatusColor(transaction.status);
    final statusLower = transaction.status.toLowerCase();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BottomSheetWrapper(
        title: 'Transaction ${transaction.status}',
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
                statusLower == 'success' || statusLower == 'paid'
                    ? Icons.check_circle_rounded
                    : statusLower == 'failed'
                        ? Icons.error_rounded
                        : Icons.pending_rounded,
                color: statusColor,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              transaction.formattedAmount,
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
                    label: 'Gateway',
                    value: transaction.provider.toUpperCase(),
                    context: context,
                  ),
                  const Divider(height: 32),
                  _DetailRow(
                    label: 'Requested Coins',
                    value: transaction.formattedRequestedUnit,
                    context: context,
                  ),
                  const Divider(height: 32),
                  _DetailRow(
                    label: 'Requested Amount',
                    value: transaction.formattedRequestAmount,
                    context: context,
                  ),
                  const Divider(height: 32),
                  if (transaction.conversionRate != null) ...[
                    _DetailRow(
                      label: 'Conversion Rate',
                      value: '${transaction.conversionRate}',
                      context: context,
                    ),
                    const Divider(height: 32),
                  ],
                  _DetailRow(
                    label: 'Credited Coins',
                    value: transaction.formattedCreditedUnit,
                    context: context,
                  ),
                  const Divider(height: 32),
                  _DetailRow(
                    label: 'Credited Amount',
                    value: transaction.formattedCreditedAmount,
                    context: context,
                  ),
                  const Divider(height: 32),
                  _DetailRow(
                    label: 'Gateway Order ID',
                    value: transaction.gatewayOrderId,
                    context: context,
                    isCopyable: true,
                  ),
                  const Divider(height: 32),
                  _DetailRow(
                    label: 'Date & Time',
                    value: _formatDate(transaction.createdOn),
                    context: context,
                  ),
                  const Divider(height: 32),
                  _DetailRow(
                    label: 'Reference No',
                    value: (statusLower == 'success' || statusLower == 'paid')
                        ? transaction.receipt
                        : '-',
                    context: context,
                  ),
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

  const _DetailRow({
    required this.label,
    required this.value,
    required this.context,
    this.isCopyable = false,
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
                          color: Theme.of(context).colorScheme.onSurface,
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

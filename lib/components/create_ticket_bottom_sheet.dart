import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connect/components/bottom_sheet_wrapper.dart';
import 'package:connect/models/support_ticket.dart';
import 'package:connect/services/support_api_service.dart';
import 'package:connect/core/utils/ui_utils.dart';
import 'package:connect/core/api/api_client.dart';

class CreateTicketBottomSheet extends StatefulWidget {
  final VoidCallback onSuccess;

  const CreateTicketBottomSheet({super.key, required this.onSuccess});

  @override
  State<CreateTicketBottomSheet> createState() =>
      _CreateTicketBottomSheetState();
}

class _CreateTicketBottomSheetState extends State<CreateTicketBottomSheet> {
  final SupportApiService _supportApiService = SupportApiService();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _referenceIdController = TextEditingController();
  String _selectedCategory = 'PAYMENT';
  bool _isSubmitting = false;
  String? _errorMessage;

  final List<String> _categories = ['PAYMENT', 'CALL', 'WALLET'];
  Timer? _errorTimer;

  @override
  void dispose() {
    _errorTimer?.cancel();
    _descriptionController.dispose();
    _referenceIdController.dispose();
    super.dispose();
  }

  void _hideError() {
    if (mounted) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  void _showError(String message) {
    _errorTimer?.cancel();
    setState(() {
      _errorMessage = message;
    });
    _errorTimer = Timer(const Duration(seconds: 3), _hideError);
  }

  Future<void> _submitTicket() async {
    final description = _descriptionController.text.trim();
    final referenceId = _referenceIdController.text.trim();

    if (description.isEmpty) {
      _showError('Please enter a description');
      return;
    }

    if (_selectedCategory != 'WALLET' && referenceId.isEmpty) {
      final label =
          _selectedCategory == 'PAYMENT' ? 'Gateway Order ID' : 'Call ID';
      _showError('Please enter $label');
      return;
    }

    // Simple word count check for 300 words
    final wordCount = description.split(RegExp(r'\s+')).length;
    if (wordCount > 300) {
      _showError('Description cannot exceed 300 words');
      return;
    }

    setState(() {
      _errorMessage = null;
      _errorTimer?.cancel();
      _isSubmitting = true;
    });

    try {
      final ticket = SupportTicket(
        id: '', // Server will generate
        category: _selectedCategory,
        description: description,
        reference: SupportReference(
          type: _selectedCategory,
          id: _selectedCategory == 'WALLET' ? '' : referenceId,
        ),
        status: 'OPEN',
        createdOn: '',
        ticketId: '',
      );

      final response = await _supportApiService.createSupportTicket(ticket);
      if (response.status.isSuccess) {
        UiUtils.showSuccessSnackBar('Ticket created successfully');
        widget.onSuccess();
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showError(ApiClient.getErrorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetWrapper(
      title: 'Create Support Ticket',
      footer: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitTicket,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Submit Ticket',
                  style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: Theme.of(context).colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _errorMessage = null),
                    icon: Icon(
                      Icons.close,
                      size: 16,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          Text(
            'Support Category',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color:
                      Theme.of(context).colorScheme.outline.withOpacity(0.2)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Description',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Describe your issue (max 300 words)',
              filled: true,
              fillColor: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.2)),
              ),
            ),
          ),
          if (_selectedCategory != 'WALLET') ...[
            const SizedBox(height: 24),
            Text(
              _selectedCategory == 'PAYMENT' ? 'Gateway Order ID' : 'Call ID',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _referenceIdController,
              decoration: InputDecoration(
                hintText:
                    'Enter ${_selectedCategory == 'PAYMENT' ? 'Order ID' : 'Call ID'}',
                filled: true,
                fillColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.2)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

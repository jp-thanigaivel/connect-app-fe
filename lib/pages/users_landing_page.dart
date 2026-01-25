import 'package:flutter/material.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:connect/components/user_card.dart';
import 'package:connect/components/generic_filter_bottom_sheet.dart';
import 'package:connect/services/expert_api_service.dart';
import 'package:connect/services/payment_api_service.dart';
import 'package:connect/models/expert.dart';
import 'package:connect/models/wallet_balance.dart';
import 'package:connect/core/config/currency_config.dart';
import 'package:connect/models/search_config.dart';
import 'dart:developer' as developer;

@NowaGenerated()
class UsersLandingPage extends StatefulWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const UsersLandingPage({super.key});

  @override
  State<UsersLandingPage> createState() {
    return _UsersLandingPageState();
  }
}

@NowaGenerated()
class _UsersLandingPageState extends State<UsersLandingPage> {
  final ExpertApiService _expertApiService = ExpertApiService();
  final PaymentApiService _paymentApiService = PaymentApiService();
  final ScrollController _scrollController = ScrollController();
  List<Expert> _experts = [];
  WalletBalance? _walletBalance;
  SearchConfig? _searchConfig;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _errorMessage = '';
  String? _nextCursor;
  bool _showBackToTop = false;

  // Dynamic Filter State
  // Map<filterKey, selectedValue(s)>
  final Map<String, dynamic> _selectedFilters = {};

  @override
  void initState() {
    super.initState();
    _initData();
    _scrollController.addListener(_scrollListener);
  }

  Future<void> _initData() async {
    await Future.wait([
      _fetchSearchConfig(),
      _fetchWalletBalance(),
    ]);
    _fetchExperts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset > 400 && !_showBackToTop) {
      setState(() => _showBackToTop = true);
    } else if (_scrollController.offset <= 400 && _showBackToTop) {
      setState(() => _showBackToTop = false);
    }

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _nextCursor != null) {
        _fetchExperts(isLoadMore: true);
      }
    }
  }

  Future<void> _fetchSearchConfig() async {
    try {
      final response = await _expertApiService.getSearchConfig();
      if (mounted && response.data != null) {
        setState(() {
          _searchConfig = response.data;
          // Set default sort if available
          /*if (_searchConfig!.sortConditions.isNotEmpty) {
             // Optional: Set default sort logic here
          }*/
        });
      }
    } catch (e) {
      developer.log('Error fetching search config: $e',
          name: 'UsersLandingPage');
    }
  }

  Future<void> _fetchExperts({bool isLoadMore = false}) async {
    if (isLoadMore) {
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _nextCursor = null;
        _experts = [];
      });
      _fetchWalletBalance();
    }

    try {
      final Map<String, dynamic> filters = Map.from(_selectedFilters);
      List<String>? sort;
      if (filters.containsKey('sort')) {
        sort = [filters.remove('sort')];
      } else {
        sort = ['age']; // Default fallback
      }

      final response = await _expertApiService.getExperts(
        nextCursor: isLoadMore ? _nextCursor : null,
        filters: filters,
        sort: sort,
      );

      if (response.status.isSuccess && response.data != null) {
        setState(() {
          if (isLoadMore) {
            _experts.addAll(response.data!);
          } else {
            _experts = response.data!;
          }
          _nextCursor = response.pagination?.nextPage;
          _isLoading = false;
          _isLoadingMore = false;
        });

        if (_experts.isEmpty && _nextCursor != null) {
          await _fetchExperts(isLoadMore: true);
        }
      } else {
        setState(() {
          _errorMessage = response.status.statusDesc;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        if (!isLoadMore) {
          _errorMessage = 'Failed to load experts. Please try again later.';
        }
        _isLoading = false;
        _isLoadingMore = false;
      });
      developer.log('Error in UsersLandingPage: $e', name: 'UsersLandingPage');
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _fetchWalletBalance() async {
    try {
      final response = await _paymentApiService.getWalletBalance();
      if (mounted) {
        setState(() {
          _walletBalance = response.data;
        });
      }
    } catch (e) {
      developer.log('Error fetching wallet balance in UsersLandingPage: $e',
          name: 'UsersLandingPage');
    }
  }

  List<Expert> get filteredAndSortedExperts {
    return _experts;
  }

  Widget _buildFilterChip(String label, VoidCallback onDelete,
      {Color? color, Color? textColor}) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: onDelete,
      backgroundColor: color ?? Theme.of(context).colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: textColor ?? Theme.of(context).colorScheme.onPrimaryContainer,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  void _showFilterSheet() {
    if (_searchConfig == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GenericFilterBottomSheet(
        searchConfig: _searchConfig!,
        initialFilters: _selectedFilters,
        onApply: (filters) {
          setState(() {
            _selectedFilters.clear();
            _selectedFilters.addAll(filters);
          });
          Navigator.pop(context);
          _fetchExperts();
        },
        onReset: () {
          setState(() {
            _selectedFilters.clear();
            _selectedFilters['sort'] = 'age';
          });
          Navigator.pop(context);
          _fetchExperts();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final experts = filteredAndSortedExperts;

    // Build active filter chips for display on top of list
    final List<Widget> activeFilterChips = [];

    // Group related filters for chip display
    final Map<String, List<MapEntry<String, dynamic>>> groupedForChips = {};
    _selectedFilters.forEach((key, value) {
      if (key == 'sort') {
        if (value != 'age') {
          activeFilterChips.add(_buildFilterChip('Sort: $value', () {
            setState(() {
              _selectedFilters['sort'] = 'age';
              _fetchExperts();
            });
          },
              color: Theme.of(context).colorScheme.secondaryContainer,
              textColor: Theme.of(context).colorScheme.onSecondaryContainer));
        }
        return;
      }

      String? field;
      if (_searchConfig != null &&
          _searchConfig!.filterConditions.containsKey(key)) {
        field = _searchConfig!.filterConditions[key]!.field;
      } else {
        field = key;
      }
      groupedForChips.putIfAbsent(field, () => []).add(MapEntry(key, value));
    });

    groupedForChips.forEach((field, entries) {
      if (_searchConfig == null) return;

      // Try to find if this is a range group
      final gtEntry = entries.firstWhere(
          (e) => e.key.endsWith('__gt') || e.key.endsWith('__gte'),
          orElse: () => const MapEntry('', null));
      final ltEntry = entries.firstWhere(
          (e) => e.key.endsWith('__lt') || e.key.endsWith('__lte'),
          orElse: () => const MapEntry('', null));

      if (gtEntry.value != null && ltEntry.value != null) {
        // Find group display name
        final group = _searchConfig!.groupedFilters.firstWhere(
            (g) => g.field == field,
            orElse: () => FilterGroup(field: field, conditions: []));
        activeFilterChips.add(_buildFilterChip(
            '${group.displayName}: ${gtEntry.value} - ${ltEntry.value}', () {
          setState(() {
            _selectedFilters.remove(gtEntry.key);
            _selectedFilters.remove(ltEntry.key);
            _fetchExperts();
          });
        }));
      } else {
        // Render individually
        for (final entry in entries) {
          final key = entry.key;
          final value = entry.value;

          if (value is List) {
            for (var val in value) {
              String displayLabel = val.toString();
              final condition = _searchConfig!.filterConditions[key];
              if (condition?.allowedValues != null) {
                final found = condition!.allowedValues!.firstWhere(
                    (element) => element.value == val,
                    orElse: () =>
                        AllowedValue(display: val.toString(), value: val));
                displayLabel =
                    '${key[0].toUpperCase()}${key.substring(1)}: ${found.display}';
              }
              activeFilterChips.add(_buildFilterChip(displayLabel, () {
                setState(() {
                  (value).remove(val);
                  if (value.isEmpty) _selectedFilters.remove(key);
                  _fetchExperts();
                });
              }));
            }
          } else {
            activeFilterChips.add(_buildFilterChip('$key: $value', () {
              setState(() {
                _selectedFilters.remove(key);
                _fetchExperts();
              });
            }));
          }
        }
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'People',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _showFilterSheet,
            icon: Icon(
              Icons.tune,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Builder(
              builder: (context) {
                final double balance = _walletBalance?.balance ?? 0.0;
                final String formattedBalance =
                    _walletBalance?.formattedBalance ??
                        '${CurrencyConfig.coinIconText} 0.00';
                Color balanceColor;
                if (balance > 50) {
                  balanceColor = const Color(0xff10b981); // Green
                } else if (balance > 10) {
                  balanceColor = const Color(0xffeab308); // Yellow
                } else if (balance > 0) {
                  balanceColor = const Color(0xfff97316); // Orange
                } else {
                  balanceColor = const Color(0xffef4444); // Red
                }

                return InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, 'ProfilePage');
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: balanceColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(
                          formattedBalance,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: balanceColor,
                                  ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchSearchConfig();
          await _fetchExperts();
        },
        child: Column(
          children: [
            if (activeFilterChips.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: activeFilterChips,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                      ? LayoutBuilder(
                          builder: (context, constraints) =>
                              SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline,
                                        size: 48,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error),
                                    const SizedBox(height: 16),
                                    Text(_errorMessage),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                        onPressed: _fetchExperts,
                                        child: const Text('Retry')),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      : experts.isEmpty
                          ? LayoutBuilder(
                              builder: (context, constraints) =>
                                  SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.person_search_rounded,
                                          size: 80,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                              .withValues(alpha: 0.2),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No user found online',
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
                                          onPressed: _fetchExperts,
                                          child: const Text(
                                              'Pull down to refresh'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(24),
                              itemCount:
                                  experts.length + (_isLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == experts.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                }
                                final expert = experts[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: UserCard(
                                    expert: expert,
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: _showBackToTop
          ? FloatingActionButton(
              onPressed: _scrollToTop,
              mini: true,
              child: const Icon(Icons.arrow_upward),
            )
          : null,
    );
  }
}

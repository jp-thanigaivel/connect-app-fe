import 'package:connect/components/bottom_sheet_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:connect/models/search_config.dart';

class GenericFilterBottomSheet extends StatefulWidget {
  final SearchConfig searchConfig;
  final Map<String, dynamic> initialFilters;
  final Function(Map<String, dynamic>) onApply;
  final VoidCallback onReset;

  const GenericFilterBottomSheet({
    super.key,
    required this.searchConfig,
    required this.initialFilters,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<GenericFilterBottomSheet> createState() =>
      _GenericFilterBottomSheetState();
}

class _GenericFilterBottomSheetState extends State<GenericFilterBottomSheet> {
  late Map<String, dynamic> _currentFilters;

  @override
  void initState() {
    super.initState();
    _currentFilters = Map.from(widget.initialFilters);
  }

  void _updateFilter(String key, dynamic value) {
    setState(() {
      if (value == null) {
        _currentFilters.remove(key);
      } else {
        _currentFilters[key] = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupedFilters = widget.searchConfig.groupedFilters;

    return BottomSheetWrapper(
      title: 'Filters & Sort',
      footer: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _currentFilters.clear();
                  _currentFilters['sort'] = 'name';
                });
                widget.onReset();
              },
              child: const Text('Reset'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () => widget.onApply(_currentFilters),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          ...groupedFilters.map((group) => _buildFilterGroup(group)),
          if (widget.searchConfig.sortConditions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Sort By',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.searchConfig.sortConditions.entries.map((entry) {
                final isSelected = _currentFilters['sort'] == entry.key;
                return FilterChip(
                  label: Text(entry.key),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      _updateFilter('sort', entry.key);
                    }
                  },
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainer,
                  selectedColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onSecondaryContainer
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFilterGroup(FilterGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          group.displayName,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 12),
        if (group.isRange)
          _buildRangeSlider(group)
        else if (group.conditions.any((c) => c.allowedValues != null))
          _buildCheckboxList(group)
        else if (group.isNullCheck)
          _buildRadioList(group)
        else
          _buildChipsList(group),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRangeSlider(FilterGroup group) {
    // Range slider for field. Assume min/max provided in one of the conditions or defaults.
    final eqWithValues = group.conditions.where((c) => c.allowedValues != null);

    double min = 0;
    double max = 100;

    if (eqWithValues.isNotEmpty) {
      final condition = eqWithValues.first;
      final minVal = condition.allowedValues!.firstWhere(
        (v) => v.display == 'min',
        orElse: () => AllowedValue(display: 'min', value: 0),
      );
      final maxVal = condition.allowedValues!.firstWhere(
        (v) => v.display == 'max',
        orElse: () => AllowedValue(display: 'max', value: 100),
      );
      min = (minVal.value as num?)?.toDouble() ?? 0.0;
      max = (maxVal.value as num?)?.toDouble() ?? 100.0;
    }

    // Find current values from _currentFilters
    String? gtKey;
    String? ltKey;

    for (final c in group.conditions) {
      if (c.filterType == '__gt' || c.filterType == '__gte') gtKey = c.key;
      if (c.filterType == '__lt' || c.filterType == '__lte') ltKey = c.key;
    }

    // Fallback if keys not found (unlikely but safe)
    gtKey ??= group.conditions.first.key;
    ltKey ??= group.conditions.last.key;

    double currentMin = (_currentFilters[gtKey] as num?)?.toDouble() ?? min;
    double currentMax = (_currentFilters[ltKey] as num?)?.toDouble() ?? max;

    // Ensure values are within bounds
    currentMin = currentMin.clamp(min, max);
    currentMax = currentMax.clamp(min, max);
    if (currentMin > currentMax) currentMin = currentMax;

    return Column(
      children: [
        RangeSlider(
          values: RangeValues(currentMin, currentMax),
          min: min,
          max: max,
          divisions: (max - min).toInt() > 0 ? (max - min).toInt() : 1,
          labels: RangeLabels(
            currentMin.round().toString(),
            currentMax.round().toString(),
          ),
          onChanged: (values) {
            setState(() {
              _currentFilters[gtKey!] = values.start.round();
              _currentFilters[ltKey!] = values.end.round();
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${min.round()}'),
              Text('${max.round()}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxList(FilterGroup group) {
    // We'll use the first condition that has allowedValues
    final condition =
        group.conditions.firstWhere((c) => c.allowedValues != null);
    final allowedValues = condition.allowedValues ?? [];
    final bool isMultiSelect = condition.filterType == '__in';

    dynamic currentVal = _currentFilters[condition.key];
    List<dynamic> selectedValues = [];
    if (currentVal is List) {
      selectedValues = List.from(currentVal);
    } else if (currentVal != null) {
      selectedValues = [currentVal];
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: allowedValues.map((val) {
        final isSelected = selectedValues.contains(val.value);
        return _buildSelectionBox(
          label: val.display,
          isSelected: isSelected,
          onTap: () {
            setState(() {
              if (isMultiSelect) {
                // Multi-select logic
                if (!isSelected) {
                  selectedValues.add(val.value);
                } else {
                  selectedValues.remove(val.value);
                }
                if (selectedValues.isEmpty) {
                  _currentFilters.remove(condition.key);
                } else {
                  _currentFilters[condition.key] = selectedValues;
                }
              } else {
                // Single-select logic (eq)
                if (isSelected) {
                  _currentFilters.remove(condition.key);
                } else {
                  _currentFilters[condition.key] = val.value;
                }
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildRadioList(FilterGroup group) {
    final condition =
        group.conditions.firstWhere((c) => c.filterType == '__isnull');
    final currentValue = _currentFilters[condition.key];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildSelectionBox(
          label: 'All',
          isSelected: currentValue == null,
          onTap: () => _updateFilter(condition.key, null),
        ),
        _buildSelectionBox(
          label: 'Yes',
          isSelected: currentValue == true,
          onTap: () => _updateFilter(condition.key, true),
        ),
        _buildSelectionBox(
          label: 'No',
          isSelected: currentValue == false,
          onTap: () => _updateFilter(condition.key, false),
        ),
      ],
    );
  }

  Widget _buildChipsList(FilterGroup group) {
    final condition = group.conditions.first;
    final allowedValues = condition.allowedValues ?? [];
    final currentValue = _currentFilters[condition.key];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: allowedValues.map((val) {
        final isSelected = currentValue == val.value;
        return _buildSelectionBox(
          label: val.display,
          isSelected: isSelected,
          onTap: () =>
              _updateFilter(condition.key, isSelected ? null : val.value),
        );
      }).toList(),
    );
  }

  Widget _buildSelectionBox({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(
                Icons.check_circle,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

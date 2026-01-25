class SearchConfig {
  final Map<String, FilterCondition> filterConditions;
  final Map<String, SortCondition> sortConditions;

  SearchConfig({
    required this.filterConditions,
    required this.sortConditions,
  });

  factory SearchConfig.fromJson(Map<String, dynamic> json) {
    final filters = json['filterConditions'] as Map<String, dynamic>? ?? {};
    final sorts = json['sortConditions'] as Map<String, dynamic>? ?? {};

    return SearchConfig(
      filterConditions: filters.map<String, FilterCondition>(
        (key, value) =>
            MapEntry(key, FilterCondition.fromJson(value, key: key)),
      ),
      sortConditions: sorts.map<String, SortCondition>(
        (key, value) => MapEntry(key, SortCondition.fromJson(value, key: key)),
      ),
    );
  }

  List<FilterGroup> get groupedFilters {
    final groups = <String, List<FilterCondition>>{};
    for (final condition in filterConditions.values) {
      groups.putIfAbsent(condition.field, () => []).add(condition);
    }

    return groups.entries.map((entry) {
      return FilterGroup(
        field: entry.key,
        conditions: entry.value,
      );
    }).toList();
  }
}

class FilterGroup {
  final String field;
  final List<FilterCondition> conditions;

  FilterGroup({required this.field, required this.conditions});

  String get displayName {
    // Convert field name to camel case or a nice display name
    // e.g., "expertiseTags" -> "Expertise Tags"
    // e.g., "pricePerMinute.price" -> "Price"
    String name = field.split('.').last;
    if (name.isEmpty) return field;

    // Expert specific mappings or general regex
    if (name == 'expertiseTags') return 'Expertise';

    final result = name.replaceAllMapped(RegExp(r'([A-Z])'), (match) {
      return ' ${match.group(0)}';
    });
    return result[0].toUpperCase() + result.substring(1);
  }

  bool get isRange {
    return conditions.any((c) =>
        c.filterType == '__gt' ||
        c.filterType == '__lt' ||
        c.filterType == '__gte' ||
        c.filterType == '__lte');
  }

  bool get isInArray {
    return conditions.any((c) => c.filterType == '__in');
  }

  bool get isNullCheck {
    return conditions.any((c) => c.filterType == '__isnull');
  }
}

class FilterCondition {
  final String key;
  final String filterType;
  final String filterOpr;
  final String field;
  final String fieldType;
  final List<AllowedValue>? allowedValues;

  FilterCondition({
    required this.key,
    required this.filterType,
    required this.filterOpr,
    required this.field,
    required this.fieldType,
    this.allowedValues,
  });

  factory FilterCondition.fromJson(Map<String, dynamic> json,
      {String key = ''}) {
    return FilterCondition(
      key: key,
      filterType: json['filter_type'] ?? '',
      filterOpr: json['filter_opr'] ?? '',
      field: json['field'] ?? '',
      fieldType: json['field_type'] ?? '',
      allowedValues: (json['allowedValues'] as List?)
          ?.map((e) => AllowedValue.fromJson(e))
          .toList(),
    );
  }
}

class AllowedValue {
  final String display;
  final dynamic value;

  AllowedValue({required this.display, required this.value});

  factory AllowedValue.fromJson(Map<String, dynamic> json) {
    return AllowedValue(
      display: json['display'] ?? '',
      value: json['value'],
    );
  }
}

class SortCondition {
  final String key;
  final String sortType;
  final String sortOpr;
  final String field;
  final String fieldType;

  SortCondition({
    required this.key,
    required this.sortType,
    required this.sortOpr,
    required this.field,
    required this.fieldType,
  });

  factory SortCondition.fromJson(Map<String, dynamic> json, {String key = ''}) {
    return SortCondition(
      key: key,
      sortType: json['sort_type'] ?? '',
      sortOpr: json['sort_opr'] ?? '',
      field: json['field'] ?? '',
      fieldType: json['field_type'] ?? '',
    );
  }
}

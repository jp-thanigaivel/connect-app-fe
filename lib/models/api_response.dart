class ApiResponse<T> {
  final ApiStatus status;
  final T? data;
  final ApiPagination? pagination;

  ApiResponse({
    required this.status,
    this.data,
    this.pagination,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    return ApiResponse(
      status: ApiStatus.fromJson(json['status']),
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      pagination: json['pagination'] != null
          ? ApiPagination.fromJson(json['pagination'])
          : null,
    );
  }
}

class ApiStatus {
  final String statusCode;
  final String statusType;
  final String statusDesc;

  ApiStatus({
    required this.statusCode,
    required this.statusType,
    required this.statusDesc,
  });

  factory ApiStatus.fromJson(Map<String, dynamic> json) {
    return ApiStatus(
      statusCode: (json['statusCode'] ?? json['errorCode'])?.toString() ?? '',
      statusType: json['statusType'] ?? '',
      statusDesc: json['statusDesc'] ?? '',
    );
  }

  bool get isSuccess =>
      (statusCode == '200' || statusCode == '201') && statusType == 'SUCCESS';
}

class ApiPagination {
  final int? count;
  final String? nextPage;
  final String? previousPage;
  final int? totalCount;

  ApiPagination({
    this.count,
    this.nextPage,
    this.previousPage,
    this.totalCount,
  });

  factory ApiPagination.fromJson(Map<String, dynamic> json) {
    return ApiPagination(
      count: json['count'],
      nextPage: json['nextPage'],
      previousPage: json['previousPage'],
      totalCount: json['totalCount'],
    );
  }
}

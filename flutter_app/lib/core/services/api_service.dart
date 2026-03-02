import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import 'storage_service.dart';

class ApiService {
  static late Dio _dio;
  static String? _authToken;

  static void init() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(milliseconds: 30000),
      receiveTimeout: const Duration(milliseconds: 30000),
      sendTimeout: const Duration(milliseconds: 30000),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors
    _dio.interceptors.add(_AuthInterceptor());
    _dio.interceptors.add(_LoggingInterceptor());
    _dio.interceptors.add(_ErrorInterceptor());
  }

  // Set auth token
  static void setAuthToken(String token) {
    _authToken = token;
  }

  // Clear auth token
  static void clearAuthToken() {
    _authToken = null;
  }

  // GET request
  static Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // POST request
  static Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // PUT request
  static Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // PATCH request
  static Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE request
  static Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Upload file
  static Future<Response<T>> uploadFile<T>(
    String path,
    String filePath, {
    String? fileName,
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        ...?data,
      });

      return await _dio.post<T>(
        path,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
        onSendProgress: onSendProgress,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Download file
  static Future<Response> downloadFile(
    String path,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.download(
        path,
        savePath,
        queryParameters: queryParameters,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Handle errors
  static ApiException _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return ApiException(
            message: 'Connection timeout. Please check your internet connection.',
            statusCode: 408,
            type: ApiExceptionType.timeout,
          );
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode ?? 0;
          final message = _getErrorMessage(error.response?.data);
          return ApiException(
            message: message,
            statusCode: statusCode,
            type: _getExceptionType(statusCode),
            data: error.response?.data,
          );
        case DioExceptionType.cancel:
          return ApiException(
            message: 'Request was cancelled',
            statusCode: 0,
            type: ApiExceptionType.cancel,
          );
        case DioExceptionType.connectionError:
          return ApiException(
            message: 'No internet connection',
            statusCode: 0,
            type: ApiExceptionType.network,
          );
        default:
          return ApiException(
            message: 'An unexpected error occurred',
            statusCode: 0,
            type: ApiExceptionType.unknown,
          );
      }
    }
    return ApiException(
      message: error.toString(),
      statusCode: 0,
      type: ApiExceptionType.unknown,
    );
  }

  static String _getErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data.containsKey('detail')) {
        final detail = data['detail'];
        if (detail is String) {
          return detail;
        } else if (detail is List && detail.isNotEmpty) {
          return detail.first['msg'] ?? 'Validation error';
        }
      }
      if (data.containsKey('message')) {
        return data['message'];
      }
      if (data.containsKey('error')) {
        return data['error'];
      }
    }
    return 'An error occurred';
  }

  static ApiExceptionType _getExceptionType(int statusCode) {
    if (statusCode >= 400 && statusCode < 500) {
      return ApiExceptionType.client;
    } else if (statusCode >= 500) {
      return ApiExceptionType.server;
    }
    return ApiExceptionType.unknown;
  }
}

// Auth Interceptor
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Add auth token if available
    if (ApiService._authToken != null) {
      options.headers['Authorization'] = 'Bearer ${ApiService._authToken}';
    } else {
      // Try to get token from storage
      final token = await StorageService.getAuthToken();
      if (token != null) {
        ApiService.setAuthToken(token);
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 errors by clearing tokens
    if (err.response?.statusCode == 401) {
      // Clear all tokens since we don't have refresh token functionality
      await StorageService.clearAuthToken();
      await StorageService.clearRefreshToken();
      ApiService.clearAuthToken();
      
      // Log the authentication error
      if (kDebugMode) {
        debugPrint('Authentication failed - tokens cleared. User needs to log in again.');
      }
    }
    handler.next(err);
  }
}

// Logging Interceptor
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('REQUEST[${options.method}] => PATH: ${options.path}');
      debugPrint('Headers: ${options.headers}');
      debugPrint('Data: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
      debugPrint('Data: ${response.data}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}');
      debugPrint('Message: ${err.message}');
      debugPrint('Data: ${err.response?.data}');
    }
    handler.next(err);
  }
}

// Error Interceptor
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Log error to analytics or crash reporting service
    // FirebaseCrashlytics.instance.recordError(err, null);
    handler.next(err);
  }
}

// API Exception
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final ApiExceptionType type;
  final dynamic data;

  ApiException({
    required this.message,
    required this.statusCode,
    required this.type,
    this.data,
  });

  @override
  String toString() {
    return 'ApiException: $message (Status: $statusCode)';
  }
}

enum ApiExceptionType {
  network,
  timeout,
  server,
  client,
  cancel,
  unknown,
}

// API Response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
    this.errors,
  });

  factory ApiResponse.success(T data, {String? message, int? statusCode}) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.error(String message, {int? statusCode, Map<String, dynamic>? errors}) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
      errors: errors,
    );
  }

  factory ApiResponse.fromResponse(Response response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return ApiResponse(
        success: response.statusCode! >= 200 && response.statusCode! < 300,
        data: data['data'] as T?,
        message: data['message'] as String?,
        statusCode: response.statusCode,
      );
    }
    return ApiResponse(
      success: response.statusCode! >= 200 && response.statusCode! < 300,
      data: data as T?,
      statusCode: response.statusCode,
    );
  }
}

// Pagination wrapper
class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  PaginatedResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final itemsJson = json['items'] as List<dynamic>;
    final items = itemsJson.map((item) => fromJson(item as Map<String, dynamic>)).toList();

    return PaginatedResponse(
      items: items,
      total: json['total'] as int,
      page: json['page'] as int,
      pageSize: json['page_size'] as int,
      totalPages: json['total_pages'] as int,
      hasNext: json['has_next'] as bool,
      hasPrevious: json['has_previous'] as bool,
    );
  }
}

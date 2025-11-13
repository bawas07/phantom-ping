import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, FormData;

import '../constants/api_constants.dart';
import '../services/storage_service.dart';
import '../utils/logger.dart';
import 'api_exception.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// Dio-based HTTP client for API communication
/// Handles authentication, logging, and error handling
class ApiClient extends GetxService {
  late final Dio _dio;
  final Logger _logger = Logger('ApiClient');
  final StorageService _storageService = Get.find<StorageService>();

  Dio get dio => _dio;

  @override
  void onInit() {
    super.onInit();
    _initializeDio();
  }

  /// Initialize Dio instance with configuration and interceptors
  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) {
          // Accept all status codes to handle them in interceptors
          return status != null && status < 500;
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.addAll([
      AuthInterceptor(_storageService, _dio),
      LoggingInterceptor(),
    ]);
  }

  /// Perform GET request
  ///
  /// [path] - API endpoint path
  /// [queryParameters] - Optional query parameters
  /// [options] - Optional request options
  ///
  /// Returns response data or throws ApiException
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse<T>(response);
    } on DioException catch (e) {
      throw ApiExceptionHandler.handleDioException(e);
    } catch (e) {
      _logger.error('Unexpected error in GET request', e);
      throw UnknownException(e.toString());
    }
  }

  /// Perform POST request
  ///
  /// [path] - API endpoint path
  /// [data] - Request body data
  /// [queryParameters] - Optional query parameters
  /// [options] - Optional request options
  ///
  /// Returns response data or throws ApiException
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse<T>(response);
    } on DioException catch (e) {
      throw ApiExceptionHandler.handleDioException(e);
    } catch (e) {
      _logger.error('Unexpected error in POST request', e);
      throw UnknownException(e.toString());
    }
  }

  /// Perform PUT request
  ///
  /// [path] - API endpoint path
  /// [data] - Request body data
  /// [queryParameters] - Optional query parameters
  /// [options] - Optional request options
  ///
  /// Returns response data or throws ApiException
  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse<T>(response);
    } on DioException catch (e) {
      throw ApiExceptionHandler.handleDioException(e);
    } catch (e) {
      _logger.error('Unexpected error in PUT request', e);
      throw UnknownException(e.toString());
    }
  }

  /// Perform PATCH request
  ///
  /// [path] - API endpoint path
  /// [data] - Request body data
  /// [queryParameters] - Optional query parameters
  /// [options] - Optional request options
  ///
  /// Returns response data or throws ApiException
  Future<T> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse<T>(response);
    } on DioException catch (e) {
      throw ApiExceptionHandler.handleDioException(e);
    } catch (e) {
      _logger.error('Unexpected error in PATCH request', e);
      throw UnknownException(e.toString());
    }
  }

  /// Perform DELETE request
  ///
  /// [path] - API endpoint path
  /// [data] - Optional request body data
  /// [queryParameters] - Optional query parameters
  /// [options] - Optional request options
  ///
  /// Returns response data or throws ApiException
  Future<T> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse<T>(response);
    } on DioException catch (e) {
      throw ApiExceptionHandler.handleDioException(e);
    } catch (e) {
      _logger.error('Unexpected error in DELETE request', e);
      throw UnknownException(e.toString());
    }
  }

  /// Handle response and extract data
  T _handleResponse<T>(Response<T> response) {
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      return response.data as T;
    }

    // Handle error responses
    throw ApiExceptionHandler.handleDioException(
      DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      ),
    );
  }
}

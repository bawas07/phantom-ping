import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../services/storage_service.dart';

class DioClient {
  late final Dio _dio;
  final StorageService _storageService = StorageService();

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add access token to requests
          final token = await _storageService.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 errors by attempting token refresh
          if (error.response?.statusCode == 401) {
            try {
              final refreshToken = await _storageService.getRefreshToken();
              if (refreshToken != null) {
                // Attempt to refresh the token
                final response = await _dio.post(
                  ApiConstants.refreshEndpoint,
                  data: {'refreshToken': refreshToken},
                  options: Options(
                    headers: {'Authorization': null}, // Don't send old token
                  ),
                );

                if (response.statusCode == 200) {
                  final newAccessToken = response.data['accessToken'] as String;
                  final newRefreshToken =
                      response.data['refreshToken'] as String;

                  // Save new tokens
                  await _storageService.saveAccessToken(newAccessToken);
                  await _storageService.saveRefreshToken(newRefreshToken);

                  // Retry the original request with new token
                  error.requestOptions.headers['Authorization'] =
                      'Bearer $newAccessToken';
                  final retryResponse = await _dio.fetch(error.requestOptions);
                  return handler.resolve(retryResponse);
                }
              }
            } catch (e) {
              // If refresh fails, clear tokens and propagate error
              await _storageService.clearAll();
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;
}

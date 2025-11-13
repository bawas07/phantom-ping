import 'package:dio/dio.dart';

import '../../utils/logger.dart';

/// Interceptor for logging HTTP requests and responses
/// Only logs in debug mode
class LoggingInterceptor extends Interceptor {
  final Logger _logger = Logger('HTTP');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.debug('→ ${options.method} ${options.uri}');
    _logger.debug('Headers: ${options.headers}');
    if (options.data != null) {
      _logger.debug('Body: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.debug(
      '← ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}',
    );
    _logger.debug('Response: ${response.data}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.error(
      '✗ ${err.requestOptions.method} ${err.requestOptions.uri}',
      err,
    );
    if (err.response != null) {
      _logger.error('Status: ${err.response?.statusCode}');
      _logger.error('Data: ${err.response?.data}');
    }
    handler.next(err);
  }
}

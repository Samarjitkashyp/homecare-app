import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:homecare_app/core/constants/app_constants.dart';
import 'package:homecare_app/core/utils/secure_store.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // ✅ Check if Authorization header is already set manually
    // If it is (e.g. from AdminDataProvider), don't overwrite it with the caregiver token
    if (!options.headers.containsKey('Authorization')) {
      final token = await SecureStore.read(AppConstants.tokenKey);

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    // Add CORS headers if needed
    options.headers['Access-Control-Allow-Origin'] = '*';

    // Add Origin header for web
    if (options.extra['fromWeb'] == true) {
      options.headers['Origin'] = 'http://localhost:64891';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle token expiration
    if (err.response?.statusCode == 401) {
      debugPrint('🔴 AuthInterceptor: 401 Unauthorized detected');
      // Only clear if it's NOT an admin request (optional: check URL)
      if (!err.requestOptions.path.contains('admin')) {
        _handleTokenExpired();
      }
    }

    // Handle CORS errors
    if (err.type == DioExceptionType.connectionError &&
        err.message?.contains('CORS') == true) {
      debugPrint('🔴 CORS Error in AuthInterceptor: ${err.message}');

      // Try without auth if CORS issue
      if (err.requestOptions.headers.containsKey('Authorization')) {
        err.requestOptions.headers.remove('Authorization');

        // Retry the request without auth
        _retryWithoutAuth(err, handler);
        return;
      }
    }

    return handler.next(err);
  }

  // Separate method for retry logic
  void _retryWithoutAuth(DioException err, ErrorInterceptorHandler handler) {
    try {
      // Create new Dio instance
      final dio = Dio();

      // Fetch with modified options
      dio.fetch(err.requestOptions).then((response) {
        handler.resolve(response);
      }).catchError((error) {
        debugPrint('🔴 Retry failed: $error');
        handler.next(err);
      });
    } catch (e) {
      debugPrint('🔴 Retry exception: $e');
      handler.next(err);
    }
  }

  void _handleTokenExpired() async {
    try {
      // Only clear the caregiver token
      await SecureStore.delete(AppConstants.tokenKey);
      debugPrint('🟢 AuthInterceptor: Caregiver token cleared due to expiration');
    } catch (e) {
      debugPrint('🔴 AuthInterceptor: Error clearing token: $e');
    }
  }
}

import 'package:homecare_app/core/utils/app_logger.dart';
import 'package:dio/dio.dart';
import 'package:homecare_app/core/network/dio_client.dart';
import 'package:homecare_app/core/constants/api_endpoints.dart';
import 'package:homecare_app/models/response_model.dart';

class ApiService {
  final Dio _dio = DioClient.instance;
  final Dio _unAuthDio = DioClient.unAuthInstance;

  // Public getters
  Dio get dio => _dio;
  Dio get unAuthDio => _unAuthDio;

  // ============ AUTH ============
  Future<ResponseModel> login(String email, String password) async {
    try {
      AppLogger.d('🟡 API Service: Sending login request');
      AppLogger.d('📧 Email: $email');
      AppLogger.d('🔗 URL: ${ApiEndpoints.getFullUrl(ApiEndpoints.login)}');

      final response = await _unAuthDio.post(
        ApiEndpoints.login,
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      AppLogger.d('🟢 API Service: Response received');
      AppLogger.d('📊 Status Code: ${response.statusCode}');
      AppLogger.d('📝 Response Data: ${response.data}');

      return ResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      AppLogger.d('🔴 API Service: DioException caught');
      AppLogger.d('🔴 Error Type: ${e.type}');
      AppLogger.d('🔴 Error Message: ${e.message}');
      AppLogger.d('🔴 Response: ${e.response?.data}');
      AppLogger.d('🔴 Request URL: ${e.requestOptions.uri}');
      return _handleError(e);
    } catch (e) {
      AppLogger.d('🔴 API Service: Unknown error: $e');
      return ResponseModel(
        status: false,
        message: 'Unexpected error: $e',
        data: null,
      );
    }
  }

  Future<ResponseModel> logout() async {
    try {
      final response = await _dio.post(ApiEndpoints.logout);
      return ResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ============ TIME ============
  Future<ResponseModel> timeIn(int policyholderId, String date, String timeIn) async {
    try {
      AppLogger.d('🟡 API Service: Sending timeIn request');
      AppLogger.d('📋 Policyholder ID: $policyholderId');
      AppLogger.d('📅 Date: $date');
      AppLogger.d('⏰ Time: $timeIn');
      AppLogger.d('🔗 URL: ${ApiEndpoints.getFullUrl(ApiEndpoints.timeIn)}');

      final response = await _dio.post(
        ApiEndpoints.timeIn,
        data: {
          'policyholder_id': policyholderId,
          'date': date,
          'time_in': timeIn,
        },
      );

      AppLogger.d('🟢 API Service: TimeIn response received');
      AppLogger.d('📊 Status Code: ${response.statusCode}');
      AppLogger.d('📝 Response Data: ${response.data}');

      return ResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      AppLogger.d('🔴 API Service: DioException - ${e.message}');
      AppLogger.d('🔴 Response: ${e.response?.data}');
      AppLogger.d('🔴 Request URL: ${e.requestOptions.uri}');
      return _handleError(e);
    } catch (e) {
      AppLogger.d('🔴 API Service: Unknown error - $e');
      return ResponseModel(
        status: false,
        message: 'Unexpected error: $e',
        data: null,
      );
    }
  }

  Future<ResponseModel> timeOut(String timeOut, double rate) async {
    try {
      AppLogger.d('🟡 API Service: Sending timeOut request');
      AppLogger.d('⏰ Time Out: $timeOut');
      AppLogger.d('💰 Rate: $rate');
      AppLogger.d('🔗 URL: ${ApiEndpoints.getFullUrl(ApiEndpoints.timeOut)}');

      final response = await _dio.post(
        ApiEndpoints.timeOut,
        data: {
          'time_out': timeOut,
          'rate': rate,
        },
      );
      
      AppLogger.d('🟢 API Service: TimeOut response received');
      AppLogger.d('📊 Status Code: ${response.statusCode}');
      AppLogger.d('📝 Response Data: ${response.data}');

      return ResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      AppLogger.d('🔴 API Service: TimeOut error - ${e.message}');
      AppLogger.d('🔴 Request URL: ${e.requestOptions.uri}');
      return _handleError(e);
    }
  }

  Future<ResponseModel> getTodayLog(String date) async {
    try {
      AppLogger.d('🟡 API Service: Fetching today\'s log');
      AppLogger.d('📅 Date: $date');
      AppLogger.d('🔗 URL: ${ApiEndpoints.getFullUrl(ApiEndpoints.todayLog)}');

      final response = await _dio.get(
        ApiEndpoints.todayLog,
        queryParameters: {'date': date},
      );

      AppLogger.d('🟢 API Service: TodayLog response received');
      AppLogger.d('📊 Status Code: ${response.statusCode}');
      AppLogger.d('📝 Response Data: ${response.data}');

      return ResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      AppLogger.d('🔴 API Service: TodayLog error - ${e.message}');
      return _handleError(e);
    }
  }

  // ============ PROGRESS ============
  Future<ResponseModel> saveDailyProgress(Map<String, dynamic> data) async {
    try {
      AppLogger.d('🟡 API Service: Saving daily progress');
      AppLogger.d('📊 Data: $data');
      AppLogger.d('🔗 URL: ${ApiEndpoints.getFullUrl(ApiEndpoints.saveDaily)}');

      final response = await _dio.post(
        ApiEndpoints.saveDaily,
        data: data,
      );
      
      AppLogger.d('🟢 API Service: SaveDaily response received');
      AppLogger.d('📊 Status Code: ${response.statusCode}');
      AppLogger.d('📝 Response Data: ${response.data}');

      return ResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      AppLogger.d('🔴 API Service: SaveDaily error - ${e.message}');
      return _handleError(e);
    }
  }

  Future<ResponseModel> getDailyProgress(int timeEntryId) async {
    try {
      AppLogger.d('🟡 API Service: Fetching daily progress');
      AppLogger.d('🆔 Time Entry ID: $timeEntryId');
      AppLogger.d('🔗 URL: ${ApiEndpoints.getFullUrl(ApiEndpoints.getDaily)}');

      final response = await _dio.get(
        ApiEndpoints.getDaily,
        queryParameters: {'time_entry_id': timeEntryId},
      );

      AppLogger.d('🟢 API Service: GetDaily response received');
      AppLogger.d('📊 Status Code: ${response.statusCode}');
      AppLogger.d('📝 Response Data: ${response.data}');

      return ResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      AppLogger.d('🔴 API Service: GetDaily error - ${e.message}');
      return _handleError(e);
    }
  }

  // ============ REPORT ============
  Future<ResponseModel> generateReport(int timeEntryId) async {
    try {
      AppLogger.d('🟡 API Service: Generating report');
      AppLogger.d('🆔 Time Entry ID: $timeEntryId');
      AppLogger.d('🔗 URL: ${ApiEndpoints.getFullUrl(ApiEndpoints.generateReport)}');

      final response = await _dio.post(
        ApiEndpoints.generateReport,
        data: {'time_entry_id': timeEntryId},
      );

      AppLogger.d('🟢 API Service: GenerateReport response received');
      AppLogger.d('📊 Status Code: ${response.statusCode}');
      AppLogger.d('📝 Response Data: ${response.data}');

      return ResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      AppLogger.d('🔴 API Service: GenerateReport error - ${e.message}');
      return _handleError(e);
    }
  }

  Future<ResponseModel> getReport(int timeEntryId) async {
    try {
      AppLogger.d('🟡 API Service: Fetching report');
      AppLogger.d('🆔 Time Entry ID: $timeEntryId');
      AppLogger.d('🔗 URL: ${ApiEndpoints.getFullUrl(ApiEndpoints.getReport)}');

      final response = await _dio.get(
        ApiEndpoints.getReport,
        queryParameters: {'entry_id': timeEntryId},
      );

      AppLogger.d('🟢 API Service: GetReport response received');
      AppLogger.d('📊 Status Code: ${response.statusCode}');
      AppLogger.d('📝 Response Data: ${response.data}');

      return ResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      AppLogger.d('🔴 API Service: GetReport error - ${e.message}');
      return _handleError(e);
    }
  }

  // ============ SIGNATURE ============
  Future<ResponseModel> saveSignature(Map<String, dynamic> data) async {
    try {
      AppLogger.d('🟡 API Service: Saving signature');
      AppLogger.d('📊 Data: $data');
      AppLogger.d('🔗 URL: ${ApiEndpoints.getFullUrl(ApiEndpoints.saveSignature)}');

      final response = await _dio.post(
        ApiEndpoints.saveSignature,
        data: data,
      );

      AppLogger.d('🟢 API Service: SaveSignature response received');
      AppLogger.d('📊 Status Code: ${response.statusCode}');
      AppLogger.d('📝 Response Data: ${response.data}');

      return ResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      AppLogger.d('🔴 API Service: SaveSignature error - ${e.message}');
      return _handleError(e);
    }
  }

  Future<ResponseModel> getSignature(int timeEntryId) async {
    try {
      AppLogger.d('🟡 API Service: Fetching signatures for entry: $timeEntryId');
      AppLogger.d('🔗 URL: ${ApiEndpoints.getFullUrl(ApiEndpoints.getSignature)}');

      final response = await _dio.get(
        ApiEndpoints.getSignature,
        queryParameters: {'time_entry_id': timeEntryId},
      );

      AppLogger.d('🟢 API Service: GetSignature response received');
      AppLogger.d('📊 Status Code: ${response.statusCode}');
      AppLogger.d('📝 Response Data: ${response.data}');

      return ResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      AppLogger.d('🔴 API Service: GetSignature error - ${e.message}');
      return _handleError(e);
    }
  }

  // ============ ADMIN APIs ============
  // ✅ Add admin-specific APIs with debug logs
  Future<ResponseModel> adminLogin(String email, String password) async {
    try {
      AppLogger.d('🟡 API Service: Admin login request');
      AppLogger.d('📧 Email: $email');
      AppLogger.d('🔗 URL: ${ApiEndpoints.getFullUrl('api/admin/login.php')}');

      final response = await _unAuthDio.post(
        'api/admin/login.php',
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      AppLogger.d('🟢 API Service: Admin login response received');
      AppLogger.d('📊 Status Code: ${response.statusCode}');
      AppLogger.d('📝 Response Data: ${response.data}');

      return ResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      AppLogger.d('🔴 API Service: Admin login error - ${e.message}');
      AppLogger.d('🔴 Request URL: ${e.requestOptions.uri}');
      return _handleError(e);
    }
  }

  // ============ ERROR HANDLER ============
  ResponseModel _handleError(DioException error) {
    String message = 'Something went wrong';

    AppLogger.d('🔴 ========== ERROR DETAILS ==========');
    AppLogger.d('🔴 Error Type: ${error.type}');
    AppLogger.d('🔴 Error Message: ${error.message}');
    AppLogger.d('🔴 Request URL: ${error.requestOptions.uri}');
    AppLogger.d('🔴 Request Method: ${error.requestOptions.method}');
    AppLogger.d('🔴 Request Headers: ${error.requestOptions.headers}');
    AppLogger.d('🔴 Request Data: ${error.requestOptions.data}');
    
    if (error.response != null) {
      AppLogger.d('🔴 Response Status: ${error.response?.statusCode}');
      AppLogger.d('🔴 Response Data: ${error.response?.data}');
      AppLogger.d('🔴 Response Headers: ${error.response?.headers}');
      
      try {
        final data = error.response?.data;
        if (data is Map<String, dynamic> && data.containsKey('message')) {
          message = data['message'] as String;
        } else if (data is String) {
          message = data;
        } else {
          message = error.response?.statusMessage ?? 'Server error';
        }
      } catch (e) {
        message = 'Server error: ${error.response?.statusCode}';
      }
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timeout. Please check your internet.';
    } else if (error.type == DioExceptionType.connectionError) {
      message = 'No internet connection. Please check your network.';
    } else if (error.type == DioExceptionType.unknown) {
      if (error.message != null &&
          (error.message!.contains('CORS') ||
              error.message!.contains('Access-Control-Allow-Origin'))) {
        message = 'CORS error. Please check server configuration.';
      } else {
        message = error.message ?? 'Unknown network error';
      }
    } else {
      message = error.message ?? 'Unknown error occurred';
    }

    AppLogger.d('🔴 Final Error Message: $message');
    AppLogger.d('🔴 =====================================');

    return ResponseModel(
      status: false,
      message: message,
      data: null,
    );
  }
}
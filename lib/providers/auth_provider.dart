import 'package:homecare_app/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:homecare_app/core/constants/app_constants.dart';
import 'package:homecare_app/core/network/api_service.dart';
import 'package:homecare_app/models/response_model.dart';
import 'package:homecare_app/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  UserModel? _user;
  String? _token;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  AuthProvider() {
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(AppConstants.tokenKey);

      if (_token != null && _token!.isNotEmpty) {
        final role = prefs.getString('user_role') ?? '';

        // ✅ Only load if role is caregiver
        if (role == 'caregiver') {
          _isAuthenticated = true;
          _user = UserModel(
            id: prefs.getInt(AppConstants.userIdKey) ?? 0,
            name: prefs.getString(AppConstants.userNameKey) ?? '',
            email: prefs.getString(AppConstants.userEmailKey) ?? '',
          );
          AppLogger.d('✅ AuthProvider: Loaded caregiver: ${_user?.name}');
        } else {
          AppLogger.d('🟡 AuthProvider: Invalid role "$role", clearing caregiver data');
          _token = null;
          _isAuthenticated = false;
          _user = null;

          await prefs.remove(AppConstants.tokenKey);
          await prefs.remove(AppConstants.userIdKey);
          await prefs.remove(AppConstants.userNameKey);
          await prefs.remove(AppConstants.userEmailKey);
          await prefs.remove('user_role');
        }
      } else {
        AppLogger.d('🟡 AuthProvider: No token found');
      }
    } catch (e) {
      AppLogger.d('🔴 AuthProvider: Error loading saved data: $e');
    }
    notifyListeners();
  }

  Future<ResponseModel> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    AppLogger.d('🟡 AuthProvider: Caregiver login attempt for: $email');

    try {
      final response = await _apiService.login(email, password);

      AppLogger.d('🟢 AuthProvider: Response status: ${response.status}');
      AppLogger.d('📝 Message: ${response.message}');

      if (response.status && response.data != null) {
        try {
          final userData = response.data['user'];
          if (userData == null) {
            AppLogger.d('🔴 AuthProvider: User data is null in response');
            _isLoading = false;
            notifyListeners();
            return ResponseModel(
              status: false,
              message: 'Invalid response from server',
              data: null,
            );
          }

          final role = userData['role'] as String? ?? 'caregiver';

          // ✅ CRITICAL: Only allow caregiver login
          if (role == 'admin') {
            AppLogger.d('🔴 AuthProvider: Admin user cannot login as caregiver');
            _isLoading = false;
            notifyListeners();
            return ResponseModel(
              status: false,
              message: '❌ Invalid credentials. Please use Admin Login for admin accounts.',
              data: null,
            );
          }

          // ✅ Only allow caregiver role
          if (role != 'caregiver') {
            AppLogger.d('🔴 AuthProvider: Invalid role for caregiver login: $role');
            _isLoading = false;
            notifyListeners();
            return ResponseModel(
              status: false,
              message: '❌ Invalid credentials. Please check your email and password.',
              data: null,
            );
          }

          _user = UserModel.fromJson(userData);
          _token = response.data['token'] as String;
          _isAuthenticated = true;

          final prefs = await SharedPreferences.getInstance();

          // ✅ Clear admin data when caregiver logs in
          await prefs.remove('admin_token');
          await prefs.remove('admin_id');
          await prefs.remove('admin_name');
          await prefs.remove('admin_email');
          await prefs.remove('admin_role');

          await prefs.setString(AppConstants.tokenKey, _token!);
          await prefs.setInt(AppConstants.userIdKey, _user!.id);
          await prefs.setString(AppConstants.userNameKey, _user!.name);
          await prefs.setString(AppConstants.userEmailKey, _user!.email);
          await prefs.setString('user_role', role);

          AppLogger.d('✅ AuthProvider: Caregiver login successful: ${_user!.name}');
        } catch (e) {
          AppLogger.d('🔴 AuthProvider: Error parsing data: $e');
          _isAuthenticated = false;
        }
      } else {
        AppLogger.d('🔴 AuthProvider: Login failed - ${response.message}');
      }

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      AppLogger.d('🔴 AuthProvider: Exception: $e');
      _isLoading = false;
      notifyListeners();
      return ResponseModel(
        status: false,
        message: 'Login error: $e',
        data: null,
      );
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.userNameKey);
    await prefs.remove(AppConstants.userEmailKey);
    await prefs.remove('user_role');

    _user = null;
    _token = null;
    _isAuthenticated = false;

    notifyListeners();
    AppLogger.d('✅ AuthProvider: Caregiver logged out');
  }
}
import 'package:homecare_app/core/utils/app_logger.dart';
import 'package:homecare_app/core/utils/secure_store.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:homecare_app/core/network/api_service.dart';
import 'package:homecare_app/core/constants/admin_api_endpoints.dart';
import 'package:homecare_app/core/constants/app_constants.dart';
import 'package:homecare_app/admin/models/admin_models.dart';

class AdminAuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  AdminUser? _adminUser;
  String? _token;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  AdminUser? get adminUser => _adminUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  AdminAuthProvider() {
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = await SecureStore.read('admin_token');

      if (_token != null && _token!.isNotEmpty) {
        final role = prefs.getString('admin_role') ?? '';

        // ✅ Only load if role is admin
        if (role == 'admin') {
          _isAuthenticated = true;
          _adminUser = AdminUser(
            id: prefs.getInt('admin_id') ?? 0,
            name: prefs.getString('admin_name') ?? '',
            email: prefs.getString('admin_email') ?? '',
            role: role,
          );
          AppLogger.d('✅ AdminAuthProvider: Loaded admin: ${_adminUser?.name}');
        } else {
          AppLogger.d('🟡 AdminAuthProvider: Invalid role "$role", clearing data');
          _token = null;
          await SecureStore.delete('admin_token');
          await prefs.remove('admin_id');
          await prefs.remove('admin_name');
          await prefs.remove('admin_email');
          await prefs.remove('admin_role');
        }
      }
    } catch (e) {
      AppLogger.d('Error loading admin data: $e');
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    AppLogger.d('🟡 AdminAuthProvider: Admin login attempt for: $email');

    try {
      final response = await _apiService.unAuthDio.post(
        AdminApiEndpoints.getFullUrl(AdminApiEndpoints.adminLogin),
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      final data = response.data;
      AppLogger.d('🟢 AdminAuthProvider: Response status: ${data['status']}');

      if (data['status'] == true) {
        final userData = data['data']['user'];
        final role = userData['role'] ?? '';

        // ✅ CRITICAL: Only allow admin login
        if (role != 'admin') {
          AppLogger.d('🔴 AdminAuthProvider: Non-admin user cannot login as admin');
          _isLoading = false;
          notifyListeners();
          return {
            'success': false,
            'message': '❌ Invalid credentials. Please use Caregiver Login for caregiver accounts.'
          };
        }

        _adminUser = AdminUser(
          id: userData['id'] ?? 0,
          name: userData['name'] ?? '',
          email: userData['email'] ?? '',
          role: role,
        );
        _token = data['data']['token'];
        _isAuthenticated = true;

        final prefs = await SharedPreferences.getInstance();

        // ✅ Clear caregiver data when admin logs in
        await SecureStore.delete(AppConstants.tokenKey);
        await prefs.remove(AppConstants.userIdKey);
        await prefs.remove(AppConstants.userNameKey);
        await prefs.remove(AppConstants.userEmailKey);
        await prefs.remove('user_role');

        await SecureStore.write('admin_token', _token!);
        await prefs.setInt('admin_id', _adminUser!.id);
        await prefs.setString('admin_name', _adminUser!.name);
        await prefs.setString('admin_email', _adminUser!.email);
        await prefs.setString('admin_role', _adminUser!.role);

        _isLoading = false;
        notifyListeners();
        AppLogger.d('✅ AdminAuthProvider: Admin login successful: ${_adminUser?.name}');
        return {'success': true, 'data': data['data']};
      } else {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': data['message'] ?? 'Invalid credentials'};
      }
    } catch (e) {
      AppLogger.d('🔴 AdminAuthProvider: Error: $e');
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await SecureStore.delete('admin_token');
    await prefs.remove('admin_id');
    await prefs.remove('admin_name');
    await prefs.remove('admin_email');
    await prefs.remove('admin_role');

    _adminUser = null;
    _token = null;
    _isAuthenticated = false;
    notifyListeners();
    AppLogger.d('✅ AdminAuthProvider: Admin logged out');
  }
}
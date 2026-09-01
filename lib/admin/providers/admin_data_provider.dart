import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:homecare_app/core/utils/secure_store.dart';
import 'package:homecare_app/core/network/api_service.dart';
import 'package:homecare_app/core/constants/admin_api_endpoints.dart';
import 'package:homecare_app/admin/models/admin_models.dart';

class AdminDataProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  DashboardStats? _dashboardStats;
  List<Caregiver> _caregivers = [];
  List<Policyholder> _policyholders = [];
  List<Shift> _shifts = [];

  bool get isLoading => _isLoading;
  DashboardStats? get dashboardStats => _dashboardStats;
  List<Caregiver> get caregivers => _caregivers;
  List<Policyholder> get policyholders => _policyholders;
  List<Shift> get shifts => _shifts;

  // Helper to get token
  Future<String?> _getToken() async {
    try {
      return await SecureStore.read('admin_token');
    } catch (e) {
      debugPrint('🔴 AdminDataProvider: Error getting token: $e');
      return null;
    }
  }

  // Helper to add auth header
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ============ DASHBOARD ============
  Future<void> loadDashboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      final headers = await _getHeaders();
      debugPrint('🟡 AdminDataProvider: Loading dashboard...');

      final response = await _apiService.dio.get(
        AdminApiEndpoints.getFullUrl(AdminApiEndpoints.dashboard),
        options: Options(headers: headers),
      );

      final data = response.data;
      if (data != null && data['status'] == true) {
        _dashboardStats = DashboardStats.fromJson(data['data']);
        debugPrint('🟢 AdminDataProvider: Dashboard loaded successfully');
      } else {
        debugPrint('🔴 AdminDataProvider: Dashboard failed: ${data?['message']}');
      }
    } catch (e) {
      debugPrint('🔴 AdminDataProvider: Error loading dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============ CAREGIVERS ============
  Future<void> loadCaregivers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final headers = await _getHeaders();
      debugPrint('🟡 AdminDataProvider: Loading caregivers...');

      final response = await _apiService.dio.get(
        AdminApiEndpoints.getFullUrl(AdminApiEndpoints.caregivers),
        options: Options(headers: headers),
      );

      final data = response.data;
      if (data != null && data['status'] == true) {
        final List<dynamic> caregiversData = data['data'] ?? [];
        _caregivers = caregiversData
            .map((item) => Caregiver.fromJson(item as Map<String, dynamic>))
            .toList();
        debugPrint('🟢 AdminDataProvider: ${_caregivers.length} caregivers loaded');
      } else {
        debugPrint('🔴 AdminDataProvider: Caregivers failed: ${data?['message']}');
      }
    } catch (e) {
      debugPrint('🔴 AdminDataProvider: Error loading caregivers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createCaregiver(Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await _apiService.dio.post(
        AdminApiEndpoints.getFullUrl(AdminApiEndpoints.caregivers),
        data: data,
        options: Options(headers: headers),
      );

      final result = response.data;
      if (result != null && result['status'] == true) {
        await loadCaregivers();
        return {'success': true, 'message': result['message'] ?? 'Caregiver created successfully'};
      }
      return {'success': false, 'message': result?['message'] ?? 'Failed to create caregiver'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateCaregiver(Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await _apiService.dio.put(
        AdminApiEndpoints.getFullUrl(AdminApiEndpoints.caregivers),
        data: data,
        options: Options(headers: headers),
      );

      final result = response.data;
      if (result != null && result['status'] == true) {
        await loadCaregivers();
        return {'success': true, 'message': result['message'] ?? 'Caregiver updated successfully'};
      }
      return {'success': false, 'message': result?['message'] ?? 'Failed to update caregiver'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteCaregiver(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await _apiService.dio.delete(
        AdminApiEndpoints.getFullUrl(AdminApiEndpoints.caregivers),
        data: {'id': id},
        options: Options(headers: headers),
      );

      final result = response.data;
      if (result != null && result['status'] == true) {
        await loadCaregivers();
        return {'success': true, 'message': result['message'] ?? 'Caregiver deleted successfully'};
      }
      return {'success': false, 'message': result?['message'] ?? 'Failed to delete caregiver'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ============ POLICYHOLDERS ============
  Future<void> loadPolicyholders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final headers = await _getHeaders();
      debugPrint('🟡 AdminDataProvider: Loading policyholders...');

      final response = await _apiService.dio.get(
        AdminApiEndpoints.getFullUrl(AdminApiEndpoints.policyholders),
        options: Options(headers: headers),
      );

      final data = response.data;
      if (data != null && data['status'] == true) {
        final List<dynamic> policyholdersData = data['data'] ?? [];
        _policyholders = policyholdersData
            .map((item) => Policyholder.fromJson(item as Map<String, dynamic>))
            .toList();
        debugPrint('🟢 AdminDataProvider: ${_policyholders.length} policyholders loaded');
      } else {
        debugPrint('🔴 AdminDataProvider: Policyholders failed: ${data?['message']}');
      }
    } catch (e) {
      debugPrint('🔴 AdminDataProvider: Error loading policyholders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createPolicyholder(Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await _apiService.dio.post(
        AdminApiEndpoints.getFullUrl(AdminApiEndpoints.policyholders),
        data: data,
        options: Options(headers: headers),
      );

      final result = response.data;
      if (result != null && result['status'] == true) {
        await loadPolicyholders();
        return {'success': true, 'message': result['message'] ?? 'Policyholder created successfully'};
      }
      return {'success': false, 'message': result?['message'] ?? 'Failed to create policyholder'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> updatePolicyholder(Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await _apiService.dio.put(
        AdminApiEndpoints.getFullUrl(AdminApiEndpoints.policyholders),
        data: data,
        options: Options(headers: headers),
      );

      final result = response.data;
      if (result != null && result['status'] == true) {
        await loadPolicyholders();
        return {'success': true, 'message': result['message'] ?? 'Policyholder updated successfully'};
      }
      return {'success': false, 'message': result?['message'] ?? 'Failed to update policyholder'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> deletePolicyholder(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await _apiService.dio.delete(
        AdminApiEndpoints.getFullUrl(AdminApiEndpoints.policyholders),
        data: {'id': id},
        options: Options(headers: headers),
      );

      final result = response.data;
      if (result != null && result['status'] == true) {
        await loadPolicyholders();
        return {'success': true, 'message': result['message'] ?? 'Policyholder deleted successfully'};
      }
      return {'success': false, 'message': result?['message'] ?? 'Failed to delete policyholder'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ============ SHIFTS ============
  Future<void> loadShifts({String? startDate, String? endDate, int? caregiverId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final headers = await _getHeaders();
      debugPrint('🟡 AdminDataProvider: Loading shifts...');

      final Map<String, dynamic> params = {};
      if (startDate != null && startDate.isNotEmpty) params['start_date'] = startDate;
      if (endDate != null && endDate.isNotEmpty) params['end_date'] = endDate;
      if (caregiverId != null) params['caregiver_id'] = caregiverId;

      final response = await _apiService.dio.get(
        AdminApiEndpoints.getFullUrl(AdminApiEndpoints.shifts),
        queryParameters: params,
        options: Options(headers: headers),
      );

      final data = response.data;
      if (data != null && data['status'] == true) {
        final List<dynamic> shiftsData = data['data'] ?? [];
        _shifts = shiftsData
            .map((item) => Shift.fromJson(item as Map<String, dynamic>))
            .toList();
        debugPrint('🟢 AdminDataProvider: ${_shifts.length} shifts loaded');
      } else {
        debugPrint('🔴 AdminDataProvider: Shifts failed: ${data?['message']}');
      }
    } catch (e) {
      debugPrint('🔴 AdminDataProvider: Error loading shifts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> approveShift(int shiftId, String status) async {
    try {
      final headers = await _getHeaders();
      final response = await _apiService.dio.post(
        AdminApiEndpoints.getFullUrl(AdminApiEndpoints.approveShift),
        data: {
          'shift_id': shiftId,
          'status': status,
        },
        options: Options(headers: headers),
      );

      final result = response.data;
      if (result != null && result['status'] == true) {
        await loadShifts();
        return {'success': true, 'message': result['message'] ?? 'Shift $status successfully'};
      }
      return {'success': false, 'message': result?['message'] ?? 'Failed to approve shift'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  void reset() {
    _dashboardStats = null;
    _caregivers = [];
    _policyholders = [];
    _shifts = [];
    _isLoading = false;
    notifyListeners();
  }
}

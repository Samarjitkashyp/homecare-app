import 'package:homecare_app/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:homecare_app/core/network/api_service.dart';
import 'package:homecare_app/models/response_model.dart';

class TimeProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  int? _currentEntryId;
  String? _timeInValue;
  String? _timeOutValue;
  double? _totalHours;
  double? _totalCharge;
  bool _hasActiveEntry = false;

  bool get isLoading => _isLoading;
  int? get currentEntryId => _currentEntryId;
  String? get timeInValue => _timeInValue;
  String? get timeOutValue => _timeOutValue;
  double? get totalHours => _totalHours;
  double? get totalCharge => _totalCharge;
  bool get hasActiveEntry => _hasActiveEntry;

  Future<ResponseModel> registerTimeIn(int policyholderId, String date, String time) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.timeIn(policyholderId, date, time);

      if (response.status && response.data != null) {
        final entryId = response.data['entry_id'];
        _currentEntryId = entryId is int ? entryId : int.tryParse(entryId.toString());
        _timeInValue = response.data['time_in'] as String?;
        _hasActiveEntry = true;

        AppLogger.d('✅ TimeProvider: Time-In registered. Entry ID: $_currentEntryId');
      }

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      AppLogger.d('🔴 TimeProvider: Exception - $e');
      _isLoading = false;
      notifyListeners();
      return ResponseModel(
        status: false,
        message: 'Error: $e',
        data: null,
      );
    }
  }

  Future<ResponseModel> registerTimeOut(String time, double rate) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.timeOut(time, rate);

      if (response.status && response.data != null) {
        _timeOutValue = response.data['time_out'] as String?;

        // ✅ Fixed: Handle string values from API
        final totalHoursValue = response.data['total_hours'];
        _totalHours = totalHoursValue is num
            ? totalHoursValue.toDouble()
            : double.tryParse(totalHoursValue.toString()) ?? 0.0;

        final totalChargeValue = response.data['total_charge'];
        _totalCharge = totalChargeValue is num
            ? totalChargeValue.toDouble()
            : double.tryParse(totalChargeValue.toString()) ?? 0.0;

        _hasActiveEntry = false;
      }

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      AppLogger.d('🔴 TimeProvider: Exception - $e');
      _isLoading = false;
      notifyListeners();
      return ResponseModel(
        status: false,
        message: 'Error: $e',
        data: null,
      );
    }
  }

  Future<ResponseModel> getTodayLog(String date) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getTodayLog(date);

      if (response.status && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['has_entry'] == true) {
          final timeEntry = data['time_entry'] as Map<String, dynamic>;

          final entryId = timeEntry['id'];
          _currentEntryId = entryId is int ? entryId : int.tryParse(entryId.toString());
          _timeInValue = timeEntry['time_in'] as String?;
          _timeOutValue = timeEntry['time_out'] as String?;

          // ✅ Fixed: Handle string values from API
          final totalHoursValue = timeEntry['total_hours'];
          _totalHours = totalHoursValue is num
              ? totalHoursValue.toDouble()
              : double.tryParse(totalHoursValue.toString()) ?? 0.0;

          final totalChargeValue = timeEntry['total_charge'];
          _totalCharge = totalChargeValue is num
              ? totalChargeValue.toDouble()
              : double.tryParse(totalChargeValue.toString()) ?? 0.0;

          _hasActiveEntry = timeEntry['status'] == 'active';
        }
      }

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      AppLogger.d('🔴 TimeProvider: Exception - $e');
      _isLoading = false;
      notifyListeners();
      return ResponseModel(
        status: false,
        message: 'Error: $e',
        data: null,
      );
    }
  }

  void reset() {
    _currentEntryId = null;
    _timeInValue = null;
    _timeOutValue = null;
    _totalHours = null;
    _totalCharge = null;
    _hasActiveEntry = false;
    notifyListeners();
  }
}
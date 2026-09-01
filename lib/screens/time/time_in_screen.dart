import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:homecare_app/core/constants/api_endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:homecare_app/providers/time_provider.dart';
import 'package:homecare_app/providers/auth_provider.dart';
import 'package:homecare_app/widgets/custom_button.dart';
import 'package:homecare_app/widgets/custom_text_field.dart';
import 'package:homecare_app/core/utils/date_formatter.dart';
import 'package:homecare_app/core/utils/app_logger.dart';
import 'package:homecare_app/core/theme/app_style.dart';
import 'package:homecare_app/core/utils/responsive.dart';
import 'package:homecare_app/screens/home/home_screen.dart';
import 'package:homecare_app/core/network/api_service.dart';
import 'package:homecare_app/core/constants/app_constants.dart';

class TimeInScreen extends StatefulWidget {
  const TimeInScreen({super.key});

  @override
  State<TimeInScreen> createState() => _TimeInScreenState();
}

class _TimeInScreenState extends State<TimeInScreen> {
  final _formKey = GlobalKey<FormState>();

  final _policyholderNameController = TextEditingController();
  final _policyholderIdController = TextEditingController();
  final _providerNameController = TextEditingController();
  final _providerPhoneController = TextEditingController();

  String _selectedDate = DateFormatter.getCurrentDate();
  String _selectedTimeIn = DateFormatter.getCurrentTime();

  bool _isLoading = false;
  bool _isLoadingPolicyholders = false;

  List<Map<String, dynamic>> _policyholders = [];
  Map<String, dynamic>? _selectedPolicyholder;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProviderData();
      _loadPolicyholders();
    });
  }

  void _loadProviderData() {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        final user = authProvider.user!;
        _providerNameController.text = user.name;
        _providerPhoneController.text =
            user.hasPhone ? user.phone! : 'Not available';
      } else {
        _providerNameController.text = 'Loading...';
        _providerPhoneController.text = 'Loading...';
      }
    } catch (e, s) {
      AppLogger.e('TimeIn: load provider failed', e, s);
      _providerNameController.text = 'Error loading';
      _providerPhoneController.text = 'Error loading';
    }
  }

  Future<void> _loadPolicyholders() async {
    setState(() => _isLoadingPolicyholders = true);
    try {
      final apiService = ApiService();
      final token = await _getToken();
      if (token == null) {
        setState(() => _isLoadingPolicyholders = false);
        return;
      }

      final response = await apiService.dio.get(
        ApiEndpoints.policyholdersList,
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        }),
      );

      final data = response.data;
      if (data != null && data['status'] == true) {
        final List<dynamic> list = data['data'] ?? [];
        setState(() {
          _policyholders =
              list.map((item) => item as Map<String, dynamic>).toList();
        });
      } else if (mounted) {
        _snack('Failed to load policyholders: ${data?['message'] ?? 'Unknown error'}',
            AppStyle.warning);
      }
    } catch (e, s) {
      AppLogger.e('TimeIn: load policyholders failed', e, s);
      if (mounted) _snack('Could not load policyholders. Pull to retry.', AppStyle.danger);
    } finally {
      if (mounted) setState(() => _isLoadingPolicyholders = false);
    }
  }

  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.tokenKey);
    } catch (e, s) {
      AppLogger.e('TimeIn: get token failed', e, s);
      return null;
    }
  }

  @override
  void dispose() {
    _policyholderNameController.dispose();
    _policyholderIdController.dispose();
    _providerNameController.dispose();
    _providerPhoneController.dispose();
    super.dispose();
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyle.rSm)),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate =
            DateFormatter.formatDateTime(picked, format: 'yyyy-MM-dd');
      });
    }
  }

  Future<void> _selectTimeIn(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTimeIn =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _startShift() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPolicyholder == null) {
      _snack('Please select a policyholder', AppStyle.warning);
      return;
    }

    final completedShifts = _selectedPolicyholder!['completed_shifts'] ?? 0;
    if (completedShifts > 0) {
      _snack(
        '${_selectedPolicyholder!['name']} already has $completedShifts completed shift(s). You cannot start a new shift for this policyholder.',
        AppStyle.danger,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final timeProvider = Provider.of<TimeProvider>(context, listen: false);
      final policyholderId = _selectedPolicyholder!['id'] as int;

      final response = await timeProvider.registerTimeIn(
        policyholderId,
        _selectedDate,
        _selectedTimeIn,
      );

      if (!mounted) return;

      if (!response.status) {
        _snack(response.message, AppStyle.danger);
      } else {
        _snack('Shift started successfully', AppStyle.success);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e, s) {
      AppLogger.e('TimeIn: start shift failed', e, s);
      if (mounted) _snack('Something went wrong. Please try again.', AppStyle.danger);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeProvider = Provider.of<TimeProvider>(context);
    final busy = _isLoading || timeProvider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Shift',
            style: TextStyle(
                color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
        backgroundColor: AppStyle.primaryDark,
        elevation: 0,
      ),
      body: DecoratedBox(
        decoration: AppStyle.pageGradient,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppStyle.lg),
          physics: const BouncingScrollPhysics(),
          child: ResponsiveCenter(
            maxWidth: 560,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _header(),
                const SizedBox(height: AppStyle.lg),
                _formCard(),
                const SizedBox(height: AppStyle.md),
                _scheduleCard(),
                const SizedBox(height: AppStyle.xl),
                CustomButton(
                  onPressed: _startShift,
                  text: 'Start Shift',
                  icon: Icons.play_arrow_rounded,
                  isFullWidth: true,
                  isLoading: busy,
                  color: AppStyle.success,
                ),
                const SizedBox(height: AppStyle.lg),
                _legalDisclaimer(),
                const SizedBox(height: AppStyle.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(AppStyle.lg),
      decoration: BoxDecoration(
        gradient: AppStyle.brandGradient,
        borderRadius: BorderRadius.circular(AppStyle.rLg),
        boxShadow: AppStyle.brandShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.play_circle_outline_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: AppStyle.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Begin Shift',
                    style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                Text('Start your caregiving session',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formCard() {
    return Container(
      padding: const EdgeInsets.all(AppStyle.lg),
      decoration: AppStyle.card(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardTitle(Icons.assignment_ind_outlined, 'Policyholder & Provider'),
            const SizedBox(height: AppStyle.lg),
            _buildPolicyholderDropdown(),
            const SizedBox(height: AppStyle.lg),
            CustomTextField(
              controller: _policyholderIdController,
              label: 'Policyholder ID',
              hint: 'Auto-filled from selection',
              prefixIcon: Icons.badge_outlined,
              readOnly: true,
            ),
            const SizedBox(height: AppStyle.lg),
            CustomTextField(
              controller: _providerNameController,
              label: 'Provider (Caregiver)',
              hint: 'Auto-filled',
              prefixIcon: Icons.medical_services_outlined,
              readOnly: true,
            ),
            const SizedBox(height: AppStyle.lg),
            CustomTextField(
              controller: _providerPhoneController,
              label: 'Provider Phone',
              hint: 'Auto-filled',
              prefixIcon: Icons.phone_android_outlined,
              readOnly: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _scheduleCard() {
    return Container(
      padding: const EdgeInsets.all(AppStyle.lg),
      decoration: AppStyle.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.event_available_outlined, 'Shift Schedule'),
          const SizedBox(height: AppStyle.lg),
          _pickerField(
            label: 'Date',
            value: _selectedDate,
            icon: Icons.calendar_today_rounded,
            onTap: () => _selectDate(context),
          ),
          const SizedBox(height: AppStyle.lg),
          _pickerField(
            label: 'Time In',
            value: _selectedTimeIn,
            icon: Icons.access_time_filled_rounded,
            onTap: () => _selectTimeIn(context),
          ),
        ],
      ),
    );
  }

  Widget _pickerField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppStyle.rMd),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
              color: AppStyle.inkSoft, fontWeight: FontWeight.w600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppStyle.rMd),
            borderSide: const BorderSide(color: AppStyle.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppStyle.rMd),
            borderSide: const BorderSide(color: AppStyle.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppStyle.rMd),
            borderSide: const BorderSide(color: AppStyle.primary, width: 2),
          ),
          prefixIcon: Icon(icon, color: AppStyle.primary),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        child: Text(value,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: AppStyle.ink)),
      ),
    );
  }

  Widget _cardTitle(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppStyle.primary),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: AppStyle.ink)),
      ],
    );
  }

  Widget _buildPolicyholderDropdown() {
    final hasDoneItems =
        _policyholders.any((p) => (p['completed_shifts'] ?? 0) > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Policyholder Name',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppStyle.inkSoft)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(AppStyle.rMd),
            border: Border.all(color: AppStyle.line),
          ),
          child: _isLoadingPolicyholders
              ? const Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppStyle.primary),
                      ),
                      SizedBox(width: 12),
                      Text('Loading policyholders...',
                          style:
                              TextStyle(fontSize: 14, color: AppStyle.inkSoft)),
                    ],
                  ),
                )
              : DropdownButtonFormField<Map<String, dynamic>>(
                  value: _selectedPolicyholder,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    hintText: _policyholders.isEmpty
                        ? 'No policyholders found'
                        : 'Select a policyholder',
                    hintStyle:
                        const TextStyle(color: AppStyle.inkSoft, fontSize: 14),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppStyle.inkSoft),
                  items: _policyholders.map((policyholder) {
                    final completedShifts =
                        policyholder['completed_shifts'] ?? 0;
                    final isDisabled = completedShifts > 0;
                    final name = policyholder['name'] ?? 'Unknown';

                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: isDisabled ? null : policyholder,
                      enabled: !isDisabled,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isDisabled
                                    ? FontWeight.normal
                                    : FontWeight.w500,
                                color: isDisabled
                                    ? AppStyle.inkSoft
                                    : AppStyle.ink,
                                decoration: isDisabled
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isDisabled) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppStyle.danger.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('Done',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppStyle.danger)),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: _policyholders.isEmpty
                      ? null
                      : (Map<String, dynamic>? value) {
                          if (value == null) {
                            _snack(
                                'This policyholder already has a completed shift.',
                                AppStyle.danger);
                            return;
                          }
                          setState(() {
                            _selectedPolicyholder = value;
                            _policyholderNameController.text =
                                value['name'] ?? '';
                            _policyholderIdController.text =
                                value['id']?.toString() ?? '';
                          });
                        },
                  validator: (value) =>
                      value == null ? 'Please select a policyholder' : null,
                ),
        ),
        if (_policyholders.isEmpty && !_isLoadingPolicyholders)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'No policyholders available. Please add one from the admin panel.',
              style: TextStyle(fontSize: 12, color: Color(0xFF9A6A00)),
            ),
          ),
        if (hasDoneItems)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: AppStyle.inkSoft),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Policyholders with a "Done" badge already have completed shifts.',
                    style: TextStyle(fontSize: 11, color: AppStyle.inkSoft),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _legalDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(AppStyle.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(AppStyle.rSm),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.gavel_rounded, size: 15, color: Color(0xFF9A6A00)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'By submitting, I certify that the information is true and accurate. False claims are punishable by law.',
              style: TextStyle(fontSize: 10, color: Color(0xFF6B5200), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

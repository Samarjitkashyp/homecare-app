import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:homecare_app/providers/time_provider.dart';
import 'package:homecare_app/widgets/custom_button.dart';
import 'package:homecare_app/widgets/custom_text_field.dart';
import 'package:homecare_app/core/utils/date_formatter.dart';
import 'package:homecare_app/core/utils/app_logger.dart';
import 'package:homecare_app/core/theme/app_style.dart';
import 'package:homecare_app/core/utils/responsive.dart';
import 'package:homecare_app/screens/home/home_screen.dart';

class TimeOutScreen extends StatefulWidget {
  const TimeOutScreen({super.key});

  @override
  State<TimeOutScreen> createState() => _TimeOutScreenState();
}

class _TimeOutScreenState extends State<TimeOutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rateController = TextEditingController();
  String _selectedTime = DateFormatter.getCurrentTime();
  bool _isLoading = false;

  static const Color _endRed = Color(0xFFD32F2F);

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
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

  Future<void> _timeOut() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final timeProvider = Provider.of<TimeProvider>(context, listen: false);
      final rate = double.tryParse(_rateController.text.trim());
      if (rate == null) {
        _snack('Please enter a valid rate', AppStyle.warning);
        setState(() => _isLoading = false);
        return;
      }

      final response = await timeProvider.registerTimeOut(_selectedTime, rate);
      if (!mounted) return;

      if (!response.status) {
        _snack(response.message, AppStyle.danger);
      } else {
        final totalHours = timeProvider.totalHours?.toStringAsFixed(2) ?? '0.00';
        final totalCharge =
            timeProvider.totalCharge?.toStringAsFixed(2) ?? '0.00';
        _snack('Shift completed — $totalHours hrs, \$$totalCharge', AppStyle.success);

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        });
      }
    } catch (e, s) {
      AppLogger.e('TimeOut failed', e, s);
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
        title: const Text('End Shift',
            style: TextStyle(
                color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
        backgroundColor: _endRed,
        elevation: 0,
        centerTitle: false,
      ),
      body: DecoratedBox(
        decoration: AppStyle.pageGradient,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppStyle.lg),
          physics: const BouncingScrollPhysics(),
          child: ResponsiveCenter(
            maxWidth: 560,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _header(),
                  const SizedBox(height: AppStyle.lg),
                  _summaryCard(timeProvider),
                  const SizedBox(height: AppStyle.md),
                  _rateCard(),
                  const SizedBox(height: AppStyle.xl),
                  CustomButton(
                    onPressed: _timeOut,
                    text: 'End Shift',
                    icon: Icons.stop_circle_outlined,
                    isFullWidth: true,
                    isLoading: busy,
                    color: _endRed,
                  ),
                  const SizedBox(height: AppStyle.lg),
                  _legalDisclaimer(),
                  const SizedBox(height: AppStyle.lg),
                ],
              ),
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
        gradient: const LinearGradient(
          colors: [_endRed, Color(0xFFEF5350)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppStyle.rLg),
        boxShadow: [
          BoxShadow(
            color: _endRed.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.stop_circle_outlined,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: AppStyle.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('End Shift',
                    style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                Text('Complete your daily shift',
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

  Widget _summaryCard(TimeProvider timeProvider) {
    return Container(
      padding: const EdgeInsets.all(AppStyle.lg),
      decoration: AppStyle.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.summarize_outlined, 'Shift Summary', AppStyle.primary),
          const SizedBox(height: AppStyle.lg),
          Container(
            padding: const EdgeInsets.all(AppStyle.md),
            decoration: BoxDecoration(
              color: AppStyle.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppStyle.rMd),
              border: Border.all(color: AppStyle.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.login_rounded, color: AppStyle.primary, size: 18),
                    SizedBox(width: 8),
                    Text('Time In',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppStyle.ink)),
                  ],
                ),
                Text(
                  timeProvider.timeInValue ?? 'Not started',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppStyle.primaryDark,
                      fontSize: 15),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppStyle.lg),
          InkWell(
            onTap: () => _selectTime(context),
            borderRadius: BorderRadius.circular(AppStyle.rMd),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Time Out',
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
                prefixIcon: const Icon(Icons.access_time_filled_rounded,
                    color: AppStyle.primary),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              child: Text(_selectedTime,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: AppStyle.ink)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rateCard() {
    return Container(
      padding: const EdgeInsets.all(AppStyle.lg),
      decoration: AppStyle.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.payments_outlined, 'Payment Details', AppStyle.success),
          const SizedBox(height: AppStyle.lg),
          CustomTextField(
            controller: _rateController,
            label: 'Hourly Rate (\$)',
            hint: 'e.g. 25.00',
            prefixIcon: Icons.attach_money_rounded,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter rate';
              final rate = double.tryParse(value);
              if (rate == null || rate <= 0) return 'Please enter a valid rate';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _cardTitle(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: AppStyle.ink)),
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
              'By submitting, I certify that the information is true and accurate. Knowingly presenting a false or fraudulent claim is a crime and may be subject to fines and confinement.',
              style: TextStyle(fontSize: 10, color: Color(0xFF6B5200), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

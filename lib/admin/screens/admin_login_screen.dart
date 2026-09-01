import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:homecare_app/admin/providers/admin_auth_provider.dart';
import 'package:homecare_app/admin/screens/admin_dashboard_screen.dart';
import 'package:homecare_app/widgets/custom_button.dart';
import 'package:homecare_app/widgets/custom_text_field.dart';
import 'package:homecare_app/screens/auth/login_screen.dart';
import 'package:homecare_app/core/theme/app_style.dart';
import 'package:homecare_app/core/utils/responsive.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Deeper navy accent to distinguish the admin area from the caregiver app.
  static const Color _adminNavy = Color(0xFF0F2A54);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AdminAuthProvider>(context, listen: false);
    final result = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _snack('Admin login successful', AppStyle.success);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } else {
      _snack(result['message']?.toString() ?? 'Login failed', AppStyle.danger);
    }
  }

  void _backToCaregiver() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AdminAuthProvider>(context);
    final busy = _isLoading || authProvider.isLoading;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToCaregiver();
      },
      child: Scaffold(
        body: DecoratedBox(
          decoration: AppStyle.pageGradient,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppStyle.xl, vertical: AppStyle.xxl),
                child: ResponsiveCenter(
                  maxWidth: 430,
                  child: Column(
                    children: [
                      _brand(),
                      const SizedBox(height: AppStyle.xxl),
                      _loginCard(busy),
                      const SizedBox(height: AppStyle.xl),
                      CustomButton(
                        onPressed: _backToCaregiver,
                        text: 'Back to Caregiver Login',
                        icon: Icons.arrow_back_rounded,
                        isOutlined: true,
                        isFullWidth: true,
                        color: AppStyle.inkSoft,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _brand() {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_adminNavy, AppStyle.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _adminNavy.withValues(alpha: 0.3),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.admin_panel_settings_rounded,
              size: 44, color: Colors.white),
        ),
        const SizedBox(height: AppStyle.lg),
        const Text(
          'Admin Portal',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppStyle.ink,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Enter your admin credentials',
          style: TextStyle(fontSize: 14.5, color: AppStyle.inkSoft),
        ),
      ],
    );
  }

  Widget _loginCard(bool busy) {
    return Container(
      padding: const EdgeInsets.all(AppStyle.xl),
      decoration: AppStyle.card(),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            CustomTextField(
              controller: _emailController,
              label: 'Email Address',
              hint: 'admin@example.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter email';
                }
                if (!value.contains('@') || !value.contains('.')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: AppStyle.lg),
            CustomTextField(
              controller: _passwordController,
              label: 'Password',
              hint: 'Enter your password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              keyboardType: TextInputType.visiblePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppStyle.inkSoft,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: AppStyle.xl),
            CustomButton(
              onPressed: _login,
              text: 'Sign In as Admin',
              icon: Icons.login_rounded,
              isFullWidth: true,
              isLoading: busy,
              color: _adminNavy,
            ),
          ],
        ),
      ),
    );
  }
}

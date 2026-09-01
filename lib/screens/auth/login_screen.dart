import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:homecare_app/providers/auth_provider.dart';
import 'package:homecare_app/widgets/custom_button.dart';
import 'package:homecare_app/widgets/custom_text_field.dart';
import 'package:homecare_app/admin/screens/admin_login_screen.dart';
import 'package:homecare_app/screens/home/home_screen.dart';
import 'package:homecare_app/core/theme/app_style.dart';
import 'package:homecare_app/core/utils/responsive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await authProvider.login(email, password);

      if (!mounted) return;

      if (!response.status) {
        _showSnack(response.message, AppStyle.danger);
      } else {
        _showSnack('Login successful', AppStyle.success);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) _showSnack('Something went wrong. Please try again.', AppStyle.danger);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyle.rSm),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final busy = _isLoading || authProvider.isLoading;

    return Scaffold(
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
                    _orDivider(),
                    const SizedBox(height: AppStyle.lg),
                    _adminButton(),
                    const SizedBox(height: AppStyle.lg),
                    Text(
                      'Absolute Choice Homecare',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppStyle.inkSoft.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
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
            gradient: AppStyle.brandGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppStyle.brandShadow,
          ),
          child: const Icon(Icons.health_and_safety_rounded,
              size: 46, color: Colors.white),
        ),
        const SizedBox(height: AppStyle.lg),
        const Text(
          'Welcome back',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppStyle.ink,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Sign in to your caregiver account',
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
              hint: 'you@example.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email';
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
                  return 'Please enter your password';
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
              text: 'Sign In',
              icon: Icons.login_rounded,
              isFullWidth: true,
              isLoading: busy,
            ),
          ],
        ),
      ),
    );
  }

  Widget _orDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppStyle.line, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppStyle.md),
          child: Text('or',
              style: TextStyle(color: AppStyle.inkSoft, fontSize: 12.5)),
        ),
        Expanded(child: Divider(color: AppStyle.line, thickness: 1)),
      ],
    );
  }

  Widget _adminButton() {
    return CustomButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
      ),
      text: 'Admin Login',
      icon: Icons.admin_panel_settings_outlined,
      isOutlined: true,
      isFullWidth: true,
      color: AppStyle.primaryDark,
    );
  }
}

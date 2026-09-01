import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:homecare_app/providers/auth_provider.dart';
import 'package:homecare_app/providers/time_provider.dart';
import 'package:homecare_app/providers/progress_provider.dart';
import 'package:homecare_app/providers/report_provider.dart';
import 'package:homecare_app/providers/signature_provider.dart';
import 'package:homecare_app/admin/providers/admin_auth_provider.dart';
import 'package:homecare_app/admin/providers/admin_data_provider.dart';
import 'package:homecare_app/screens/auth/login_screen.dart';
import 'package:homecare_app/screens/home/home_screen.dart';
import 'package:homecare_app/admin/screens/admin_login_screen.dart';
import 'package:homecare_app/admin/screens/admin_dashboard_screen.dart';
import 'package:homecare_app/core/utils/connectivity_checker.dart';
import 'package:homecare_app/core/utils/globals.dart';
import 'package:homecare_app/core/utils/app_logger.dart';
import 'package:homecare_app/core/theme/app_theme.dart';

void main() {
  // Run the whole app inside a guarded zone so that any uncaught async
  // error is logged instead of crashing the app for the user.
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();

    // Framework build/layout/paint errors -> log, and in release show a
    // friendly fallback instead of the red error screen.
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      AppLogger.e('FlutterError', details.exception, details.stack);
    };

    ErrorWidget.builder = (FlutterErrorDetails details) {
      if (kReleaseMode) {
        return const _FriendlyErrorScreen();
      }
      return ErrorWidget(details.exception);
    };

    runApp(const MyApp());
  }, (error, stack) {
    AppLogger.e('Uncaught zone error', error, stack);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TimeProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => SignatureProvider()),
        ChangeNotifierProvider(create: (_) => AdminAuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminDataProvider()),
      ],
      child: MaterialApp(
        title: 'Absolute Choice Homecare',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: Globals.scaffoldMessengerKey,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        // Screens are currently designed for a light surface; force light so
        // the look stays consistent until a full dark pass is done.
        themeMode: ThemeMode.light,
        // Keep text from scaling to extreme sizes on some devices (prevents
        // overflow crashes while still respecting the user's preference).
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          final clamped = mq.textScaler.clamp(
            minScaleFactor: 0.9,
            maxScaleFactor: 1.3,
          );
          return MediaQuery(
            data: mq.copyWith(textScaler: clamped),
            child: child ?? const SizedBox.shrink(),
          );
        },
        initialRoute: '/',
        routes: {
          '/': (context) => const ConnectivityChecker(
                child: AuthWrapper(),
              ),
          '/admin-login': (context) => const AdminLoginScreen(),
          '/admin-dashboard': (context) => const AdminDashboardScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final adminAuthProvider = Provider.of<AdminAuthProvider>(context);

    if (authProvider.isLoading || adminAuthProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Caregiver first (this is primarily the caregiver app)
    if (authProvider.isAuthenticated) {
      AppLogger.i('AuthWrapper: caregiver authenticated');
      return const HomeScreen();
    }

    if (adminAuthProvider.isAuthenticated) {
      AppLogger.i('AuthWrapper: admin authenticated');
      return const AdminDashboardScreen();
    }

    return const LoginScreen();
  }
}

/// Shown (release only) if a widget fails to build, instead of a red screen.
class _FriendlyErrorScreen extends StatelessWidget {
  const _FriendlyErrorScreen();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: const Color(0xFFF5F5F5),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 56, color: Color(0xFF2196F3)),
            SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please go back and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF757575)),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Central design tokens so every screen shares the same spacing, corner
/// radius, shadows and surface treatment. Colours/fonts stay as-is
/// (AppTheme.primaryColor = #2196F3); this just makes the look consistent
/// and professional across the whole app.
class AppStyle {
  const AppStyle._();

  // ---- Brand palette (kept from the existing design) ----
  static const Color primary = AppTheme.primaryColor;       // #2196F3
  static const Color primaryDark = Color(0xFF1976D2);       // blue.shade700
  static const Color ink = Color(0xFF1A2233);               // headings
  static const Color inkSoft = Color(0xFF64748B);           // secondary text
  static const Color line = Color(0xFFE8EDF3);              // borders/dividers
  static const Color surface = Colors.white;
  static const Color canvasTop = Color(0xFFEAF3FE);         // gradient top
  static const Color canvasBottom = Color(0xFFF7FAFD);      // gradient bottom
  static const Color success = AppTheme.successColor;
  static const Color warning = AppTheme.warningColor;
  static const Color danger = AppTheme.errorColor;

  // ---- Spacing scale ----
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  // ---- Corner radius ----
  static const double rSm = 10;
  static const double rMd = 14;
  static const double rLg = 20;

  // ---- Soft, layered shadow used on cards ----
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF1A2233).withValues(alpha: 0.05),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get brandShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.28),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ];

  // ---- Reusable surface decoration ----
  static BoxDecoration card({double radius = rLg, Color? color}) => BoxDecoration(
        color: color ?? surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: line),
        boxShadow: cardShadow,
      );

  /// Page background gradient (subtle, professional).
  static const BoxDecoration pageGradient = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [canvasTop, canvasBottom],
    ),
  );

  static const LinearGradient brandGradient = LinearGradient(
    colors: [primaryDark, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

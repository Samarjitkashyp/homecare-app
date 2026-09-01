import 'package:flutter/material.dart';
import 'package:homecare_app/core/theme/app_style.dart';

/// Professional, consistent button used across the app.
/// Backward compatible with existing call sites; adds [isLoading] and [icon].
class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isFullWidth;
  final bool isOutlined;
  final Color? color;
  final double? width;
  final bool isLoading;
  final IconData? icon;

  const CustomButton({
    super.key,
    this.onPressed,
    required this.text,
    this.isFullWidth = false,
    this.isOutlined = false,
    this.color,
    this.width,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final Color base = color ?? AppStyle.primary;
    final bool disabled = onPressed == null || isLoading;

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppStyle.rMd),
    );
    const padding = EdgeInsets.symmetric(horizontal: 22, vertical: 15);

    final Widget label = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOutlined ? base : Colors.white,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 19),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          );

    final Widget button = isOutlined
        ? OutlinedButton(
            onPressed: disabled ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: base,
              padding: padding,
              shape: shape,
              side: BorderSide(color: base, width: 1.4),
            ),
            child: label,
          )
        : ElevatedButton(
            onPressed: disabled ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: base,
              foregroundColor: Colors.white,
              disabledBackgroundColor: base.withValues(alpha: 0.5),
              disabledForegroundColor: Colors.white,
              padding: padding,
              shape: shape,
              elevation: 0,
            ),
            child: label,
          );

    if (isFullWidth) {
      return SizedBox(width: double.infinity, height: 52, child: button);
    }
    return SizedBox(width: width ?? 200, height: 52, child: button);
  }
}

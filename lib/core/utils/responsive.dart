import 'package:flutter/widgets.dart';

/// Responsive helpers so the UI looks right on every iPhone AND iPad.
///
/// On large screens (iPad / landscape) full-width forms and lists look
/// stretched and unprofessional. `ResponsiveCenter` constrains content to a
/// comfortable reading width and centers it; the context extensions expose
/// simple breakpoints.
extension ResponsiveContext on BuildContext {
  Size get _size => MediaQuery.sizeOf(this);

  double get screenWidth => _size.width;
  double get screenHeight => _size.height;

  /// Phones are < 600dp wide (shortest side heuristic used by Material).
  bool get isPhone => _size.shortestSide < 600;
  bool get isTablet => _size.shortestSide >= 600;
  bool get isLandscape => _size.width > _size.height;

  /// A scale factor to gently grow paddings/spacing on tablets.
  double get gutter => isTablet ? 24.0 : 16.0;
}

/// Centers its [child] and caps the width on large screens so forms and
/// content columns don't stretch edge-to-edge on iPad.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 560,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

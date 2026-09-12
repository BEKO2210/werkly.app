import 'package:flutter/material.dart';

/// Material 3 spacing helpers — 4 dp base grid (UI-POLISH-HAPPYPATH-V1).
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Screen horizontal padding.
  static const double screenH = 16;

  /// Under AppBar vertical padding.
  static const double screenV = 12;

  /// Section gap.
  static const double section = 24;

  /// Card inner padding.
  static const double card = 16;

  /// Min list item / touch height.
  static const double touchMin = 48;
  static const double listItemMin = 64;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screenH,
    vertical: screenV,
  );

  static const EdgeInsets screenPaddingH = EdgeInsets.symmetric(
    horizontal: screenH,
  );

  static const EdgeInsets cardPadding = EdgeInsets.all(card);

  static const EdgeInsets sectionGap = EdgeInsets.only(top: section);
}

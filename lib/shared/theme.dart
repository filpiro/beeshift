import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Beeshift's accent: shadcn's stock Amber recolor on the Slate base scheme.
ThemeData _theme(ColorScheme scheme) => ThemeData(
  colorScheme: scheme.amber,
  radius: 1.0, // "Full" (pill); shadcn default is 0.5
  scaling: 1.0,
  density: Density.reducedDensity,
  surfaceOpacity: 1.0, // "Solid"
  surfaceBlur: 8.0, // "Medium"; no named constant, invisible under opacity 1.0
);

final ThemeData lightTheme = _theme(ColorSchemes.lightSlate);
final ThemeData darkTheme = _theme(ColorSchemes.darkSlate);

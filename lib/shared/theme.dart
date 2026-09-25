import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Beeshift's accent: Amber, layered onto shadcn's Slate base scheme.
/// `ColorScheme.copyWith` takes `ValueGetter<Color>`, hence the closures.
ColorScheme _amber(ColorScheme base) => base.copyWith(
  primary: () => Colors.amber.shade500,
  primaryForeground: () => Colors.slate.shade950,
  ring: () => Colors.amber.shade500,
);

ThemeData _theme(ColorScheme scheme) => ThemeData(
  colorScheme: _amber(scheme),
  radius: 0.75, // "Rounded"; shadcn default is 0.5
  scaling: 1.0,
  density: Density.reducedDensity,
  surfaceOpacity: 1.0, // "Solid"
  surfaceBlur: 8.0, // "Medium"; no named constant, invisible under opacity 1.0
);

final ThemeData lightTheme = _theme(ColorSchemes.lightSlate);
final ThemeData darkTheme = _theme(ColorSchemes.darkSlate);

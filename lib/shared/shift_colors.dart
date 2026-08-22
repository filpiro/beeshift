import 'package:catui/catui.dart';
import 'package:flutter/material.dart';

import 'shift_type.dart';

/// The Shift Colour of each Shift Type, taken per flavor so latte and mocha
/// each get their own hues from one table.
///
/// The mapping is beeshift's, not the house style's: `catui` has no opinion
/// about what a night shift looks like. See ADR-0005.
///
/// Yellow is the app's accent and red is the scheme's error colour, so neither
/// is available here. A day with no Shift has no Shift Colour — the accent
/// stands in wherever one is still needed.
@immutable
class ShiftColors extends ThemeExtension<ShiftColors> {
  const ShiftColors(this._byType);

  ShiftColors.forFlavor(Flavor flavor)
    : _byType = {
        ShiftType.primo: flavor.peach,
        ShiftType.secondo: flavor.blue,
        ShiftType.notte: flavor.mauve,
        ShiftType.smonto: flavor.teal,
        ShiftType.riposo: flavor.green,
        ShiftType.ferie: flavor.pink,
      };

  final Map<ShiftType, Color> _byType;

  /// Every Shift Type is present, so the lookup cannot miss.
  Color operator [](ShiftType type) => _byType[type]!;

  static ShiftColors of(BuildContext context) =>
      Theme.of(context).extension<ShiftColors>()!;

  @override
  ShiftColors copyWith({Map<ShiftType, Color>? byType}) =>
      ShiftColors(byType ?? _byType);

  @override
  ShiftColors lerp(ShiftColors? other, double t) {
    if (other == null) return this;
    return ShiftColors({
      for (final type in ShiftType.values)
        type: Color.lerp(this[type], other[type], t)!,
    });
  }
}

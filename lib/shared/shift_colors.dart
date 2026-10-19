import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'shift_type.dart';

/// The Shift Colour of each Shift Type: shadcn's palette, shade 300 on the
/// dark ground and 700 on the light one. See ADR-0006.
///
/// Amber is the app's accent and red is the error colour, so neither is
/// here. A day with no Shift has no Shift Colour — the accent stands in.
abstract final class ShiftColors {
  static const dark = <ShiftType, Color>{
    ShiftType.primo: Color(0xFFFDBA74), // orange-300
    ShiftType.secondo: Color(0xFF93C5FD), // blue-300
    ShiftType.notte: Color(0xFFC4B5FD), // violet-300
    ShiftType.smonto: Color(0xFF5EEAD4), // teal-300
    ShiftType.riposo: Color(0xFF86EFAC), // green-300
    ShiftType.ferie: Color(0xFFF9A8D4), // pink-300
  };

  static const light = <ShiftType, Color>{
    ShiftType.primo: Color(0xFFC2410C), // orange-700
    ShiftType.secondo: Color(0xFF1D4ED8), // blue-700
    ShiftType.notte: Color(0xFF6D28D9), // violet-700
    ShiftType.smonto: Color(0xFF0F766E), // teal-700
    ShiftType.riposo: Color(0xFF15803D), // green-700
    ShiftType.ferie: Color(0xFFBE185D), // pink-700
  };

  static Map<ShiftType, Color> of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

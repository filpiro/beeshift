import 'package:beeshift/shared/shift_colors.dart';
import 'package:beeshift/shared/shift_type.dart';
import 'package:beeshift/shared/theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

void main() {
  // The spec's own §3 table, independent of shift_colors.dart, so a typo
  // there has something to be caught against.
  const light = <ShiftType, Color>{
    ShiftType.primo: Color(0xFFC2410C),
    ShiftType.secondo: Color(0xFF1D4ED8),
    ShiftType.notte: Color(0xFF6D28D9),
    ShiftType.smonto: Color(0xFF0F766E),
    ShiftType.riposo: Color(0xFF15803D),
    ShiftType.ferie: Color(0xFFBE185D),
  };
  const dark = <ShiftType, Color>{
    ShiftType.primo: Color(0xFFFDBA74),
    ShiftType.secondo: Color(0xFF93C5FD),
    ShiftType.notte: Color(0xFFC4B5FD),
    ShiftType.smonto: Color(0xFF5EEAD4),
    ShiftType.riposo: Color(0xFF86EFAC),
    ShiftType.ferie: Color(0xFFF9A8D4),
  };

  for (final (name, theme, colors, table) in [
    ('light', lightTheme, ShiftColors.light, light),
    ('dark', darkTheme, ShiftColors.dark, dark),
  ]) {
    group(name, () {
      test('every Shift Type resolves to a distinct colour', () {
        final resolved = {for (final t in ShiftType.values) colors[t]};
        expect(resolved, hasLength(ShiftType.values.length));
      });

      test('neither the accent amber nor the error red is used', () {
        for (final type in ShiftType.values) {
          expect(colors[type], isNot(theme.colorScheme.primary));
          expect(colors[type], isNot(theme.colorScheme.destructive));
        }
      });

      test('the colours are the §3 table\'s own', () {
        for (final type in ShiftType.values) {
          expect(colors[type], table[type], reason: type.name);
        }
      });
    });
  }

  testWidgets('a widget reads the Shift Colours from the theme', (
    tester,
  ) async {
    late Map<ShiftType, Color> read;
    await tester.pumpWidget(
      ShadcnApp(
        theme: lightTheme,
        home: Builder(
          builder: (context) {
            read = ShiftColors.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(read[ShiftType.notte], light[ShiftType.notte]);
  });
}

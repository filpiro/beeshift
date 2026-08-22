import 'package:beeshift/shared/shift_colors.dart';
import 'package:beeshift/shared/shift_type.dart';
import 'package:beeshift/shared/theme.dart';
import 'package:catui/catui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (name, theme, flavor) in [
    ('latte', lightTheme, catppuccin.latte),
    ('mocha', darkTheme, catppuccin.mocha),
  ]) {
    group(name, () {
      final colors = theme.extension<ShiftColors>()!;

      test('every Shift Type resolves to a distinct colour', () {
        final resolved = {for (final t in ShiftType.values) colors[t]};
        expect(resolved, hasLength(ShiftType.values.length));
      });

      test('neither the accent yellow nor the error red is used', () {
        for (final type in ShiftType.values) {
          expect(colors[type], isNot(flavor.yellow));
          expect(colors[type], isNot(theme.colorScheme.error));
        }
      });

      test('the colours are the flavor\'s own', () {
        expect(colors[ShiftType.primo], flavor.peach);
        expect(colors[ShiftType.secondo], flavor.blue);
        expect(colors[ShiftType.notte], flavor.mauve);
        expect(colors[ShiftType.smonto], flavor.teal);
        expect(colors[ShiftType.riposo], flavor.green);
        expect(colors[ShiftType.ferie], flavor.pink);
      });
    });
  }

  testWidgets('a widget reads the Shift Colours from the theme', (
    tester,
  ) async {
    late ShiftColors read;
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: Builder(
          builder: (context) {
            read = ShiftColors.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(read[ShiftType.notte], catppuccin.latte.mauve);
  });
}

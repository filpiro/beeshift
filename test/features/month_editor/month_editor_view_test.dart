import 'package:beeshift/features/calendar/cubit/calendar_cubit.dart';
import 'package:beeshift/features/settings/cubit/theme_cubit.dart';
import 'package:beeshift/features/shell/shell_view.dart';
import 'package:beeshift/shared/shift_colors.dart';
import 'package:beeshift/shared/shift_type.dart';
import 'package:beeshift/shared/theme.dart';
import 'package:beeshift/shared/widgets/equal_row_segmented.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../data/fake_shifts_repository.dart';

/// The editor as reached from the Shell's bar — which month it targets, and
/// what happens on the way back. The payload itself is asserted on the cubit.
void main() {
  late FakeShiftsRepository repository;

  Future<CalendarCubit> pumpCalendar(
    WidgetTester tester, {
    Map<String, ShiftType> shifts = const {},
  }) async {
    repository = FakeShiftsRepository(shifts);
    final calendar = CalendarCubit(
      repository,
      clock: () => DateTime(2026, 2, 15),
    );
    await calendar.load();
    await tester.pumpWidget(
      ShadcnApp(
        theme: lightTheme,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<CalendarCubit>.value(value: calendar),
            BlocProvider<ThemeCubit>(
              create: (_) =>
                  ThemeCubit(read: () async => null, write: (_) async {}),
            ),
          ],
          child: ShellPage(repository: repository),
        ),
      ),
    );
    repository.calls.clear();
    return calendar;
  }

  Future<void> openEditor(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('Modifica')));
    await tester.pumpAndSettle();
  }

  testWidgets('the button opens the editor for the month on screen', (
    tester,
  ) async {
    await pumpCalendar(tester);
    await openEditor(tester);

    expect(find.text('Febbraio 2026'), findsOne);
    expect(find.text('1 Domenica'), findsOne, reason: '1 February is a Sunday');
    // The list is lazy, so the last day has to be scrolled to — and February
    // 2026 ends there, with no 29th and nothing from March.
    await tester.scrollUntilVisible(find.text('28 Sabato'), 300);
    expect(find.text('28 Sabato'), findsOne);
    expect(find.text('29 Domenica'), findsNothing);
  });

  testWidgets('swiping first targets the month swiped to', (tester) async {
    await pumpCalendar(tester);

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    await openEditor(tester);

    expect(find.text('Marzo 2026'), findsOne);
  });

  testWidgets('every day offers the six Shift Types as codes', (tester) async {
    await pumpCalendar(tester);
    await openEditor(tester);

    // The list is lazy, so assert against the days actually built.
    for (final shift in ShiftType.values) {
      expect(find.text(shift.code), findsWidgets, reason: shift.code);
      expect(find.text(shift.label), findsNothing, reason: shift.label);
    }
    // A header divider now separates the AppBar from the body — that one is
    // structural, not a line between rows, so the check is scoped to the list.
    expect(
      find.descendant(of: find.byType(ListView), matching: find.byType(Divider)),
      findsNothing,
      reason: 'space, not lines',
    );
    expect(find.byType(RadioGroup<ShiftType>), findsNothing);
    expect(find.byType(Radio), findsNothing);
  });

  testWidgets('a day line names the weekday in full', (tester) async {
    await pumpCalendar(tester);
    await openEditor(tester);

    expect(find.text('1 Domenica'), findsOne, reason: '1 February is a Sunday');
  });

  testWidgets('the codes announce their full names, one row, 48dp', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpCalendar(tester);
    await openEditor(tester);

    for (final shift in ShiftType.values) {
      expect(
        find.bySemanticsLabel(shift.label),
        findsWidgets,
        reason: shift.label,
      );
    }

    // Which one is picked is said out loud too, not left to the colour: the
    // whole design leans on hue now, so the spoken state is what keeps it
    // honest for anyone who cannot see it.
    expect(
      tester.getSemantics(find.bySemanticsLabel(ShiftType.riposo.label).first),
      isSemantics(isSelected: false),
    );
    await tester.tap(find.text(ShiftType.riposo.code).first);
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.bySemanticsLabel(ShiftType.riposo.label).first),
      isSemantics(isSelected: true),
    );

    // One row, and a target you can hit: the six codes of the first day share
    // a centre line, and the control they sit in is at least 48dp tall.
    final firstDay = find.byType(EqualRowSegmented<ShiftType>).first;
    expect(tester.getSize(firstDay).height, greaterThanOrEqualTo(48));
    final row = tester.getCenter(firstDay).dy;
    for (final shift in ShiftType.values) {
      expect(
        tester.getCenter(find.text(shift.code).first).dy,
        closeTo(row, 1),
        reason: shift.code,
      );
    }
    semantics.dispose();
  });

  testWidgets('a Shift Type once chosen cannot be taken back off', (
    tester,
  ) async {
    await pumpCalendar(tester);
    await openEditor(tester);

    await tester.tap(find.text(ShiftType.riposo.code).first);
    await tester.pumpAndSettle();
    // Tapping the selected segment again would empty the selection if the
    // control were left to its own devices. An Empty day is "not entered yet",
    // and nothing may put a day back there.
    await tester.tap(find.text(ShiftType.riposo.code).first);
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<EqualRowSegmented<ShiftType>>(
            find.byType(EqualRowSegmented<ShiftType>).first,
          )
          .selected,
      ShiftType.riposo,
    );
  });

  testWidgets('an existing Shift arrives pre-selected, an Empty day bare', (
    tester,
  ) async {
    await pumpCalendar(tester, shifts: {'2026-02-01': ShiftType.notte});
    await openEditor(tester);

    final controls = tester.widgetList<EqualRowSegmented<ShiftType>>(
      find.byType(EqualRowSegmented<ShiftType>),
    );
    expect(controls.first.selected, ShiftType.notte);
    // 2 February has nothing recorded: nothing selected is a real state.
    expect(controls.elementAt(1).selected, isNull);
  });

  testWidgets('a picked choice is a Shift Colour border and a bold letter, '
      'with no fill', (tester) async {
    await pumpCalendar(tester, shifts: {'2026-02-01': ShiftType.notte});
    await openEditor(tester);
    final theme = Theme.of(tester.element(find.text('Salva')));
    const colors = ShiftColors.light;

    /// The style the first day's given code is drawn with.
    ({BorderSide? side, TextStyle? label, bool filled}) styleOf(String code) {
      final button = find
          .ancestor(of: find.text(code), matching: find.byType(Button))
          .first;
      final widget = tester.widget<Button>(button);
      final context = tester.element(button);
      final decoration =
          widget.style.decoration(context, const {}) as BoxDecoration;
      final border = decoration.border as Border?;
      return (
        side: border == null
            ? null
            : BorderSide(color: border.top.color, width: border.top.width),
        label: widget.style.textStyle(context, const {}),
        filled: (decoration.color?.a ?? 0) > 0,
      );
    }

    // Every choice is outlined — nothing is a filled face any more, which is
    // what makes the colour the whole signal.
    final picked = styleOf(ShiftType.notte.code);
    expect(picked.side?.color, colors[ShiftType.notte]);
    expect(picked.side?.width, 1);
    expect(picked.label?.fontWeight, FontWeight.bold);
    expect(picked.label?.color, colors[ShiftType.notte]);
    expect(picked.filled, isFalse);

    final quiet = styleOf(ShiftType.riposo.code);
    expect(quiet.side?.color, theme.colorScheme.border);
    expect(quiet.label?.fontWeight, FontWeight.normal);
    expect(quiet.label?.color, theme.colorScheme.mutedForeground);
    // The same heading-sized letter the Filter's letters take.
    expect(picked.label?.fontSize, theme.typography.base.fontSize);
  });

  testWidgets('tapping a code writes nothing until Save', (tester) async {
    await pumpCalendar(tester);
    await openEditor(tester);

    await tester.tap(find.text(ShiftType.primo.code).first);
    await tester.pumpAndSettle();

    expect(repository.calls, isEmpty);
  });

  testWidgets('Save writes once, pops, and the Calendar re-queries', (
    tester,
  ) async {
    await pumpCalendar(tester);
    await openEditor(tester);

    await tester.tap(find.text(ShiftType.riposo.code).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();

    // One write, then a local read — and no sync anywhere in it.
    expect(repository.calls, ['upsertAll', 'fetchRange']);
    expect(repository.batches, [
      {'2026-02-01': ShiftType.riposo},
    ]);
    // Popped back to the Calendar, which now shows the saved Shift.
    expect(find.byKey(const Key('Modifica')), findsOne);
    expect(find.text(ShiftType.riposo.code), findsWidgets);
  });

  group('when a save fails', () {
    Future<void> failingSave(WidgetTester tester) async {
      await pumpCalendar(tester);
      await openEditor(tester);
      await tester.tap(find.text(ShiftType.riposo.code).first);
      await tester.pumpAndSettle();
      repository.failing.add('upsertAll');
      await tester.tap(find.text('Salva'));
      await tester.pumpAndSettle();
    }

    testWidgets('the editor stays put, with the selection intact', (
      tester,
    ) async {
      await failingSave(tester);

      expect(find.text('Febbraio 2026'), findsOne, reason: 'still the editor');
      expect(
        find.byKey(const Key('Modifica')),
        findsNothing,
        reason: 'did not pop',
      );
      expect(
        tester
            .widget<EqualRowSegmented<ShiftType>>(
              find.byType(EqualRowSegmented<ShiftType>).first,
            )
            .selected,
        ShiftType.riposo,
      );
    });

    testWidgets('the message is inline and does not go away on its own', (
      tester,
    ) async {
      await failingSave(tester);

      expect(find.byType(Alert), findsOne);

      // Still there long after any toast would have gone.
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
      expect(find.byType(Alert), findsOne);
    });

    testWidgets('Save retries and succeeds once connectivity returns', (
      tester,
    ) async {
      await failingSave(tester);

      repository.failing.remove('upsertAll');
      await tester.tap(find.text('Salva'));
      await tester.pumpAndSettle();

      // Two attempts, one written batch, then the pop and the re-query.
      expect(repository.calls, ['upsertAll', 'upsertAll', 'fetchRange']);
      expect(repository.batches, [
        {'2026-02-01': ShiftType.riposo},
      ]);
      expect(
        find.byKey(const Key('Modifica')),
        findsOne,
        reason: 'back on the Calendar',
      );
      expect(find.text(ShiftType.riposo.code), findsWidgets);
    });
  });
}

import 'package:beeshift/calendar_cubit.dart';
import 'package:beeshift/calendar_page.dart';
import 'package:beeshift/shift_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_shifts_repository.dart';

/// The editor as reached from the Calendar — which month it targets, and what
/// happens on the way back. The payload itself is asserted on the cubit.
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
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: calendar,
            child: CalendarPage(repository: repository),
          ),
        ),
      ),
    );
    repository.calls.clear();
    return calendar;
  }

  Future<void> openEditor(WidgetTester tester) async {
    await tester.tap(find.text('Modifica'));
    await tester.pumpAndSettle();
  }

  testWidgets('the button opens the editor for the month on screen', (
    tester,
  ) async {
    await pumpCalendar(tester);
    await openEditor(tester);

    expect(find.text('Febbraio 2026'), findsOne);
    expect(find.text('1 Dom'), findsOne, reason: '1 February is a Sunday');
    // The list is lazy, so the last day has to be scrolled to — and February
    // 2026 ends there, with no 29th and nothing from March.
    await tester.scrollUntilVisible(find.text('28 Sab'), 300);
    expect(find.text('28 Sab'), findsOne);
    expect(find.text('29 Dom'), findsNothing);
  });

  testWidgets('swiping first targets the month swiped to', (tester) async {
    await pumpCalendar(tester);

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    await openEditor(tester);

    expect(find.text('Marzo 2026'), findsOne);
  });

  testWidgets('every day offers the six Shift Types by name', (tester) async {
    await pumpCalendar(tester);
    await openEditor(tester);

    // The list is lazy, so assert against the days actually built.
    for (final shift in ShiftType.values) {
      expect(find.text(shift.label), findsWidgets, reason: shift.label);
    }
  });

  testWidgets('an existing Shift arrives pre-selected', (tester) async {
    await pumpCalendar(tester, shifts: {'2026-02-01': ShiftType.notte});
    await openEditor(tester);

    final radio = tester.widgetList<Radio<ShiftType>>(
      find.descendant(
        of: find.ancestor(
          of: find.text('1 Dom'),
          matching: find.byType(Column),
        ).last,
        matching: find.byType(Radio<ShiftType>),
      ),
    );
    expect(radio.length, ShiftType.values.length);
    expect(
      tester
          .widget<RadioGroup<ShiftType>>(find.byType(RadioGroup<ShiftType>).first)
          .groupValue,
      ShiftType.notte,
    );
  });

  testWidgets('tapping a radio writes nothing until Save', (tester) async {
    await pumpCalendar(tester);
    await openEditor(tester);

    await tester.tap(find.text('Primo').first);
    await tester.pumpAndSettle();

    expect(repository.calls, isEmpty);
  });

  testWidgets('Save writes once, pops, and the Calendar re-queries', (
    tester,
  ) async {
    await pumpCalendar(tester);
    await openEditor(tester);

    await tester.tap(find.text('Riposo').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();

    // One write, then a local read — and no sync anywhere in it.
    expect(repository.calls, ['upsertAll', 'fetchRange']);
    expect(repository.batches, [
      {'2026-02-01': ShiftType.riposo},
    ]);
    // Popped back to the Calendar, which now shows the saved Shift.
    expect(find.text('Modifica'), findsOne);
    expect(find.text(ShiftType.riposo.code), findsWidgets);
  });
}

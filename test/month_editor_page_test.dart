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
        home: BlocProvider.value(
          value: calendar,
          child: CalendarPage(repository: repository),
        ),
      ),
    );
    repository.calls.clear();
    return calendar;
  }

  Future<void> openEditor(WidgetTester tester) async {
    await tester.tap(find.byType(FloatingActionButton));
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
        // The nearest Column is the day's row; the ones further out belong to
        // the page's layout.
        of: find
            .ancestor(of: find.text('1 Dom'), matching: find.byType(Column))
            .first,
        matching: find.byType(Radio<ShiftType>),
      ),
    );
    expect(radio.length, ShiftType.values.length);
    expect(
      tester
          .widget<RadioGroup<ShiftType>>(
            find.byType(RadioGroup<ShiftType>).first,
          )
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
    expect(find.byType(FloatingActionButton), findsOne);
    expect(find.text(ShiftType.riposo.code), findsWidgets);
  });

  group('when a save fails', () {
    Future<void> failingSave(WidgetTester tester) async {
      await pumpCalendar(tester);
      await openEditor(tester);
      await tester.tap(find.text('Riposo').first);
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
        find.byType(FloatingActionButton),
        findsNothing,
        reason: 'did not pop',
      );
      expect(
        tester
            .widget<RadioGroup<ShiftType>>(
              find.byType(RadioGroup<ShiftType>).first,
            )
            .groupValue,
        ShiftType.riposo,
      );
    });

    testWidgets('the message is inline and does not go away on its own', (
      tester,
    ) async {
      await failingSave(tester);

      expect(find.byType(MaterialBanner), findsOne);
      expect(find.byType(SnackBar), findsNothing, reason: 'not a toast');

      // Still there long after any toast would have gone.
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
      expect(find.byType(MaterialBanner), findsOne);
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
        find.byType(FloatingActionButton),
        findsOne,
        reason: 'back on the Calendar',
      );
      expect(find.text(ShiftType.riposo.code), findsWidgets);
    });
  });
}

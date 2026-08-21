import 'package:beeshift/features/calendar/calendar_view.dart';
import 'package:beeshift/features/calendar/cubit/calendar_cubit.dart';
import 'package:beeshift/shared/shift_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../data/fake_shifts_repository.dart';

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
    expect(find.byType(Divider), findsNothing, reason: 'space, not lines');
    expect(find.byType(RadioGroup<ShiftType>), findsNothing);
    expect(find.byType(Radio<ShiftType>), findsNothing);
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

    // One row, and a target you can hit: the six codes of the first day share
    // a centre line, and the control they sit in is at least 48dp tall.
    final firstDay = find.byType(SegmentedButton<ShiftType>).first;
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
          .widget<SegmentedButton<ShiftType>>(
            find.byType(SegmentedButton<ShiftType>).first,
          )
          .selected,
      {ShiftType.riposo},
    );
  });

  testWidgets('an existing Shift arrives pre-selected, an Empty day bare', (
    tester,
  ) async {
    await pumpCalendar(tester, shifts: {'2026-02-01': ShiftType.notte});
    await openEditor(tester);

    final controls = tester.widgetList<SegmentedButton<ShiftType>>(
      find.byType(SegmentedButton<ShiftType>),
    );
    expect(controls.first.selected, {ShiftType.notte});
    // 2 February has nothing recorded: nothing selected is a real state.
    expect(controls.elementAt(1).selected, isEmpty);
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
    expect(find.byType(FloatingActionButton), findsOne);
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
        find.byType(FloatingActionButton),
        findsNothing,
        reason: 'did not pop',
      );
      expect(
        tester
            .widget<SegmentedButton<ShiftType>>(
              find.byType(SegmentedButton<ShiftType>).first,
            )
            .selected,
        {ShiftType.riposo},
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

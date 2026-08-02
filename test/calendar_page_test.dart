import 'package:beeshift/calendar_cubit.dart';
import 'package:beeshift/calendar_page.dart';
import 'package:beeshift/shift_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_shifts_repository.dart';

/// Only what the widget alone can prove: that the two triggers are wired to
/// the Calendar's refresh. What refresh then does is asserted on the cubit.
void main() {
  late FakeShiftsRepository repository;

  Future<void> pumpCalendar(WidgetTester tester) async {
    repository = FakeShiftsRepository();
    final cubit = CalendarCubit(repository, clock: () => DateTime(2026, 2, 15));
    await cubit.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: CalendarPage(repository: repository),
          ),
        ),
      ),
    );
    repository.calls.clear();
  }

  testWidgets('returning to the foreground syncs, then re-queries', (
    tester,
  ) async {
    await pumpCalendar(tester);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(repository.calls, ['sync', 'fetchRange']);
  });

  testWidgets('pulling down on the Calendar syncs, then re-queries', (
    tester,
  ) async {
    await pumpCalendar(tester);

    await tester.drag(find.byType(PageView), const Offset(0, 300));
    await tester.pumpAndSettle();

    expect(repository.calls, ['sync', 'fetchRange']);
  });

  testWidgets('swiping between the months does not sync', (tester) async {
    await pumpCalendar(tester);

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();

    expect(repository.calls, isEmpty);
  });

  group('when a sync fails', () {
    /// The Calendar as loaded, with a Shift on screen to prove a failure
    /// leaves it there.
    Future<void> pumpLoaded(WidgetTester tester) async {
      repository = FakeShiftsRepository({'2026-02-10': ShiftType.notte});
      final cubit = CalendarCubit(
        repository,
        clock: () => DateTime(2026, 2, 15),
      );
      await cubit.load();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: cubit,
              child: CalendarPage(repository: repository),
            ),
          ),
        ),
      );
      repository.failing.add('sync');
    }

    testWidgets('a failed pull-to-refresh says so, transiently', (
      tester,
    ) async {
      await pumpLoaded(tester);

      await tester.drag(find.byType(PageView), const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(find.text('Aggiornamento non riuscito'), findsOne);
      // The data that was on screen is still on screen.
      expect(find.text(ShiftType.notte.code), findsWidgets);

      // Transient: it goes on its own, without anyone dismissing it.
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      expect(find.text('Aggiornamento non riuscito'), findsNothing);
    });

    testWidgets('a failed resume sync shows nothing at all', (tester) async {
      await pumpLoaded(tester);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(repository.calls.last, 'sync', reason: 'it did try');
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(MaterialBanner), findsNothing);
      expect(find.text(ShiftType.notte.code), findsWidgets);
    });
  });
}

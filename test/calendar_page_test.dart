import 'package:beeshift/calendar_cubit.dart';
import 'package:beeshift/calendar_page.dart';
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
          body: BlocProvider.value(value: cubit, child: const CalendarPage()),
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
}

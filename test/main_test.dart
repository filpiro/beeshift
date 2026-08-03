import 'package:beeshift/main.dart';
import 'package:beeshift/shift_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_shifts_repository.dart';

/// The one failure with no graceful degradation: without the database there is
/// no app, so it takes the whole screen and offers the only action that helps.
void main() {
  testWidgets('a failed connect fills the screen, and Retry re-opens', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      MainApp(
        open: () async {
          attempts++;
          // Opening the real thing waits on the disk and the network, so a
          // fake that failed synchronously would not be the same shape.
          await Future<void>.delayed(Duration.zero);
          // Fails once, the way a first launch out of signal does, then works.
          if (attempts == 1) throw Exception('cannot reach the database');
          return FakeShiftsRepository({'2026-02-10': ShiftType.notte});
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Impossibile aprire il database.'), findsOne);
    expect(
      find.byType(FloatingActionButton),
      findsNothing,
      reason: 'nothing to edit behind a database that would not open',
    );

    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();

    // A second attempt was actually made, and the app is now the Calendar.
    expect(attempts, 2);
    expect(find.text('Impossibile aprire il database.'), findsNothing);
    expect(find.byType(FloatingActionButton), findsOne);
  });

  testWidgets('Retry that fails again returns to the same error', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      MainApp(
        open: () async {
          attempts++;
          // Opening the real thing waits on the disk and the network, so a
          // fake that failed synchronously would not be the same shape.
          await Future<void>.delayed(Duration.zero);
          throw Exception('still cannot reach the database');
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Impossibile aprire il database.'), findsOne);
  });
}

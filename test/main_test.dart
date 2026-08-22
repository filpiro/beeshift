import 'dart:async';

import 'package:beeshift/data/shifts_repository.dart';
import 'package:beeshift/main.dart';
import 'package:beeshift/shared/shift_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/fake_shifts_repository.dart';

/// The one failure with no graceful degradation: without the database there is
/// no app, so it takes the whole screen and offers the only action that helps.
void main() {
  // MainApp builds a real ThemeCubit, which reads SharedPreferences on
  // construction — these tests never care about theme, but the channel
  // still needs a mock backing it.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  _firstLaunch();

  testWidgets('no bar over the opening spinner', (tester) async {
    // Never completes: the point is what is on screen before it does.
    await tester.pumpWidget(
      MainApp(open: () => Completer<ShiftsRepository>().future),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOne);
    expect(find.byTooltip('Modifica'), findsNothing);
    expect(find.byTooltip('Impostazioni'), findsNothing);
  });

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
      find.byTooltip('Modifica'),
      findsNothing,
      reason: 'nothing to edit behind a database that would not open',
    );

    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();

    // A second attempt was actually made, and the app is now the Calendar.
    expect(attempts, 2);
    expect(find.text('Impossibile aprire il database.'), findsNothing);
    expect(find.byTooltip('Modifica'), findsOne);
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

/// A replica file that has just been created is an empty SQLite database: the
/// first read finds no `shifts` table at all. Nothing else in the app ever
/// syncs before a read, so the first launch has to.
void _firstLaunch() {
  test('a replica with no schema is synced before the first read', () async {
    final repository = FakeShiftsRepository()..schema = false;

    await syncIfEmpty(repository);

    expect(repository.calls, ['hasShiftsTable', 'sync']);
  });

  test('a replica that already has its schema stays offline', () async {
    final repository = FakeShiftsRepository();

    await syncIfEmpty(repository);

    expect(repository.calls, ['hasShiftsTable'], reason: 'no network');
  });

  test('a first sync that fails is left to the error screen', () async {
    // Offline, a fresh install usually dies earlier, inside connect, which is
    // what bootstraps the replica. Either way there is nothing to show, so the
    // failure travels to the retry screen rather than being swallowed here.
    final repository = FakeShiftsRepository()..schema = false;
    repository.failing.add('sync');

    await expectLater(syncIfEmpty(repository), throwsA(isA<Exception>()));
  });
}

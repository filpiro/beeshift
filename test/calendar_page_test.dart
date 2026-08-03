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

  group('the tile grid', () {
    /// The Calendar at a chosen "now", on a screen of a chosen size.
    Future<void> pumpAt(
      WidgetTester tester,
      DateTime now, {
      Size size = const Size(390, 844),
    }) async {
      tester.view.physicalSize = size * tester.view.devicePixelRatio;
      addTearDown(tester.view.resetPhysicalSize);
      repository = FakeShiftsRepository();
      final cubit = CalendarCubit(repository, clock: () => now);
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
    }

    /// A tile filled with the primary colour — the one and only highlight.
    Finder filledTiles(WidgetTester tester) {
      final scheme = Theme.of(
        tester.element(find.byType(CalendarPage)),
      ).colorScheme;
      return find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is ShapeDecoration &&
            (widget.decoration as ShapeDecoration).color == scheme.primary,
      );
    }

    testWidgets('names the visible month, and renames it on a swipe', (
      tester,
    ) async {
      await pumpAt(tester, DateTime(2026, 2, 15));

      expect(find.text('Febbraio 2026'), findsOne);

      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text('Marzo 2026'), findsOne);
      expect(find.text('Febbraio 2026'), findsNothing);
    });

    testWidgets('exactly one tile is filled, and it is today', (tester) async {
      await pumpAt(tester, DateTime(2026, 2, 15));

      expect(filledTiles(tester), findsOne);
      expect(
        find.descendant(
          of: filledTiles(tester),
          matching: find.text('15'),
        ),
        findsOne,
      );
    });

    testWidgets('today is never filled on the page it is filler on', (
      tester,
    ) async {
      // 31 August 2026 is a Monday: page one's last day and page two's first
      // filler day. Only the page that owns it fills it — so however many
      // pages are mounted, there is never a second filled tile.
      await pumpAt(tester, DateTime(2026, 8, 31));
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text('Settembre 2026'), findsOne, reason: 'page two is up');
      // Counted rather than matched: whether the carousel keeps page one
      // mounted is its own business, but two filled tiles is never right.
      expect(
        tester.widgetList(filledTiles(tester)).length,
        lessThanOrEqualTo(1),
      );
    });

    testWidgets('the whole month fits, and nothing overflows', (tester) async {
      // A six-row month on a short screen: the tiles compress below square
      // rather than running off the bottom. An overflow fails the test by
      // itself — the harness reports it as an exception.
      await pumpAt(
        tester,
        DateTime(2026, 8, 15),
        size: const Size(360, 420),
      );

      expect(tester.takeException(), isNull);
      // Every day of August is on screen: no scrolling, nothing clipped.
      for (final day in [1, 15, 31]) {
        expect(find.text('$day'), findsWidgets, reason: 'August $day');
      }
    });
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

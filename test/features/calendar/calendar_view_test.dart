import 'package:beeshift/features/calendar/calendar_view.dart';
import 'package:beeshift/features/calendar/cubit/calendar_cubit.dart';
import 'package:beeshift/shared/shift_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../data/fake_shifts_repository.dart';

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
        home: BlocProvider.value(value: cubit, child: const CalendarPage()),
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

  /// The Calendar at a chosen "now", on a screen of a chosen size.
  Future<void> pumpAt(
    WidgetTester tester,
    DateTime now, {
    Size size = const Size(390, 844),
    Map<String, ShiftType> shifts = const {},
  }) async {
    tester.view.physicalSize = size * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
    repository = FakeShiftsRepository(shifts);
    final cubit = CalendarCubit(repository, clock: () => now);
    await cubit.load();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubit, child: const CalendarPage()),
      ),
    );
  }

  group('the tile grid', () {
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
        find.descendant(of: filledTiles(tester), matching: find.text('15')),
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
      await pumpAt(tester, DateTime(2026, 8, 15), size: const Size(360, 420));

      expect(tester.takeException(), isNull);
      // Every day of August is on screen: no scrolling, nothing clipped.
      for (final day in [1, 15, 31]) {
        expect(find.text('$day'), findsWidgets, reason: 'August $day');
      }
    });
  });

  /// Only the wiring: that a tap reaches the Filter and that the grid redraws
  /// from it. The match rule itself is asserted on the cubit.
  group('the Filter', () {
    /// The opacity a given day is drawn at.
    double opacityOf(WidgetTester tester, String day) {
      final tile = find
          .ancestor(of: find.text(day), matching: find.byType(Opacity))
          .first;
      return tester.widget<Opacity>(tile).opacity;
    }

    Future<void> pumpFiltered(WidgetTester tester) => pumpAt(
      tester,
      DateTime(2026, 2, 15),
      shifts: {
        '2026-02-02': ShiftType.notte, // Monday
        '2026-02-03': ShiftType.notte, // Tuesday
        '2026-02-04': ShiftType.primo, // Wednesday
      },
    );

    const shiftGroup = 'Filtra per turno';
    const weekdayGroup = 'Filtra per giorno';

    /// A chip inside one of the two groups. Always scoped: the same letter
    /// appears in both — `S` is Smonto under `Filtra per turno` and Sabato
    /// under `Filtra per giorno` — so a bare label finds two chips that mean
    /// different things. The weekday header draws the same letters again.
    Finder chipIn(String group, String label) => find.descendant(
      of: find.byKey(Key(group)),
      matching: find.widgetWithText(FilterChip, label),
    );

    Finder chipsIn(String group) => find.descendant(
      of: find.byKey(Key(group)),
      matching: find.byType(FilterChip),
    );

    testWidgets('draws both groups on open, with nothing to expand', (
      tester,
    ) async {
      await pumpFiltered(tester);

      expect(find.byType(ExpansionTile), findsNothing);
      // The disclosure's chrome went with it: nothing names the block, and
      // nothing says the selection a second time.
      expect(find.text('Filtri'), findsNothing);
      expect(find.text('Azzera'), findsNothing);
      expect(find.text(shiftGroup), findsOne);
      expect(find.text(weekdayGroup), findsOne);
      expect(chipsIn(shiftGroup), findsNWidgets(ShiftType.values.length));
      expect(chipsIn(weekdayGroup), findsNWidgets(DateTime.daysPerWeek));
      // The collision the headings exist to settle.
      expect(find.widgetWithText(FilterChip, 'S'), findsNWidgets(2));
    });

    testWidgets('the weekday header is still a heading and nothing more', (
      tester,
    ) async {
      await pumpFiltered(tester);

      final headerL = find.descendant(
        of: find.byKey(const Key('weekday-header')),
        matching: find.text('L'),
      );
      expect(headerL, findsOne);
      expect(
        find.ancestor(of: headerL, matching: find.byType(InkWell)),
        findsNothing,
      );
    });

    testWidgets('the groups sit above the title, which sits above the grid', (
      tester,
    ) async {
      await pumpFiltered(tester);

      expect(
        tester.getRect(find.byKey(const Key(weekdayGroup))).bottom,
        lessThan(tester.getRect(find.text('Febbraio 2026')).top),
      );
      expect(
        tester.getRect(find.text('Febbraio 2026')).bottom,
        lessThan(tester.getRect(find.byKey(const Key('weekday-header'))).top),
      );
    });

    testWidgets('tapping a Shift Code dims every day that is not it', (
      tester,
    ) async {
      await pumpFiltered(tester);
      expect(opacityOf(tester, '4'), 1, reason: 'nothing selected yet');

      await tester.tap(chipIn(shiftGroup, ShiftType.notte.code));
      await tester.pumpAndSettle();

      expect(opacityOf(tester, '2'), 1, reason: 'an N');
      expect(opacityOf(tester, '4'), 0.35, reason: 'a 7');
      expect(opacityOf(tester, '9'), 0.35, reason: 'an Empty day');
      // Today is 15 February, Empty, and the one filled tile.
      expect(opacityOf(tester, '15'), 0.35, reason: 'today is not exempt');
    });

    testWidgets('tapping a weekday narrows it further', (tester) async {
      await pumpFiltered(tester);

      await tester.tap(chipIn(shiftGroup, ShiftType.notte.code));
      await tester.tap(chipIn(weekdayGroup, 'L'));
      await tester.pumpAndSettle();

      expect(opacityOf(tester, '2'), 1, reason: 'a Monday N');
      expect(opacityOf(tester, '3'), 0.35, reason: 'a Tuesday N');
    });

    testWidgets('tapping the same chip again gives the month back', (
      tester,
    ) async {
      await pumpFiltered(tester);

      await tester.tap(chipIn(shiftGroup, ShiftType.notte.code));
      await tester.pumpAndSettle();
      await tester.tap(chipIn(shiftGroup, ShiftType.notte.code));
      await tester.pumpAndSettle();

      expect(opacityOf(tester, '4'), 1);
      expect(opacityOf(tester, '15'), 1);
    });

    testWidgets('the selection survives a swipe', (tester) async {
      // The controls sit outside the carousel, so paging is not a reason to
      // forget what was chosen.
      await pumpFiltered(tester);
      await tester.tap(chipIn(shiftGroup, ShiftType.notte.code));
      await tester.pumpAndSettle();

      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text('Marzo 2026'), findsOne, reason: 'page two is up');
      expect(
        tester
            .widget<FilterChip>(chipIn(shiftGroup, ShiftType.notte.code))
            .selected,
        isTrue,
      );
    });

    testWidgets('the grid still fits under the controls on a short screen', (
      tester,
    ) async {
      // A six-row month on a short screen with four permanent rows of chrome
      // above it — the worst case for the space the grid has left.
      await pumpAt(tester, DateTime(2026, 8, 15), size: const Size(360, 420));

      expect(tester.takeException(), isNull);
      expect(find.text('31'), findsWidgets, reason: 'the last day is drawn');
    });

    testWidgets('every chip speaks its Italian name, its state, and can be '
        'activated', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpFiltered(tester);

      // The letters are drawn; the names are what is spoken — which is also
      // what tells the two `M`s apart.
      final monday = find.descendant(
        of: find.byKey(const Key(weekdayGroup)),
        matching: find.bySemanticsLabel('Lunedì'),
      );
      expect(monday, findsOne);
      expect(
        find.descendant(
          of: find.byKey(const Key(shiftGroup)),
          matching: find.bySemanticsLabel(ShiftType.notte.label),
        ),
        findsOne,
      );
      // The two `M`s. The drawn letter cannot tell them apart at all, so the
      // spoken name is the only thing that does.
      for (final name in ['Martedì', 'Mercoledì']) {
        expect(
          find.descendant(
            of: find.byKey(const Key(weekdayGroup)),
            matching: find.bySemanticsLabel(name),
          ),
          findsOne,
          reason: name,
        );
      }
      expect(
        tester.getSemantics(monday),
        isSemantics(isButton: true, isSelected: false, hasTapAction: true),
      );

      final notte = find.descendant(
        of: find.byKey(const Key(shiftGroup)),
        matching: find.bySemanticsLabel(ShiftType.notte.label),
      );
      await tester.tap(chipIn(weekdayGroup, 'L'));
      await tester.tap(chipIn(shiftGroup, ShiftType.notte.code));
      await tester.pumpAndSettle();

      expect(tester.getSemantics(monday), isSemantics(isSelected: true));
      expect(tester.getSemantics(notte), isSemantics(isSelected: true));
      // The chips are the whole account of what is selected — no line
      // anywhere restates it in letters.
      expect(find.text('N, L'), findsNothing);
      handle.dispose();
    });
  });

  group('when the very first load fails', () {
    /// A brand-new install with no schema in the replica: the first query
    /// throws and there is nothing to draw.
    Future<void> pumpFirstLoad(WidgetTester tester) async {
      repository = FakeShiftsRepository();
      repository.failing.add('fetchRange');
      final cubit = CalendarCubit(
        repository,
        clock: () => DateTime(2026, 2, 15),
      );
      await cubit.load();
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(value: cubit, child: const CalendarPage()),
        ),
      );
    }

    testWidgets('says so rather than spinning forever', (tester) async {
      await pumpFirstLoad(tester);

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Impossibile leggere i turni.'), findsOne);
    });

    testWidgets('Riprova syncs and draws the Calendar', (tester) async {
      await pumpFirstLoad(tester);
      repository.failing.clear();

      await tester.tap(find.text('Riprova'));
      await tester.pumpAndSettle();

      // Sync first: the schema arrives with it, which is the whole point.
      expect(repository.calls.sublist(1), ['sync', 'fetchRange']);
      expect(find.text('Febbraio 2026'), findsOne);
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
          home: BlocProvider.value(value: cubit, child: const CalendarPage()),
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

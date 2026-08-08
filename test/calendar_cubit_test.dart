import 'package:beeshift/calendar_cubit.dart';
import 'package:beeshift/shift_type.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_shifts_repository.dart';

/// The primary seam: the grid lives in the Calendar's state, so every shape
/// assertion here runs without building a widget. "Now" is injected, never
/// read from the system clock.
void main() {
  Future<CalendarCubit> loadedFor(
    DateTime now, {
    Map<String, ShiftType> shifts = const {},
    FakeShiftsRepository? repository,
  }) async {
    final cubit = CalendarCubit(
      repository ?? FakeShiftsRepository(shifts),
      clock: () => now,
    );
    await cubit.load();
    return cubit;
  }

  /// The current month's grid — the page the Calendar opens on.
  Future<List<DayCell>> gridFor(
    DateTime now, {
    Map<String, ShiftType> shifts = const {},
    FakeShiftsRepository? repository,
  }) async {
    final cubit = await loadedFor(now, shifts: shifts, repository: repository);
    return cubit.state.grids!.first;
  }

  test('a month starting on a Monday has no leading filler', () async {
    // June 2026 starts on a Monday and has 30 days: five full rows.
    final cells = await gridFor(DateTime(2026, 6, 15));

    expect(cells.length, 35);
    expect(cells.first.date, DateTime(2026, 6, 1));
    expect(cells.first.isFiller, isFalse);
    expect(cells.last.date, DateTime(2026, 7, 5));
    expect(cells.where((cell) => cell.isFiller).length, 5);
  });

  test(
    'a month starting on a Sunday is padded with six leading days',
    () async {
      // February 2026 starts on a Sunday: six filler days before the 1st.
      final cells = await gridFor(DateTime(2026, 2, 15));

      expect(cells.length, 35);
      expect(cells.first.date, DateTime(2026, 1, 26));
      expect(cells.take(6).every((cell) => cell.isFiller), isTrue);
      expect(cells[6].date, DateTime(2026, 2, 1));
    },
  );

  test(
    'a 28-day February on a Monday is exactly four rows, no filler',
    () async {
      // February 2027: 28 days starting Monday, the only shape with no filler.
      final cells = await gridFor(DateTime(2027, 2, 15));

      expect(cells.length, 28);
      expect(cells.any((cell) => cell.isFiller), isFalse);
      expect(cells.last.date, DateTime(2027, 2, 28));
    },
  );

  test('every row is seven days and weeks start on Monday', () async {
    for (final now in [
      DateTime(2026, 6, 15),
      DateTime(2026, 2, 15),
      DateTime(2027, 2, 15),
    ]) {
      final cells = await gridFor(now);

      expect(cells.length % 7, 0, reason: '$now');
      expect(cells.first.date.weekday, DateTime.monday, reason: '$now');
      expect(cells.last.date.weekday, DateTime.sunday, reason: '$now');
      // Consecutive days, no gaps and no repeats.
      expect(
        cells.map((cell) => cell.date).toList(),
        List.generate(
          cells.length,
          (index) => cells.first.date.add(Duration(days: index)),
        ),
        reason: '$now',
      );
    }
  });

  test(
    'cells carry the Shift recorded for their day, filler included',
    () async {
      final cells = await gridFor(
        DateTime(2026, 2, 15),
        shifts: {
          '2026-01-27': ShiftType.notte, // leading filler
          '2026-02-01': ShiftType.riposo,
          '2026-03-01': ShiftType.ferie, // trailing filler
        },
      );

      DayCell cellOn(DateTime date) =>
          cells.firstWhere((cell) => cell.date == date);

      expect(cellOn(DateTime(2026, 1, 27)).shift, ShiftType.notte);
      expect(cellOn(DateTime(2026, 2, 1)).shift, ShiftType.riposo);
      expect(cellOn(DateTime(2026, 3, 1)).shift, ShiftType.ferie);
      // An Empty day is empty, filler or not.
      expect(cellOn(DateTime(2026, 1, 28)).shift, isNull);
      expect(cellOn(DateTime(2026, 2, 2)).shift, isNull);
    },
  );

  test('loads with one query spanning the grids of both pages', () async {
    final repository = FakeShiftsRepository();
    final cubit = await loadedFor(
      DateTime(2026, 2, 15),
      repository: repository,
    );

    final grids = cubit.state.grids!;
    expect(repository.ranges, [(grids.first.first.date, grids.last.last.date)]);
  });

  test('exactly one cell is today, and it is the injected day', () async {
    // A time of day, not midnight: "now" is an instant, today is a day.
    final cells = await gridFor(DateTime(2026, 2, 15, 23, 45));

    expect(cells.where((cell) => cell.isToday).map((cell) => cell.date), [
      DateTime(2026, 2, 15),
    ]);
  });

  /// Ticket 09 dropped the current-week band, so today is the only highlight
  /// the Calendar's state carries. The band's edge cases — a week spilling into
  /// an adjacent month — went with it; today is a single day and cannot spill.
  test('today is the only highlight, Shift or no Shift', () async {
    final cells = await gridFor(
      DateTime(2026, 2, 15),
      shifts: {'2026-02-09': ShiftType.notte},
    );

    DayCell cellOn(DateTime date) =>
        cells.firstWhere((cell) => cell.date == date);

    // Today is Empty and still today; the day with a Shift is not.
    expect(cellOn(DateTime(2026, 2, 15)).shift, isNull);
    expect(cellOn(DateTime(2026, 2, 15)).isToday, isTrue);
    expect(cellOn(DateTime(2026, 2, 9)).isToday, isFalse);
  });

  test(
    'the Data Window is this month and the next, and nothing else',
    () async {
      final cubit = await loadedFor(DateTime(2026, 2, 15));

      expect(cubit.state.months, [DateTime(2026, 2), DateTime(2026, 3)]);
      expect(cubit.state.grids!.length, 2, reason: 'there is no third page');
    },
  );

  test('a December "now" puts the next month in the following year', () async {
    final cubit = await loadedFor(DateTime(2026, 12, 15));

    expect(cubit.state.months, [DateTime(2026, 12), DateTime(2027, 1)]);
    expect(
      cubit.state.grids!.last.any((cell) => cell.date.year == 2027),
      isTrue,
    );
  });

  test('the visible month starts on this month and follows the page', () async {
    final cubit = await loadedFor(DateTime(2026, 2, 15));

    expect(cubit.state.visibleMonth, DateTime(2026, 2));

    cubit.showPage(1);
    expect(cubit.state.visibleMonth, DateTime(2026, 3));

    cubit.showPage(0);
    expect(cubit.state.visibleMonth, DateTime(2026, 2));
  });

  test('swiping never fetches — both pages come from the one load', () async {
    final repository = FakeShiftsRepository();
    final cubit = await loadedFor(
      DateTime(2026, 2, 15),
      repository: repository,
    );

    cubit.showPage(1);
    cubit.showPage(0);

    expect(repository.ranges.length, 1);
  });

  test('the second page is the next month, with its own filler', () async {
    final cubit = await loadedFor(DateTime(2026, 2, 15));

    // March 2026 starts on a Sunday: six leading filler days from February.
    final next = cubit.state.grids!.last;
    expect(next.first.date, DateTime(2026, 2, 23));
    expect(next.take(6).every((cell) => cell.isFiller), isTrue);
    expect(next[6].date, DateTime(2026, 3, 1));
  });

  test(
    'today appears on both pages when it is the last day of a month',
    () async {
      // 31 August 2026 is a Monday, so it is both the last row of page one and
      // the leading filler of page two. The state flags it on both; which page
      // actually fills it is the widget's call — see calendar_page_test.
      final cubit = await loadedFor(DateTime(2026, 8, 31));

      final onThisPage = cubit.state.grids!.first.firstWhere(
        (cell) => cell.date == DateTime(2026, 8, 31),
      );
      expect(onThisPage.isFiller, isFalse);
      expect(onThisPage.isToday, isTrue);

      final onNextPage = cubit.state.grids!.last.first;
      expect(onNextPage.date, DateTime(2026, 8, 31));
      expect(onNextPage.isFiller, isTrue);
      expect(onNextPage.isToday, isTrue);
    },
  );

  /// The match rule, asserted where it lives: two groups, OR within one and
  /// AND across the two, with an empty group passing everything.
  group('the Filter', () {
    /// February 2026, with a Shift on a Monday, a Shift on a Tuesday, and an
    /// Empty day on another Monday.
    Future<CalendarCubit> filterable() => loadedFor(
      DateTime(2026, 2, 15),
      shifts: {
        '2026-02-02': ShiftType.notte, // Monday
        '2026-02-03': ShiftType.notte, // Tuesday
        '2026-02-04': ShiftType.primo, // Wednesday
        // 2026-02-09, a Monday, is left Empty on purpose.
      },
    );

    /// A day of the current month's page.
    DayCell cellOn(CalendarCubit cubit, int day) => cubit.state.grids!.first
        .firstWhere((cell) => cell.date == DateTime(2026, 2, day));

    test('nothing selected mutes nothing, Empty days included', () async {
      final cubit = await filterable();

      expect(
        cubit.state.grids!.expand((grid) => grid).any(cubit.state.muted),
        isFalse,
      );
    });

    test('a Shift Filter mutes every other Shift Type, and every Empty '
        'day', () async {
      final cubit = await filterable();

      cubit.toggleShift(ShiftType.notte);

      expect(cubit.state.muted(cellOn(cubit, 2)), isFalse, reason: 'N');
      expect(cubit.state.muted(cellOn(cubit, 3)), isFalse, reason: 'N');
      expect(cubit.state.muted(cellOn(cubit, 4)), isTrue, reason: '7, not N');
      expect(cubit.state.muted(cellOn(cubit, 9)), isTrue, reason: 'Empty');
    });

    test('selections within a group are alternatives', () async {
      final cubit = await filterable();

      cubit.toggleShift(ShiftType.notte);
      cubit.toggleShift(ShiftType.primo);

      expect(cubit.state.muted(cellOn(cubit, 2)), isFalse, reason: 'N');
      expect(cubit.state.muted(cellOn(cubit, 4)), isFalse, reason: '7');
      expect(cubit.state.muted(cellOn(cubit, 9)), isTrue, reason: 'Empty');
    });

    test('a Weekday Filter mutes the other six days, Empty days too', () async {
      final cubit = await filterable();

      cubit.toggleWeekday(DateTime.monday);

      expect(cubit.state.muted(cellOn(cubit, 2)), isFalse, reason: 'Monday');
      expect(cubit.state.muted(cellOn(cubit, 3)), isTrue, reason: 'Tuesday');
      // "All Shift Types" means the six, not the absence of one — so a Monday
      // with nothing recorded is muted like any other non-answer.
      expect(
        cubit.state.muted(cellOn(cubit, 9)),
        isTrue,
        reason: 'an Empty Monday',
      );
    });

    test('the two groups are conditions, not alternatives', () async {
      final cubit = await filterable();

      cubit.toggleWeekday(DateTime.monday);
      cubit.toggleShift(ShiftType.notte);

      expect(cubit.state.muted(cellOn(cubit, 2)), isFalse, reason: 'Monday, N');
      expect(cubit.state.muted(cellOn(cubit, 3)), isTrue, reason: 'N, Tuesday');
      expect(
        cubit.state.muted(cellOn(cubit, 16)),
        isTrue,
        reason: 'Monday, Empty',
      );
    });

    test('today is muted like any other day', () async {
      // 15 February 2026 is a Sunday and Empty: the one tile the Calendar
      // fills is not exempt from the rule.
      final cubit = await filterable();

      cubit.toggleShift(ShiftType.notte);

      expect(cellOn(cubit, 15).isToday, isTrue);
      expect(cubit.state.muted(cellOn(cubit, 15)), isTrue);
    });

    test('a filler day is judged like any other day', () async {
      // 26 and 27 January 2026 are leading filler on February's page. The
      // answer makes no visible difference — the widget dims filler either
      // way — but it is the Shift that decides it, never the filler flag.
      final cubit = await loadedFor(
        DateTime(2026, 2, 15),
        shifts: {'2026-01-26': ShiftType.notte, '2026-01-27': ShiftType.primo},
      );
      final grid = cubit.state.grids!.first;

      cubit.toggleShift(ShiftType.notte);

      expect(grid.first.isFiller, isTrue);
      expect(cubit.state.muted(grid.first), isFalse, reason: 'a filler N');
      expect(cubit.state.muted(grid[1]), isTrue, reason: 'a filler 7');
    });

    test('the Filter reaches the second page of the carousel', () async {
      // Both pages are drawn from the one state, so a Filter that stopped at
      // the first would be a carousel showing two different months.
      final cubit = await loadedFor(
        DateTime(2026, 2, 15),
        shifts: {'2026-03-10': ShiftType.notte, '2026-03-11': ShiftType.primo},
      );

      cubit.toggleShift(ShiftType.notte);

      final next = cubit.state.grids!.last;
      DayCell cellOn(int day) =>
          next.firstWhere((cell) => cell.date == DateTime(2026, 3, day));
      expect(cubit.state.muted(cellOn(10)), isFalse);
      expect(cubit.state.muted(cellOn(11)), isTrue);
    });

    test('the Month Editor still opens on the whole month', () async {
      // The Filter is a way of reading. The editor is for writing, and hiding
      // a day you can write to would be a trap.
      final cubit = await filterable();
      final before = cubit.state.visibleMonthShifts;

      cubit.toggleShift(ShiftType.notte);
      cubit.toggleWeekday(DateTime.monday);

      expect(cubit.state.visibleMonthShifts, before);
    });

    test('toggling a selection off gives the whole month back', () async {
      final cubit = await filterable();

      cubit.toggleShift(ShiftType.notte);
      cubit.toggleWeekday(DateTime.monday);
      cubit.toggleShift(ShiftType.notte);
      cubit.toggleWeekday(DateTime.monday);

      expect(cubit.state.shiftFilter, isEmpty);
      expect(cubit.state.weekdayFilter, isEmpty);
      expect(cubit.state.muted(cellOn(cubit, 4)), isFalse);
    });

    test('clearing empties both groups at once', () async {
      // Azzera. Thirteen toggles are their own undo, but only if you
      // remember which thirteen you touched.
      final cubit = await filterable();

      cubit.toggleShift(ShiftType.notte);
      cubit.toggleShift(ShiftType.primo);
      cubit.toggleWeekday(DateTime.monday);
      cubit.clearFilter();

      expect(cubit.state.shiftFilter, isEmpty);
      expect(cubit.state.weekdayFilter, isEmpty);
      expect(cubit.state.muted(cellOn(cubit, 4)), isFalse);
    });

    test('the Filter survives a load and a refresh', () async {
      // Coming back from the Month Editor loads; resume and pull-to-refresh
      // refresh. None of the three is a reason to forget what you selected.
      final cubit = await filterable();
      cubit.toggleShift(ShiftType.notte);
      cubit.toggleWeekday(DateTime.monday);

      await cubit.load();
      await cubit.refresh();

      expect(cubit.state.shiftFilter, {ShiftType.notte});
      expect(cubit.state.weekdayFilter, {DateTime.monday});
      expect(cubit.state.muted(cellOn(cubit, 3)), isTrue);
    });
  });

  group('sync triggers', () {
    /// A cubit whose "now" the test moves, standing in for time passing while
    /// the app sat in the background.
    (CalendarCubit, FakeShiftsRepository, void Function(DateTime)) movable(
      DateTime now, {
      Map<String, ShiftType> shifts = const {},
    }) {
      var current = now;
      final repository = FakeShiftsRepository(shifts);
      final cubit = CalendarCubit(repository, clock: () => current);
      return (cubit, repository, (next) => current = next);
    }

    test('a refresh syncs, and only then queries', () async {
      final (cubit, repository, _) = movable(DateTime(2026, 2, 15));
      await cubit.load();
      repository.calls.clear();

      await cubit.refresh();

      expect(repository.calls, ['sync', 'fetchRange']);
    });

    test('"today" is recomputed on refresh', () async {
      final (cubit, _, setNow) = movable(DateTime(2026, 2, 15, 23, 45));
      await cubit.load();
      expect(
        cubit.state.grids!.first.singleWhere((cell) => cell.isToday).date,
        DateTime(2026, 2, 15),
      );

      // Backgrounded overnight: the highlight must have moved by morning.
      setNow(DateTime(2026, 2, 16, 8, 10));
      await cubit.refresh();

      expect(
        cubit.state.grids!.first.singleWhere((cell) => cell.isToday).date,
        DateTime(2026, 2, 16),
      );
    });

    test('the Data Window rolls forward on refresh', () async {
      final (cubit, repository, setNow) = movable(DateTime(2026, 2, 15));
      await cubit.load();
      expect(cubit.state.months, [DateTime(2026, 2), DateTime(2026, 3)]);

      setNow(DateTime(2026, 3, 1));
      await cubit.refresh();

      expect(cubit.state.months, [DateTime(2026, 3), DateTime(2026, 4)]);
      expect(
        cubit.state.grids!.last.any((cell) => cell.date.month == 4),
        isTrue,
      );
      // The re-query covers the new window, not the old one.
      expect(repository.ranges.last.$1, cubit.state.grids!.first.first.date);
      expect(repository.ranges.last.$2, cubit.state.grids!.last.last.date);
    });

    test('a write is not followed by a sync', () async {
      // Writes go to the primary and read-your-writes shows them at once, so
      // a post-write sync would push nothing and pull nothing.
      final (cubit, repository, _) = movable(DateTime(2026, 2, 15));
      await cubit.load();
      repository.calls.clear();

      await repository.upsertAll({'2026-02-16': ShiftType.notte});
      await cubit.load();

      expect(repository.calls, ['upsertAll', 'fetchRange']);
    });

    test('opening the Calendar does not sync', () async {
      final (cubit, repository, _) = movable(DateTime(2026, 2, 15));
      await cubit.load();
      cubit.showPage(1);

      expect(repository.calls, ['fetchRange']);
    });

    test('a refresh reports success', () async {
      final (cubit, _, _) = movable(DateTime(2026, 2, 15));

      expect(await cubit.refresh(), isTrue);
    });

    test('a failed sync reports failure and never throws', () async {
      final (cubit, repository, _) = movable(DateTime(2026, 2, 15));
      await cubit.load();
      repository.failing.add('sync');

      expect(await cubit.refresh(), isFalse);
      expect(repository.calls.last, 'sync', reason: 'no query after a failure');
    });

    test('a failed sync leaves loaded data untouched', () async {
      final (cubit, repository, _) = movable(
        DateTime(2026, 2, 15),
        shifts: {'2026-02-10': ShiftType.notte},
      );
      await cubit.load();
      final before = cubit.state;
      repository.failing.add('sync');

      await cubit.refresh();

      // Same state object: a failure emits nothing at all, so nothing on
      // screen can be cleared, emptied or half-rebuilt.
      expect(identical(cubit.state, before), isTrue);
      expect(
        cubit.state.grids!.first
            .firstWhere((cell) => cell.date == DateTime(2026, 2, 10))
            .shift,
        ShiftType.notte,
      );
    });

    test('a failed query leaves loaded data untouched', () async {
      final (cubit, repository, _) = movable(
        DateTime(2026, 2, 15),
        shifts: {'2026-02-10': ShiftType.notte},
      );
      await cubit.load();
      final before = cubit.state;
      repository.failing.add('fetchRange');

      expect(await cubit.refresh(), isFalse);
      expect(identical(cubit.state, before), isTrue);
    });

    test('a first load that fails says so instead of spinning', () async {
      // A brand-new replica has no schema, so the very first query throws.
      // Nothing is on screen to protect, so the failure is state, not silence.
      final (cubit, repository, _) = movable(DateTime(2026, 2, 15));
      repository.failing.add('fetchRange');

      expect(await cubit.load(), isFalse, reason: 'it does not throw');
      expect(cubit.state.grids, isNull);
      expect(cubit.state.loadFailed, isTrue);
    });

    test('a retry after a failed first load clears the failure', () async {
      final (cubit, repository, _) = movable(DateTime(2026, 2, 15));
      repository.failing.add('fetchRange');
      await cubit.load();

      repository.failing.clear();

      expect(await cubit.refresh(), isTrue);
      expect(cubit.state.grids, isNotNull);
      expect(cubit.state.loadFailed, isFalse);
    });

    test('a refresh succeeds again once connectivity returns', () async {
      final (cubit, repository, _) = movable(DateTime(2026, 2, 15));
      await cubit.load();
      repository.failing.add('sync');
      await cubit.refresh();

      repository.failing.clear();

      expect(await cubit.refresh(), isTrue);
      expect(cubit.state.grids, isNotNull);
    });
  });
}

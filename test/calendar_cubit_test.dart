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

  test('a month starting on a Sunday is padded with six leading days', () async {
    // February 2026 starts on a Sunday: six filler days before the 1st.
    final cells = await gridFor(DateTime(2026, 2, 15));

    expect(cells.length, 35);
    expect(cells.first.date, DateTime(2026, 1, 26));
    expect(cells.take(6).every((cell) => cell.isFiller), isTrue);
    expect(cells[6].date, DateTime(2026, 2, 1));
  });

  test('a 28-day February on a Monday is exactly four rows, no filler', () async {
    // February 2027: 28 days starting Monday, the only shape with no filler.
    final cells = await gridFor(DateTime(2027, 2, 15));

    expect(cells.length, 28);
    expect(cells.any((cell) => cell.isFiller), isFalse);
    expect(cells.last.date, DateTime(2027, 2, 28));
  });

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

  test('cells carry the Shift recorded for their day, filler included', () async {
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
  });

  test('loads with one query spanning the grids of both pages', () async {
    final repository = FakeShiftsRepository();
    final cubit = await loadedFor(DateTime(2026, 2, 15), repository: repository);

    final grids = cubit.state.grids!;
    expect(repository.ranges, [
      (grids.first.first.date, grids.last.last.date),
    ]);
  });

  test('exactly one cell is today, and it is the injected day', () async {
    // A time of day, not midnight: "now" is an instant, today is a day.
    final cells = await gridFor(DateTime(2026, 2, 15, 23, 45));

    expect(
      cells.where((cell) => cell.isToday).map((cell) => cell.date),
      [DateTime(2026, 2, 15)],
    );
  });

  test('the current week is a band of seven cells containing today', () async {
    final cells = await gridFor(DateTime(2026, 2, 15));

    final band = cells.where((cell) => cell.isCurrentWeek).toList();
    expect(band.length, 7);
    expect(band.first.date, DateTime(2026, 2, 9)); // Monday
    expect(band.last.date, DateTime(2026, 2, 15)); // Sunday
    expect(band.singleWhere((cell) => cell.isToday).date, DateTime(2026, 2, 15));
  });

  test('the band is contiguous — one row, never a scatter', () async {
    final cells = await gridFor(DateTime(2026, 2, 15));

    final first = cells.indexWhere((cell) => cell.isCurrentWeek);
    expect(first % 7, 0, reason: 'a band starts on a Monday column');
    expect(
      cells.sublist(first, first + 7).every((cell) => cell.isCurrentWeek),
      isTrue,
    );
  });

  test('on the first of a month the band covers previous-month filler', () async {
    // 1 February 2026 is a Sunday: the band is six leading filler days
    // from January plus the 1st itself.
    final cells = await gridFor(DateTime(2026, 2, 1));

    final band = cells.where((cell) => cell.isCurrentWeek).toList();
    expect(band.first.date, DateTime(2026, 1, 26));
    expect(band.last.date, DateTime(2026, 2, 1));
    expect(band.where((cell) => cell.isFiller).length, 6);
    expect(cells.first.isCurrentWeek, isTrue);
  });

  test('on the last day of a month the band covers next-month filler', () async {
    // 30 June 2026 is a Tuesday: the band runs into five days of July.
    final cells = await gridFor(DateTime(2026, 6, 30));

    final band = cells.where((cell) => cell.isCurrentWeek).toList();
    expect(band.first.date, DateTime(2026, 6, 29));
    expect(band.last.date, DateTime(2026, 7, 5));
    expect(band.where((cell) => cell.isFiller).length, 5);
    expect(cells.last.isCurrentWeek, isTrue);
  });

  test('highlighting ignores whether the day has a Shift', () async {
    final cells = await gridFor(
      DateTime(2026, 2, 15),
      shifts: {'2026-02-09': ShiftType.notte}, // Monday of the current week
    );

    DayCell cellOn(DateTime date) =>
        cells.firstWhere((cell) => cell.date == date);

    // Today is Empty and still today; a banded day is banded either way.
    expect(cellOn(DateTime(2026, 2, 15)).shift, isNull);
    expect(cellOn(DateTime(2026, 2, 15)).isToday, isTrue);
    expect(cellOn(DateTime(2026, 2, 9)).isCurrentWeek, isTrue);
    expect(cellOn(DateTime(2026, 2, 10)).shift, isNull);
    expect(cellOn(DateTime(2026, 2, 10)).isCurrentWeek, isTrue);
  });

  test('the Data Window is this month and the next, and nothing else', () async {
    final cubit = await loadedFor(DateTime(2026, 2, 15));

    expect(cubit.state.months, [DateTime(2026, 2), DateTime(2026, 3)]);
    expect(cubit.state.grids!.length, 2, reason: 'there is no third page');
  });

  test('a December "now" puts the next month in the following year', () async {
    final cubit = await loadedFor(DateTime(2026, 12, 15));

    expect(cubit.state.months, [DateTime(2026, 12), DateTime(2027, 1)]);
    expect(cubit.state.grids!.last.any((cell) => cell.date.year == 2027), isTrue);
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
    final cubit = await loadedFor(DateTime(2026, 2, 15), repository: repository);

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

  test('a week straddling the two pages is banded on both', () async {
    // 31 August 2026 is a Monday, so today's week runs 31 August to 6
    // September — the last row of page one and the first row of page two.
    final cubit = await loadedFor(DateTime(2026, 8, 31));

    for (final grid in cubit.state.grids!) {
      final band = grid.where((cell) => cell.isCurrentWeek).toList();
      expect(band.length, 7);
      expect(band.first.date, DateTime(2026, 8, 31));
      expect(band.last.date, DateTime(2026, 9, 6));
      expect(band.first.isToday, isTrue);
    }

    // Today appears on both pages, as a real day on one and filler on the
    // other, and is highlighted either way.
    final onNextPage = cubit.state.grids!.last.first;
    expect(onNextPage.date, DateTime(2026, 8, 31));
    expect(onNextPage.isFiller, isTrue);
    expect(onNextPage.isToday, isTrue);
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
      final band =
          cubit.state.grids!.first.where((cell) => cell.isCurrentWeek).toList();
      expect(band.first.date, DateTime(2026, 2, 16), reason: 'a new week');
    });

    test('the Data Window rolls forward on refresh', () async {
      final (cubit, repository, setNow) = movable(DateTime(2026, 2, 15));
      await cubit.load();
      expect(cubit.state.months, [DateTime(2026, 2), DateTime(2026, 3)]);

      setNow(DateTime(2026, 3, 1));
      await cubit.refresh();

      expect(cubit.state.months, [DateTime(2026, 3), DateTime(2026, 4)]);
      expect(cubit.state.grids!.last.any((cell) => cell.date.month == 4), isTrue);
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
  });
}

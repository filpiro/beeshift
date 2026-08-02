import 'package:beeshift/calendar_cubit.dart';
import 'package:beeshift/shift_type.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_shifts_repository.dart';

/// The primary seam: the grid lives in the Calendar's state, so every shape
/// assertion here runs without building a widget. "Now" is injected, never
/// read from the system clock.
void main() {
  Future<List<DayCell>> gridFor(
    DateTime now, {
    Map<String, ShiftType> shifts = const {},
    FakeShiftsRepository? repository,
  }) async {
    final cubit = CalendarCubit(
      repository ?? FakeShiftsRepository(shifts),
      now: now,
    );
    await cubit.load();
    return cubit.state!;
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

  test('loads with one query spanning the whole visible grid', () async {
    final repository = FakeShiftsRepository();
    final cells = await gridFor(DateTime(2026, 2, 15), repository: repository);

    expect(repository.ranges, [(cells.first.date, cells.last.date)]);
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
}

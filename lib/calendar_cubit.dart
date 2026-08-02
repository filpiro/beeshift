import 'package:flutter_bloc/flutter_bloc.dart';

import 'shift_type.dart';
import 'shifts_repository.dart';

/// One day in the grid. Filler days belong to an adjacent month and are drawn
/// dimmed; they carry real data like any other day, because Shifts are never
/// purged and the load query spans the whole grid.
class DayCell {
  const DayCell({
    required this.date,
    required this.shift,
    required this.isFiller,
  });

  final DateTime date;

  /// Null on an Empty day — nothing recorded yet.
  final ShiftType? shift;

  final bool isFiller;
}

/// Holds the Calendar's computed grid. Read-only: it never writes.
///
/// `null` state means the first load has not finished.
class CalendarCubit extends Cubit<List<DayCell>?> {
  CalendarCubit(this._repository, {required DateTime now})
    : month = DateTime(now.year, now.month),
      super(null);

  final ShiftsRepository _repository;

  /// The month this Calendar page shows, at its first day.
  final DateTime month;

  /// Every date the grid shows, Monday-first and always whole weeks, so the
  /// leading and trailing edges spill into the adjacent months.
  late final List<DateTime> _dates = _gridDates();

  List<DateTime> _gridDates() {
    final leading = month.weekday - 1;
    // Day zero of the next month is the last day of this one.
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final cellCount = ((leading + daysInMonth) / 7).ceil() * 7;
    return [
      // Out-of-range days normalise into the adjacent month, which keeps this
      // free of Duration arithmetic and therefore of daylight-saving drift.
      for (var i = 0; i < cellCount; i++)
        DateTime(month.year, month.month, i + 1 - leading),
    ];
  }

  /// One query for the entire visible grid, not the month bounds — that is
  /// what makes the filler days' Shifts available without a second fetch.
  Future<void> load() async {
    final shifts = await _repository.fetchRange(_dates.first, _dates.last);
    emit([
      for (final date in _dates)
        DayCell(
          date: date,
          shift: shifts[isoDate(date)],
          isFiller: date.month != month.month,
        ),
    ]);
  }
}

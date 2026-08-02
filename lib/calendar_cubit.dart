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
    required this.isToday,
    required this.isCurrentWeek,
  });

  final DateTime date;

  /// Null on an Empty day — nothing recorded yet.
  final ShiftType? shift;

  final bool isFiller;

  /// Both highlights are independent of [shift] and of [isFiller]: a filler
  /// day in the current week is banded like any other.
  final bool isToday;

  final bool isCurrentWeek;
}

/// What the Calendar shows: the Data Window's two months, a computed grid per
/// month once loaded, and which of the two pages is on screen.
class CalendarState {
  const CalendarState({
    required this.months,
    required this.grids,
    required this.visibleIndex,
  });

  /// The Data Window: this month and the next, each at its first day. Exactly
  /// two — a *viewing* rule only, so Shifts outside it are retained, just not
  /// reachable.
  final List<DateTime> months;

  /// One grid per entry in [months]. Null means the first load has not
  /// finished; both pages arrive together, from a single query.
  final List<List<DayCell>>? grids;

  final int visibleIndex;

  /// The month the user is currently looking at. The Month Editor targets it,
  /// which is why it lives here rather than in the widget's PageController.
  DateTime get visibleMonth => months[visibleIndex];

  CalendarState copyWith({List<List<DayCell>>? grids, int? visibleIndex}) =>
      CalendarState(
        months: months,
        grids: grids ?? this.grids,
        visibleIndex: visibleIndex ?? this.visibleIndex,
      );
}

/// The Data Window for an instant: this month and the next.
List<DateTime> _dataWindow(DateTime now) => [
  DateTime(now.year, now.month),
  // Month 13 normalises into January of the next year.
  DateTime(now.year, now.month + 1),
];

/// Holds the Calendar's computed grids. Read-only: it never writes.
class CalendarCubit extends Cubit<CalendarState> {
  CalendarCubit(this._repository, {required DateTime Function() clock})
    : _clock = clock,
      super(
        CalendarState(
          months: _dataWindow(clock()),
          grids: null,
          visibleIndex: 0,
        ),
      );

  final ShiftsRepository _repository;

  /// Read afresh on every [load], so resuming after midnight — or after a
  /// month has ended — moves "today" and rolls the Data Window forward.
  /// Device-local: single user, single timezone, no UTC modelling.
  final DateTime Function() _clock;

  List<DateTime> _gridDates(DateTime month) {
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

  /// One query for both pages' entire grids, not the month bounds — that is
  /// what makes the filler days' Shifts available, and what makes swiping to
  /// the second page cost nothing.
  ///
  /// No sync: a load is a read, and reads come from the local replica.
  Future<void> load() async {
    final now = _clock();
    final today = DateTime(now.year, now.month, now.day);
    // The Monday of today's week, and the Monday after it. Half-open, so the
    // band is a plain range test rather than grid-index arithmetic — which is
    // what keeps it correct when the band spills into an adjacent month.
    final weekStart = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday - 1),
    );
    final weekEnd = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day + 7,
    );
    final months = _dataWindow(now);
    // Every date a month's grid shows, Monday-first and always whole weeks, so
    // the leading and trailing edges spill into the adjacent months.
    final dates = [for (final month in months) _gridDates(month)];

    final shifts = await _repository.fetchRange(
      dates.first.first,
      dates.last.last,
    );
    emit(
      CalendarState(
        months: months,
        grids: [
          for (var page = 0; page < months.length; page++)
            [
              for (final date in dates[page])
                DayCell(
                  date: date,
                  shift: shifts[isoDate(date)],
                  isFiller: date.month != months[page].month,
                  isToday: date == today,
                  isCurrentWeek:
                      !date.isBefore(weekStart) && date.isBefore(weekEnd),
                ),
            ],
        ],
        visibleIndex: state.visibleIndex,
      ),
    );
  }

  /// The only sync trigger there is: resume and pull-to-refresh both land
  /// here. Sync first, then load — a load that ran first would query rows the
  /// sync was about to bring in.
  Future<void> refresh() async {
    await _repository.sync();
    await load();
  }

  /// Records which page the carousel settled on. Emits only — the data for
  /// both pages already arrived with [load].
  void showPage(int index) => emit(state.copyWith(visibleIndex: index));
}

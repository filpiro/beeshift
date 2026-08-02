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

/// Holds the Calendar's computed grids. Read-only: it never writes.
class CalendarCubit extends Cubit<CalendarState> {
  CalendarCubit(this._repository, {required DateTime now})
    : _today = DateTime(now.year, now.month, now.day),
      super(
        CalendarState(
          months: [
            DateTime(now.year, now.month),
            // Month 13 normalises into January of the next year.
            DateTime(now.year, now.month + 1),
          ],
          grids: null,
          visibleIndex: 0,
        ),
      );

  final ShiftsRepository _repository;

  /// Device-local, established once per load — single user, single timezone,
  /// no UTC modelling. Recomputing it on resume is 06's job.
  final DateTime _today;

  /// The Monday of today's week, and the Monday after it. Half-open, so the
  /// band is a plain range test rather than grid-index arithmetic — which is
  /// what keeps it correct when the band spills into an adjacent month.
  late final DateTime _weekStart = DateTime(
    _today.year,
    _today.month,
    _today.day - (_today.weekday - 1),
  );
  late final DateTime _weekEnd = DateTime(
    _weekStart.year,
    _weekStart.month,
    _weekStart.day + 7,
  );

  /// Every date a month's grid shows, Monday-first and always whole weeks, so
  /// the leading and trailing edges spill into the adjacent months.
  late final List<List<DateTime>> _dates = [
    for (final month in state.months) _gridDates(month),
  ];

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
  Future<void> load() async {
    final shifts = await _repository.fetchRange(
      _dates.first.first,
      _dates.last.last,
    );
    emit(
      state.copyWith(
        grids: [
          for (var page = 0; page < state.months.length; page++)
            [
              for (final date in _dates[page])
                DayCell(
                  date: date,
                  shift: shifts[isoDate(date)],
                  isFiller: date.month != state.months[page].month,
                  isToday: date == _today,
                  isCurrentWeek:
                      !date.isBefore(_weekStart) && date.isBefore(_weekEnd),
                ),
            ],
        ],
      ),
    );
  }

  /// Records which page the carousel settled on. Emits only — the data for
  /// both pages already arrived with [load].
  void showPage(int index) => emit(state.copyWith(visibleIndex: index));
}

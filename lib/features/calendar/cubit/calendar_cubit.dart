import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/shifts_repository.dart';
import '../../../shared/shift_type.dart';

/// One day in the grid. Filler days belong to an adjacent month and are drawn
/// dimmed; they carry real data like any other day, because Shifts are never
/// purged and the load query spans the whole grid.
class DayCell {
  const DayCell({
    required this.date,
    required this.shift,
    required this.isFiller,
    required this.isToday,
  });

  final DateTime date;

  /// Null on an Empty day — nothing recorded yet.
  final ShiftType? shift;

  final bool isFiller;

  /// The Calendar's only highlight, and independent of [shift] — an Empty day
  /// is today like any other. It is set on both pages when today is the last
  /// day of a month, since the next month's grid opens with it as filler;
  /// which of the two actually draws the highlight is the widget's call.
  final bool isToday;
}

/// What the Calendar shows: the Data Window's two months, a computed grid per
/// month once loaded, and which of the two pages is on screen.
class CalendarState {
  const CalendarState({
    required this.months,
    required this.grids,
    required this.visibleIndex,
    this.loadFailed = false,
    this.shiftFilter = const {},
    this.weekdayFilter = const {},
  });

  /// The Data Window: this month and the next, each at its first day. Exactly
  /// two — a *viewing* rule only, so Shifts outside it are retained, just not
  /// reachable.
  final List<DateTime> months;

  /// One grid per entry in [months]. Null means the first load has not
  /// finished; both pages arrive together, from a single query.
  final List<List<DayCell>>? grids;

  final int visibleIndex;

  /// Set only when there was nothing on screen to protect: a first load that
  /// failed. A later failure leaves whatever is drawn exactly as it is and
  /// says so through [CalendarCubit.refresh]'s return instead.
  final bool loadFailed;

  /// The Filter's two groups. Empty is the default and means "everything" —
  /// a group with nothing selected is not a filter at all. Held here rather
  /// than baked into [DayCell] because it changes on every tap, where
  /// [DayCell.isFiller] and [DayCell.isToday] are settled once per load.
  ///
  /// Never persisted: it lives as long as the process and no longer.
  final Set<ShiftType> shiftFilter;

  /// [DateTime.monday] to [DateTime.sunday].
  final Set<int> weekdayFilter;

  /// Whether a day fails the Filter and is therefore drawn dimmed. OR within
  /// a group, AND across the two.
  ///
  /// A filler day is answered on the same terms as any other, and its answer
  /// makes no visible difference: the widget dims it either way, and never
  /// twice — 0.35 is a floor, not a multiplier.
  bool muted(DayCell cell) {
    // A group with nothing selected is not a filter, so neither group being
    // selected is not a filter at all.
    if (shiftFilter.isEmpty && weekdayFilter.isEmpty) return false;
    // An Empty day cannot answer a question about Shift Types, and does not
    // become an answer just because the question was only about weekdays.
    if (cell.shift == null) return true;
    final wrongShift =
        shiftFilter.isNotEmpty && !shiftFilter.contains(cell.shift);
    final wrongDay =
        weekdayFilter.isNotEmpty && !weekdayFilter.contains(cell.date.weekday);
    return wrongShift || wrongDay;
  }

  /// The month the user is currently looking at. The Month Editor targets it,
  /// which is why it lives here rather than in the widget's PageController.
  DateTime get visibleMonth => months[visibleIndex];

  /// What the Month Editor opens pre-loaded with: the Shifts recorded for the
  /// visible month, and only that month — the page's filler days belong to a
  /// neighbour and are not the editor's to write. Read from the grid already
  /// loaded, so opening the editor costs no query.
  Map<String, ShiftType> get visibleMonthShifts => {
    for (final cell in grids![visibleIndex])
      if (!cell.isFiller && cell.shift != null) isoDate(cell.date): cell.shift!,
  };

  CalendarState copyWith({
    List<List<DayCell>>? grids,
    int? visibleIndex,
    bool? loadFailed,
    Set<ShiftType>? shiftFilter,
    Set<int>? weekdayFilter,
  }) => CalendarState(
    months: months,
    grids: grids ?? this.grids,
    visibleIndex: visibleIndex ?? this.visibleIndex,
    loadFailed: loadFailed ?? this.loadFailed,
    shiftFilter: shiftFilter ?? this.shiftFilter,
    weekdayFilter: weekdayFilter ?? this.weekdayFilter,
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
  ///
  /// Never throws — it is called from a constructor's cascade, where a thrown
  /// error would go nowhere and leave the spinner spinning. Returns whether it
  /// worked instead.
  Future<bool> load() async {
    final now = _clock();
    final today = DateTime(now.year, now.month, now.day);
    final months = _dataWindow(now);
    // Every date a month's grid shows, Monday-first and always whole weeks, so
    // the leading and trailing edges spill into the adjacent months.
    final dates = [for (final month in months) _gridDates(month)];

    final Map<String, ShiftType> shifts;
    try {
      shifts = await _repository.fetchRange(dates.first.first, dates.last.last);
    } catch (_) {
      // Nothing drawn yet — a brand-new replica has no schema at all, and a
      // silent failure here is a spinner that never stops. With a Calendar
      // already on screen the rule from ticket 08 stands: emit nothing, keep
      // what the user is reading, and let the caller report it.
      if (state.grids == null) emit(state.copyWith(loadFailed: true));
      return false;
    }
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
                ),
            ],
        ],
        visibleIndex: state.visibleIndex,
        // A load is a re-read of the same two months, not a new screen: what
        // the user selected outlives it, the Month Editor round trip included.
        shiftFilter: state.shiftFilter,
        weekdayFilter: state.weekdayFilter,
      ),
    );
    return true;
  }

  /// The only sync trigger there is: resume and pull-to-refresh both land
  /// here. Sync first, then load — a load that ran first would query rows the
  /// sync was about to bring in.
  ///
  /// Returns whether it worked, and never throws: the two callers want
  /// different things from a failure — one line of text for a pull, silence
  /// for a resume — and neither wants an exception. A failure emits nothing at
  /// all, so whatever the Calendar already shows stays exactly as it is.
  Future<bool> refresh() async {
    try {
      await _repository.sync();
    } catch (_) {
      return false;
    }
    return load();
  }

  /// The Filter's two toggles. Emit only: the grids are untouched, since what
  /// changes is how each day is drawn, not which days there are.
  void toggleShift(ShiftType type) =>
      emit(state.copyWith(shiftFilter: _toggled(state.shiftFilter, type)));

  void toggleWeekday(int weekday) => emit(
    state.copyWith(weekdayFilter: _toggled(state.weekdayFilter, weekday)),
  );

  static Set<T> _toggled<T>(Set<T> selection, T value) =>
      selection.contains(value)
      ? ({...selection}..remove(value))
      : {...selection, value};

  /// Records which page the carousel settled on. Emits only — the data for
  /// both pages already arrived with [load].
  void showPage(int index) => emit(state.copyWith(visibleIndex: index));
}

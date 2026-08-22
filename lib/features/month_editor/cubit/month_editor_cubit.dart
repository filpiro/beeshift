import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/shifts_repository.dart';
import '../../../shared/shift_type.dart';

/// The Month Editor's state: what is chosen, and whether the last attempt to
/// commit it failed.
class MonthEditorState {
  const MonthEditorState({required this.shifts, this.saveFailed = false});

  /// The Shift chosen for each day of the month, keyed by ISO date. A day
  /// absent from the map is Empty — not entered yet — and stays that way until
  /// a radio is tapped. Nothing is ever removed from it, because nothing is
  /// ever deleted: a mistake is corrected by choosing a different Shift Type.
  final Map<String, ShiftType> shifts;

  /// Sticky: set by a failed [MonthEditorCubit.save] and cleared only by one
  /// that succeeds. A failed write is the one thing here that must be
  /// impossible to miss, so it does not time out and cannot be dismissed —
  /// missing it means believing a month was recorded when it was not.
  final bool saveFailed;
}

/// Holds the month being edited. The only thing in the app that writes.
class MonthEditorCubit extends Cubit<MonthEditorState> {
  /// [shifts] is what the Calendar already holds for [month], so the editor
  /// opens pre-loaded — which is what makes it safe to leave half-finished,
  /// and what makes it a bulk-correction tool rather than first-entry-only.
  MonthEditorCubit(
    this._repository, {
    required this.month,
    required Map<String, ShiftType> shifts,
  }) : super(MonthEditorState(shifts: Map.unmodifiable(shifts)));

  final ShiftsRepository _repository;

  /// The month being edited, at its first day.
  final DateTime month;

  /// Every day of [month], in order. Day zero of the next month is the last
  /// day of this one.
  late final List<DateTime> days = [
    for (
      var day = 1;
      day <= DateTime(month.year, month.month + 1, 0).day;
      day++
    )
      DateTime(month.year, month.month, day),
  ];

  /// Local only — no per-day save and nothing on the network until [save].
  /// Editing after a failure does not clear the banner: nothing has been
  /// written, so the warning is still true.
  void select(DateTime date, ShiftType shift) => emit(
    MonthEditorState(
      shifts: Map.unmodifiable({...state.shifts, isoDate(date): shift}),
      saveFailed: state.saveFailed,
    ),
  );

  /// One batch upsert for the whole month. Days that were empty and stayed
  /// unselected are absent from the state, so they are not written at all.
  ///
  /// No sync afterwards: the write went to the primary and read-your-writes
  /// means the Calendar's re-query already sees it.
  ///
  /// Returns whether it worked. A failure leaves every selection exactly as it
  /// was — writes reach the primary synchronously, so this is what being
  /// offline looks like, and the retry is simply pressing Save again.
  Future<bool> save() async {
    try {
      await _repository.upsertAll(state.shifts);
      if (state.saveFailed) emit(MonthEditorState(shifts: state.shifts));
      return true;
    } catch (_) {
      emit(MonthEditorState(shifts: state.shifts, saveFailed: true));
      return false;
    }
  }
}

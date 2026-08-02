import 'package:flutter_bloc/flutter_bloc.dart';

import 'shift_type.dart';
import 'shifts_repository.dart';

/// The Month Editor's state: the Shift chosen for each day of the month, keyed
/// by ISO date. A day absent from the map is Empty — not entered yet — and
/// stays that way until a radio is tapped. Nothing is ever removed from it,
/// because nothing is ever deleted: a mistake is corrected by choosing a
/// different Shift Type.
class MonthEditorCubit extends Cubit<Map<String, ShiftType>> {
  /// [shifts] is what the Calendar already holds for [month], so the editor
  /// opens pre-loaded — which is what makes it safe to leave half-finished,
  /// and what makes it a bulk-correction tool rather than first-entry-only.
  MonthEditorCubit(
    this._repository, {
    required this.month,
    required Map<String, ShiftType> shifts,
  }) : super(Map.unmodifiable(shifts));

  final ShiftsRepository _repository;

  /// The month being edited, at its first day.
  final DateTime month;

  /// Every day of [month], in order. Day zero of the next month is the last
  /// day of this one.
  late final List<DateTime> days = [
    for (var day = 1; day <= DateTime(month.year, month.month + 1, 0).day; day++)
      DateTime(month.year, month.month, day),
  ];

  /// Local only — no per-day save and nothing on the network until [save].
  void select(DateTime date, ShiftType shift) =>
      emit(Map.unmodifiable({...state, isoDate(date): shift}));

  /// One batch upsert for the whole month. Days that were empty and stayed
  /// unselected are absent from the state, so they are not written at all.
  ///
  /// No sync afterwards: the write went to the primary and read-your-writes
  /// means the Calendar's re-query already sees it.
  Future<void> save() => _repository.upsertAll(state);
}

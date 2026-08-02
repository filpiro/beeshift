import 'package:beeshift/month_editor_cubit.dart';
import 'package:beeshift/shift_type.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_shifts_repository.dart';

/// The write path's seam: what the editor holds and what it sends is decided
/// here, so the batch payload can be asserted without touching a widget.
void main() {
  MonthEditorCubit editorFor(
    DateTime month, {
    Map<String, ShiftType> shifts = const {},
    FakeShiftsRepository? repository,
  }) => MonthEditorCubit(
    repository ?? FakeShiftsRepository(shifts),
    month: month,
    shifts: shifts,
  );

  test('lists every day of the month, and no day of another', () {
    final editor = editorFor(DateTime(2026, 2));

    expect(editor.days.length, 28);
    expect(editor.days.first, DateTime(2026, 2, 1));
    expect(editor.days.last, DateTime(2026, 2, 28));
    expect(editor.days.every((day) => day.month == DateTime.february), isTrue);
  });

  test('a 31-day month lists 31 days', () {
    expect(editorFor(DateTime(2026, 1)).days.length, 31);
  });

  test('opens pre-loaded with the Shifts already recorded', () {
    final editor = editorFor(
      DateTime(2026, 2),
      shifts: {'2026-02-03': ShiftType.notte, '2026-02-04': ShiftType.smonto},
    );

    expect(editor.state, {
      '2026-02-03': ShiftType.notte,
      '2026-02-04': ShiftType.smonto,
    });
  });

  test('selecting changes local state only — nothing reaches the repository', () {
    final repository = FakeShiftsRepository();
    final editor = editorFor(DateTime(2026, 2), repository: repository);

    editor.select(DateTime(2026, 2, 5), ShiftType.primo);
    editor.select(DateTime(2026, 2, 6), ShiftType.riposo);

    expect(editor.state, {
      '2026-02-05': ShiftType.primo,
      '2026-02-06': ShiftType.riposo,
    });
    expect(repository.calls, isEmpty);
  });

  test('selecting again replaces the day rather than adding to it', () {
    final editor = editorFor(DateTime(2026, 2));

    editor.select(DateTime(2026, 2, 5), ShiftType.primo);
    editor.select(DateTime(2026, 2, 5), ShiftType.ferie);

    expect(editor.state, {'2026-02-05': ShiftType.ferie});
  });

  test('save sends the whole month as exactly one batch upsert', () async {
    // A mixed month: one Shift kept as it arrived, one corrected, one newly
    // entered, and empty days left alone.
    final repository = FakeShiftsRepository({
      '2026-02-03': ShiftType.notte, // untouched, keeps what it had
      '2026-02-04': ShiftType.smonto, // corrected below
    });
    final editor = editorFor(
      DateTime(2026, 2),
      shifts: {'2026-02-03': ShiftType.notte, '2026-02-04': ShiftType.smonto},
      repository: repository,
    );

    editor.select(DateTime(2026, 2, 4), ShiftType.riposo);
    editor.select(DateTime(2026, 2, 10), ShiftType.primo);
    await editor.save();

    expect(repository.batches, [
      {
        '2026-02-03': ShiftType.notte,
        '2026-02-04': ShiftType.riposo,
        '2026-02-10': ShiftType.primo,
      },
    ], reason: 'untouched empty days are not written at all');
    expect(repository.calls, ['upsertAll'], reason: 'no sync, one write');
  });

  test('a save that selected nothing still writes only what was loaded', () async {
    final repository = FakeShiftsRepository({'2026-02-03': ShiftType.notte});
    final editor = editorFor(
      DateTime(2026, 2),
      shifts: {'2026-02-03': ShiftType.notte},
      repository: repository,
    );

    await editor.save();

    expect(repository.batches, [
      {'2026-02-03': ShiftType.notte},
    ]);
  });
}

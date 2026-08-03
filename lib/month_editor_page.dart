import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'italian_dates.dart';
import 'month_editor_cubit.dart';
import 'shift_type.dart';
import 'shifts_repository.dart';

/// Indexed by [DateTime.weekday], Monday first. Ticket 11 replaces these with
/// the full names from [weekdayNames] and deletes this list.
const _weekdayAbbreviations = [
  '',
  'Lun',
  'Mar',
  'Mer',
  'Gio',
  'Ven',
  'Sab',
  'Dom',
];

/// One month, every day of it, six Shift Types each. One Save commits the lot.
class MonthEditorPage extends StatelessWidget {
  const MonthEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final editor = context.read<MonthEditorCubit>();
    final month = editor.month;
    return Scaffold(
      appBar: AppBar(
        // Which month is being edited, spelled out: the Calendar's button
        // targets whatever was on screen, so the editor says which that was.
        title: Text(monthTitle(month)),
        actions: [
          // Never disabled, so a failed save is retried by pressing the same
          // button again — there is nothing else to undo or dismiss first.
          TextButton(
            onPressed: () async {
              if (!await editor.save()) return; // Stay put, banner shows why.
              // The Calendar re-queries on the way back — see CalendarPage.
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Salva'),
          ),
        ],
      ),
      body: BlocBuilder<MonthEditorCubit, MonthEditorState>(
        builder: (context, state) => Column(
          children: [
            // Inline and sticky rather than a toast: this is the one message
            // in the app that must not be able to scroll or time out away.
            if (state.saveFailed)
              MaterialBanner(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                content: const Text(
                  'Salvataggio non riuscito. Le modifiche sono ancora qui: '
                  'riprova.',
                ),
                // No dismiss action: the only way out is a save that works.
                actions: const [SizedBox.shrink()],
              ),
            Expanded(
              child: ListView.builder(
                itemCount: editor.days.length,
                itemBuilder: (context, index) {
                  final day = editor.days[index];
                  return _DayRow(
                    day: day,
                    selected: state.shifts[isoDate(day)],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A day and its six choices. No way to clear one: an Empty day means "not
/// entered yet", and a mistake is corrected by picking a different Shift Type.
class _DayRow extends StatelessWidget {
  const _DayRow({required this.day, required this.selected});

  final DateTime day;
  final ShiftType? selected;

  @override
  Widget build(BuildContext context) {
    final editor = context.read<MonthEditorCubit>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${day.day} ${_weekdayAbbreviations[day.weekday]}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          // Names, not codes: nobody should have to remember what S means.
          // They wrap rather than scroll, so every choice is reachable.
          RadioGroup<ShiftType>(
            groupValue: selected,
            // Non-null: there is no radio that clears a day, so the only way
            // out of a wrong choice is a different Shift Type.
            onChanged: (shift) => editor.select(day, shift!),
            child: Wrap(
              children: [
                for (final shift in ShiftType.values)
                  // The label is part of the tap target, not decoration next
                  // to it — a bare radio dot is a small thing to hit.
                  InkWell(
                    onTap: () => editor.select(day, shift),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Radio<ShiftType>(value: shift),
                        Text(shift.label),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

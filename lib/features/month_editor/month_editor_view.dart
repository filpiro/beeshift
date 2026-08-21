import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/shifts_repository.dart';
import '../../shared/italian_dates.dart';
import '../../shared/shift_type.dart';
import 'cubit/month_editor_cubit.dart';

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
      // No divider closing the row: once the rows breathe, a line between two
      // outlined controls is ink competing with the outlines.
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${day.day} ${weekdayNames[day.weekday]}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          // Codes, not names — six Italian names cannot share one row on a
          // phone, and the codes are what the user reads off the real rota.
          // The names stay as what a screen reader says.
          SegmentedButton<ShiftType>(
            // An Empty day means "not entered yet", so nothing selected has to
            // be drawable. Returning to it is blocked below, not here.
            emptySelectionAllowed: true,
            // The check would take the space the letter needs.
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              // Six segments at a sixth of a phone's width: the default
              // padding is wider than a single letter can pay for.
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: const Size(0, 48),
            ),
            segments: [
              for (final shift in ShiftType.values)
                ButtonSegment(
                  value: shift,
                  label: Text(shift.code, semanticsLabel: shift.label),
                ),
            ],
            selected: {?selected},
            // Tapping the selected segment would otherwise empty the set, and
            // nothing may put a day back to "not entered yet". A wrong choice
            // is corrected by picking a different Shift Type.
            onSelectionChanged: (chosen) {
              if (chosen.isNotEmpty) editor.select(day, chosen.single);
            },
          ),
        ],
      ),
    );
  }
}

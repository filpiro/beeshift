import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../data/shifts_repository.dart';
import '../../shared/italian_dates.dart';
import '../../shared/shift_colors.dart';
import '../../shared/shift_type.dart';
import '../../shared/widgets/equal_row_segmented.dart';
import 'cubit/month_editor_cubit.dart';

/// One month, every day of it, six Shift Types each. One Save commits the lot.
class MonthEditorPage extends StatelessWidget {
  const MonthEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final editor = context.read<MonthEditorCubit>();
    final month = editor.month;
    return Scaffold(
      headers: [
        AppBar(
          // Which month is being edited, spelled out: the Calendar's button
          // targets whatever was on screen, so the editor says which that was.
          title: Text(monthTitle(month)),
          trailing: [
            // Never disabled, so a failed save is retried by pressing the same
            // button again — there is nothing else to undo or dismiss first.
            TextButton(
              onPressed: () async {
                if (!await editor.save()) return; // Stay put, alert says why.
                // The Calendar re-queries on the way back — see CalendarPage.
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Salva'),
            ),
          ],
        ),
        const Divider(),
      ],
      // The AppBar header already took the top inset, and the ListView below
      // would pad for it again from MediaQuery.
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: BlocBuilder<MonthEditorCubit, MonthEditorState>(
          builder: (context, state) => Column(
            children: [
              // Inline and sticky rather than a toast: this is the one message
              // in the app that must not be able to scroll or time out away.
              // No dismiss action: the only way out is a save that works.
              if (state.saveFailed)
                const Alert(
                  destructive: true,
                  content: Text(
                    'Salvataggio non riuscito. Le modifiche sono ancora qui: '
                    'riprova.',
                  ),
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
    final colors = ShiftColors.of(context);
    return Padding(
      // No divider closing the row: once the rows breathe, a line between two
      // outlined controls is ink competing with the outlines.
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${day.day} ${weekdayNames[day.weekday]}',
            style: Theme.of(context).typography.xLarge,
          ),
          const SizedBox(height: 8),
          // Codes, not names — six Italian names cannot share one row on a
          // phone, and the codes are what the user reads off the real rota.
          // The names stay as what a screen reader says.
          EqualRowSegmented<ShiftType>(
            segments: [
              for (final shift in ShiftType.values)
                RowSegment(
                  value: shift,
                  code: shift.code,
                  // Picked turns the Shift Colour, so the editor and the
                  // Calendar's tiles say the same thing in the same hue.
                  color: colors[shift]!,
                  label: shift.label,
                ),
            ],
            selected: selected,
            // Every tap, selected code included, sets the day to that Shift
            // Type — there is no toggle-off, so nothing may put a day back to
            // "not entered yet". A wrong choice is corrected by picking a
            // different one.
            onChanged: (shift) => editor.select(day, shift),
          ),
        ],
      ),
    );
  }
}

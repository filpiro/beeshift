import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'month_editor_cubit.dart';
import 'shift_type.dart';
import 'shifts_repository.dart';

/// Italian, indexed by [DateTime.month] — the app has one user, one language.
/// ponytail: a const list, not the intl package, for twelve strings.
const _monthNames = [
  '',
  'Gennaio',
  'Febbraio',
  'Marzo',
  'Aprile',
  'Maggio',
  'Giugno',
  'Luglio',
  'Agosto',
  'Settembre',
  'Ottobre',
  'Novembre',
  'Dicembre',
];

/// Indexed by [DateTime.weekday], Monday first.
const _weekdayNames = ['', 'Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];

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
        title: Text('${_monthNames[month.month]} ${month.year}'),
        actions: [
          TextButton(
            onPressed: () async {
              await editor.save();
              // The Calendar re-queries on the way back — see CalendarPage.
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Salva'),
          ),
        ],
      ),
      body: BlocBuilder<MonthEditorCubit, Map<String, ShiftType>>(
        builder: (context, selections) => ListView.builder(
          itemCount: editor.days.length,
          itemBuilder: (context, index) {
            final day = editor.days[index];
            return _DayRow(day: day, selected: selections[isoDate(day)]);
          },
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
            '${day.day} ${_weekdayNames[day.weekday]}',
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

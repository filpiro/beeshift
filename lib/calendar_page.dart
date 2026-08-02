import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'calendar_cubit.dart';

/// Monday first, matching how the Rotation is written.
const _weekdayInitials = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];

/// The month grid. Every decision it draws — which cells exist, which are
/// filler, what each one shows — was already made in [CalendarCubit].
class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarCubit, List<DayCell>?>(
      builder: (context, cells) {
        if (cells == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            Row(
              children: [
                for (final initial in _weekdayInitials)
                  Expanded(
                    child: Center(
                      child: Text(
                        initial,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ),
              ],
            ),
            // Rows flex to the available height, so the whole month is on
            // screen whatever its shape — no scrolling and nothing clipped.
            for (var row = 0; row < cells.length; row += 7)
              Expanded(
                child: Row(
                  children: [
                    for (final cell in cells.skip(row).take(7))
                      Expanded(child: _DayCellView(cell)),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// No gesture handling of any kind — the Month Editor is the only way in.
class _DayCellView extends StatelessWidget {
  const _DayCellView(this.cell);

  final DayCell cell;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: cell.isFiller ? 0.35 : 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${cell.date.day}', style: theme.textTheme.labelMedium),
          Text(cell.shift?.code ?? '', style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

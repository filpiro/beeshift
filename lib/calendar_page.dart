import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'calendar_cubit.dart';

/// Monday first, matching how the Rotation is written.
const _weekdayInitials = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];

/// The Calendar: the Data Window's two months as a carousel. Every decision it
/// draws — which cells exist, which are filler, what each one shows — was
/// already made in [CalendarCubit].
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Resume, not cold start: Android rarely kills this app, so a cold-start
  /// trigger would almost never fire — and the highlight would still be
  /// pointing at yesterday.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<CalendarCubit>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarCubit, CalendarState>(
      builder: (context, state) {
        final grids = state.grids;
        if (grids == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            // Outside the carousel: the weekday initials are the same on both
            // pages, so sliding them would be motion that says nothing.
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
            Expanded(
              child: RefreshIndicator(
                onRefresh: context.read<CalendarCubit>().refresh,
                // The pull comes from inside a page, so it reaches here one
                // viewport deeper than the default predicate accepts.
                notificationPredicate: (notification) =>
                    notification.depth == 1,
                // Exactly two children, so paging stops at both ends on its
                // own — there is no third page to clamp against.
                child: PageView(
                  onPageChanged: context.read<CalendarCubit>().showPage,
                  children: [for (final grid in grids) _MonthGrid(grid)],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// One month's grid, filling the height it is given.
class _MonthGrid extends StatelessWidget {
  const _MonthGrid(this.cells);

  final List<DayCell> cells;

  @override
  Widget build(BuildContext context) {
    // The grid never scrolls — it is sized to the viewport. The scroll view
    // exists only so the pull-down gesture has something to overscroll, which
    // is what RefreshIndicator listens to.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(height: constraints.maxHeight, child: _grid(context)),
      ),
    );
  }

  Widget _grid(BuildContext context) {
    return Column(
      children: [
        // Rows flex to the available height, so the whole month is on screen
        // whatever its shape — no scrolling and nothing clipped.
        for (var row = 0; row < cells.length; row += 7)
          Expanded(
            // The band is drawn once per row rather than per cell, so it
            // reads as one continuous stripe with no seams between days.
            // Reading the row's first cell is enough: a row is always one
            // whole Monday-first week, so the flag is uniform across it.
            child: ColoredBox(
              color: cells[row].isCurrentWeek
                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                  : Colors.transparent,
              child: Row(
                children: [
                  for (final cell in cells.skip(row).take(7))
                    Expanded(child: _DayCellView(cell)),
                ],
              ),
            ),
          ),
      ],
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
          // The disc is what makes today findable without reading a date.
          // Every cell carries the same padding, so only the colour moves.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: cell.isToday
                ? ShapeDecoration(
                    color: theme.colorScheme.primary,
                    shape: const StadiumBorder(),
                  )
                : null,
            child: Text(
              '${cell.date.day}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: cell.isToday ? theme.colorScheme.onPrimary : null,
              ),
            ),
          ),
          Text(cell.shift?.code ?? '', style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

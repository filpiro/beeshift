import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'calendar_cubit.dart';
import 'month_editor_cubit.dart';
import 'month_editor_page.dart';
import 'shifts_repository.dart';

/// Monday first, matching how the Rotation is written.
const _weekdayInitials = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];

/// The Calendar: the Data Window's two months as a carousel. Every decision it
/// draws — which cells exist, which are filler, what each one shows — was
/// already made in [CalendarCubit].
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.repository});

  /// Handed on to the Month Editor, which is the only thing here that writes.
  /// It arrives from the app's wiring rather than through [CalendarCubit],
  /// which is read-only and has no business lending out a write path.
  final ShiftsRepository repository;

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
  ///
  /// The result is deliberately dropped: a resume sync is something the user
  /// never asked for, so its failure gets no UI. Unlocking your phone in a bad
  /// signal spot must not produce a message.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<CalendarCubit>().refresh();
    }
  }

  /// A pull the user made, so a failure gets one transient line — and nothing
  /// else: the data already on screen is untouched and stays readable.
  Future<void> _pullToRefresh() async {
    if (await context.read<CalendarCubit>().refresh()) return;
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Aggiornamento non riuscito')));
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
                onRefresh: _pullToRefresh,
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
            // Below the carousel, so it is clear the button acts on the month
            // you swiped to rather than on some month it chose for you.
            Padding(
              padding: const EdgeInsets.all(8),
              child: FilledButton(
                onPressed: () => _openEditor(context),
                child: const Text('Modifica'),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Opens the Month Editor on whichever month is on screen, pre-loaded from
  /// the grid already in hand. On the way back the Calendar re-queries — a
  /// local read, no sync: read-your-writes means the row is already there.
  Future<void> _openEditor(BuildContext context) async {
    final calendar = context.read<CalendarCubit>();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
          create: (_) => MonthEditorCubit(
            widget.repository,
            month: calendar.state.visibleMonth,
            shifts: calendar.state.visibleMonthShifts,
          ),
          child: const MonthEditorPage(),
        ),
      ),
    );
    await calendar.load();
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

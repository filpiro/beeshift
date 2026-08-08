import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'calendar_cubit.dart';
import 'italian_dates.dart';
import 'month_editor_cubit.dart';
import 'month_editor_page.dart';
import 'shift_type.dart';
import 'shifts_repository.dart';

/// Height kept clear under the grid: a 56dp floating button, the Scaffold's
/// 16dp margin below it, and 8dp so the last row is not touching it.
const _fabReserve = 80.0;

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
        // Its own Scaffold, not the app's: that one also hosts the loading
        // spinner and the connect-error screen, and an edit button floating
        // over a database that would not open invites editing nothing.
        return Scaffold(
          floatingActionButton: grids == null
              ? null
              : FloatingActionButton(
                  onPressed: () => _openEditor(context),
                  // The icon alone is nameless to a screen reader.
                  tooltip: 'Modifica',
                  // A pencil, not a plus: the editor overwrites the month's
                  // days and never creates a Shift out of nothing.
                  child: const Icon(Icons.edit),
                ),
          body: SafeArea(
            child: switch (grids) {
              // A first load that failed: the spinner would otherwise spin for
              // as long as the app is open, saying nothing.
              null when state.loadFailed => _FirstLoadError(
                onRetry: context.read<CalendarCubit>().refresh,
              ),
              null => const Center(child: CircularProgressIndicator()),
              _ => _body(context, state, grids),
            },
          ),
        );
      },
    );
  }

  /// The loaded Calendar: the header, and the carousel under it.
  Widget _body(
    BuildContext context,
    CalendarState state,
    List<List<DayCell>> grids,
  ) {
    return Column(
      children: [
        // Outside the carousel, and so is the month name: the weekday
        // initials are the same on both pages, so a header that slid with
        // the grid would tear in half — half moving, half not. The name
        // swaps when the page settles instead.
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            monthTitle(state.visibleMonth),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        _ShiftFilterRow(selected: state.shiftFilter),
        Row(
          children: [
            for (var day = DateTime.monday; day <= DateTime.sunday; day++)
              Expanded(
                child: _WeekdayFilter(
                  weekday: day,
                  selected: state.weekdayFilter.contains(day),
                ),
              ),
          ],
        ),
        Expanded(
          child: Padding(
            // The floating button overlaps whatever is under it, and on a
            // short screen the grid reaches the bottom. Reserved here so
            // the last row stops above it rather than under it.
            padding: const EdgeInsets.only(bottom: _fabReserve),
            child: RefreshIndicator(
              onRefresh: _pullToRefresh,
              // The pull comes from inside a page, so it reaches here one
              // viewport deeper than the default predicate accepts.
              notificationPredicate: (notification) => notification.depth == 1,
              // Exactly two children, so paging stops at both ends on its
              // own — there is no third page to clamp against.
              child: PageView(
                onPageChanged: context.read<CalendarCubit>().showPage,
                children: [
                  for (final grid in grids) _MonthGrid(grid, state.muted),
                ],
              ),
            ),
          ),
        ),
      ],
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

/// Nothing loaded and no way to load it. Retry syncs first, which is what
/// makes it the cure for a replica that has never been synced.
class _FirstLoadError extends StatelessWidget {
  const _FirstLoadError({required this.onRetry});

  final Future<bool> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Impossibile leggere i turni.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Riprova')),
        ],
      ),
    );
  }
}

/// The Shift Filter: the six Shift Codes, tapped on and off. A [Wrap] rather
/// than a row of equal shares — six single letters fit one line on a phone,
/// and falling to a second line beats overflowing. A scroll view would have
/// been worse still: it would fight the pull-to-refresh for the same gesture.
class _ShiftFilterRow extends StatelessWidget {
  const _ShiftFilterRow({required this.selected});

  final Set<ShiftType> selected;

  @override
  Widget build(BuildContext context) {
    final toggle = context.read<CalendarCubit>().toggleShift;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final type in ShiftType.values)
            FilterChip(
              // The letter is drawn, the Italian name is spoken — the same
              // trade the Month Editor's segments make.
              label: Text(type.code, semanticsLabel: type.label),
              selected: selected.contains(type),
              // A tick beside a one-letter label doubles the chip's width and
              // says nothing the fill has not already said.
              showCheckmark: false,
              onSelected: (_) => toggle(type),
            ),
        ],
      ),
    );
  }
}

/// One column heading, which is also the Weekday Filter's control. Not a
/// [FilterChip]: a chip's own padding would pull the letter off the centre of
/// the column it labels, and labelling the column is what it is here for.
class _WeekdayFilter extends StatelessWidget {
  const _WeekdayFilter({required this.weekday, required this.selected});

  final int weekday;

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    void toggle() => context.read<CalendarCubit>().toggleWeekday(weekday);
    return Semantics(
      // The bare initial says nothing out loud; the selected state is the
      // other half of what a filter control has to announce.
      label: weekdayNames[weekday],
      button: true,
      selected: selected,
      // Excluding the InkWell's semantics takes its tap action with them, so
      // the action is restated here — otherwise the control announces itself
      // perfectly and then does nothing when a screen reader activates it.
      onTap: toggle,
      excludeSemantics: true,
      child: InkWell(
        onTap: toggle,
        child: SizedBox(
          // A tap target you can hit, on a row of text that is much shorter.
          height: 48,
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // The chips' selected colour, not the primary that fills
                // today's tile: one colour, one meaning.
                color: selected ? theme.colorScheme.secondaryContainer : null,
              ),
              child: Text(
                // L M M G V S D, straight off the full names.
                weekdayNames[weekday][0],
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected
                      ? theme.colorScheme.onSecondaryContainer
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One month's grid of square tiles, as large as the space allows.
class _MonthGrid extends StatelessWidget {
  const _MonthGrid(this.cells, this.muted);

  final List<DayCell> cells;

  /// Whether a day fails the Filter — [CalendarState.muted], passed down so
  /// the tiles decide nothing themselves.
  final bool Function(DayCell) muted;

  @override
  Widget build(BuildContext context) {
    // The grid never scrolls — it is sized to the viewport. The scroll view
    // exists only so the pull-down gesture has something to overscroll, which
    // is what RefreshIndicator listens to.
    return LayoutBuilder(
      builder: (context, constraints) {
        final rows = cells.length ~/ 7;
        // Square is a ceiling, not a lock: whichever of a column's width and a
        // row's height is smaller wins. A tall phone leaves space below the
        // grid — which is where the edit button goes — and a short one gives
        // tiles that are wider than they are tall rather than an overflow.
        final side = math.min(
          constraints.maxWidth / 7,
          constraints.maxHeight / rows,
        );
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: constraints.maxHeight,
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: side * 7,
                height: side * rows,
                child: Column(
                  children: [
                    for (var row = 0; row < cells.length; row += 7)
                      Expanded(
                        child: Row(
                          children: [
                            for (final cell in cells.skip(row).take(7))
                              Expanded(child: _DayCellView(cell, muted(cell))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// No gesture handling of any kind — the Month Editor is the only way in.
class _DayCellView extends StatelessWidget {
  const _DayCellView(this.cell, this.muted);

  final DayCell cell;

  /// Dimmed because it failed the Filter. The same dimming a filler day
  /// already has, and never on top of it.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Today is filled only on the page that owns the day. It also appears as
    // filler on the next month's page whenever it is the last day of a month,
    // and a dimmed tile carrying a loud fill is neither one thing nor the
    // other — so the page that merely borrows the day draws it plainly.
    final highlighted = cell.isToday && !cell.isFiller;
    final foreground = highlighted ? theme.colorScheme.onPrimary : null;
    return Opacity(
      // One opacity for both reasons, so a muted filler day is not dimmed
      // twice. Today's fill dims with everything else: an exception for it
      // would read as "today matched".
      opacity: cell.isFiller || muted ? 0.35 : 1,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: highlighted ? theme.colorScheme.primary : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              // The fill says everything today's tile needs to say; an outline
              // on top of it would only muddy the edge.
              side: highlighted
                  ? BorderSide.none
                  : BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: Center(
            // Tiles get small on a short screen. Scaling down beats clipping,
            // and beats a layout that only works above some secret width.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${cell.date.day}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: foreground,
                    ),
                  ),
                  Text(
                    cell.shift?.code ?? '',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

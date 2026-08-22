import 'dart:math' as math;

import 'package:catui/catui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../shared/italian_dates.dart';
import '../../shared/shift_type.dart';
import '../../shared/widgets/floating_bottom_bar.dart';
import 'cubit/calendar_cubit.dart';

/// The Calendar: the Data Window's two months as a carousel. Every decision it
/// draws — which cells exist, which are filler, what each one shows — was
/// already made in [CalendarCubit]. The edit button lives in the Shell now,
/// which is also the only thing here that writes.
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
        // spinner and the connect-error screen, which the Shell never mounts
        // over — see ADR 0004.
        return Scaffold(
          body: SafeArea(
            // Not at the bottom: `barReserve` already measures from the raw
            // edge, and a SafeArea under it would take the inset off twice.
            bottom: false,
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
        _FilterControls(
          shiftFilter: state.shiftFilter,
          weekdayFilter: state.weekdayFilter,
        ),
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
        // A heading and nothing more: seven letters centred over the columns
        // they name. Nothing here is tappable — a control that looks exactly
        // like a column heading is one nobody finds, which is why the Filter
        // has its own chips above.
        Padding(
          key: const Key('weekday-header'),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              for (var day = DateTime.monday; day <= DateTime.sunday; day++)
                Expanded(
                  child: Center(
                    child: Text(
                      // L M M G V S D, straight off the full names.
                      weekdayNames[day][0],
                      // The bare initial says nothing out loud, and it is the
                      // only thing telling the two `M`s apart.
                      semanticsLabel: weekdayNames[day],
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            // The floating bar overlaps whatever is under it, and on a short
            // screen the grid reaches the bottom. Reserved here so the last
            // row stops above it rather than under it.
            padding: EdgeInsets.only(bottom: barReserve(context)),
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

/// The Filter's controls, both groups always drawn. Nothing to expand: a
/// disclosure is a promise of a control rather than a control, and the
/// summary it needs to keep that promise says the selection a second time in
/// letters that are one heading short of unambiguous.
///
/// The block sits above the month title and outside the carousel, so paging
/// between months leaves the selection alone. Nothing here holds state — what
/// is selected lives in [CalendarState] and nothing else needs remembering.
class _FilterControls extends StatelessWidget {
  const _FilterControls({
    required this.shiftFilter,
    required this.weekdayFilter,
  });

  final Set<ShiftType> shiftFilter;

  final Set<int> weekdayFilter;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CalendarCubit>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilterGroup(
            // The heading says what a tap does, not what the row contains:
            // rows that are always on screen have to earn their space.
            heading: 'Filtra per turno',
            children: [
              for (final type in ShiftType.values)
                FilterChip(
                  // The letter is drawn, the Italian name is spoken — the same
                  // trade the Month Editor's segments make.
                  label: Text(type.code, semanticsLabel: type.label),
                  selected: shiftFilter.contains(type),
                  // A tick beside a one-letter label doubles the chip's width
                  // and says nothing the fill has not already said.
                  showCheckmark: false,
                  onSelected: (_) => cubit.toggleShift(type),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _FilterGroup(
            heading: 'Filtra per giorno',
            children: [
              for (var day = DateTime.monday; day <= DateTime.sunday; day++)
                FilterChip(
                  label: Text(
                    weekdayNames[day][0],
                    semanticsLabel: weekdayNames[day],
                  ),
                  selected: weekdayFilter.contains(day),
                  showCheckmark: false,
                  onSelected: (_) => cubit.toggleWeekday(day),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One of the Filter's two groups — the Shift Filter or the Weekday Filter —
/// as a heading over its chips. The heading is what separates the two groups
/// and what settles the one collision the shared chip idiom creates — `S` is
/// Smonto under `Filtra per turno` and Sabato under `Filtra per giorno`, and
/// the letter alone cannot say which.
///
/// A [Wrap] rather than a row of equal shares: the letters fit one line on a
/// phone, and falling to a second line beats overflowing. A scroll view would
/// be worse still — it would fight the pull-to-refresh for the same gesture.
class _FilterGroup extends StatelessWidget {
  /// The heading doubles as the key. The two groups draw the same chips from
  /// the same idiom, so the heading is the only thing that tells them apart —
  /// on screen, and for anything looking one of them up.
  _FilterGroup({required this.heading, required this.children})
    : super(key: Key(heading));

  final String heading;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading, style: Theme.of(context).textTheme.labelMedium),
        Wrap(spacing: 8, runSpacing: 4, children: children),
      ],
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
              borderRadius: BorderRadius.circular(AppTokens.radius),
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

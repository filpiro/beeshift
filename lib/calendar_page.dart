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
        _FilterPanel(
          shiftFilter: state.shiftFilter,
          weekdayFilter: state.weekdayFilter,
        ),
        // A heading and nothing more: seven letters centred over the columns
        // they name. Nothing here is tappable — a control that looks exactly
        // like a column heading is one nobody finds, which is why the Filter
        // lives in the panel above.
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

/// The Filter's controls, both groups in one disclosure. Shut on open and
/// shut most of the time — what it says shut is the whole answer to "is a
/// Filter on?", which is why the selection goes in the subtitle rather than
/// behind the chevron.
///
/// Openness is not held anywhere: [ExpansionTile] keeps its own, and whether
/// a disclosure is open is not something a read-only cubit over Shifts and
/// the Filter should be able to answer. The panel sits outside the carousel,
/// so paging between months leaves it as it was either way.
class _FilterPanel extends StatelessWidget {
  const _FilterPanel({required this.shiftFilter, required this.weekdayFilter});

  final Set<ShiftType> shiftFilter;

  final Set<int> weekdayFilter;

  /// What is selected, each group in its display order and shifts before
  /// weekdays regardless of what was tapped first. Empty when nothing is —
  /// the tile then has no subtitle at all rather than an empty line.
  ///
  /// [spoken] takes the Italian names instead of the letters. The chips get
  /// away with letters because a heading names their group and a fixed row
  /// position separates the two `M`s; a subtitle has neither, so read aloud
  /// it would be the one place a Shift Code says nothing.
  String _summary({required bool spoken}) => [
    for (final type in ShiftType.values)
      if (shiftFilter.contains(type)) spoken ? type.label : type.code,
    for (var day = DateTime.monday; day <= DateTime.sunday; day++)
      if (weekdayFilter.contains(day))
        spoken ? weekdayNames[day] : weekdayNames[day][0],
  ].join(', ');

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CalendarCubit>();
    final summary = _summary(spoken: false);
    return ExpansionTile(
      title: const Text('Filtri'),
      subtitle: summary.isEmpty
          ? null
          : Text(summary, semanticsLabel: _summary(spoken: true)),
      // The chevron moves to the left so the trailing corner is free: a
      // `trailing` widget would otherwise replace it. That is what lets
      // Azzera be tapped without opening the panel, which is the point of
      // having a clear-all at all.
      controlAffinity: ListTileControlAffinity.leading,
      trailing: summary.isEmpty
          ? null
          : TextButton(
              onPressed: cubit.clearFilter,
              child: const Text('Azzera'),
            ),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      children: [
        _FilterGroup(
          heading: 'Turni',
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
        _FilterGroup(
          heading: 'Giorni',
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
    );
  }
}

/// One of the Filter's two groups — the Shift Filter or the Weekday Filter —
/// as a heading over its chips. The heading is what
/// separates the two groups and what settles the one collision the shared
/// chip idiom creates — `S` is Smonto under `Turni` and Sabato under
/// `Giorni`, and the letter alone cannot say which.
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

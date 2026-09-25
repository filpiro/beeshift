import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../shared/italian_dates.dart';
import '../../shared/shift_colors.dart';
import '../../shared/shift_type.dart';
import '../../shared/widgets/floating_bottom_bar.dart';
import '../../shared/widgets/picked_style.dart';
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
    // At the top: the bottom edge is under the floating bar.
    showToast(
      context: context,
      builder: (context, overlay) =>
          const SurfaceCard(child: Text('Aggiornamento non riuscito')),
      location: ToastLocation.topCenter,
    );
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
          child: SafeArea(
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
            style: Theme.of(context).typography.xLarge,
          ),
        ),
        // A heading and nothing more: seven letters centred over the columns
        // they name. Nothing here is tappable — a control that looks exactly
        // like a column heading is one nobody finds, which is why the Filter
        // has its own letters above.
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
                      style: Theme.of(context).typography.xSmall,
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
            // Exactly two children, so paging stops at both ends on its own —
            // there is no third page to clamp against.
            child: PageView(
              onPageChanged: context.read<CalendarCubit>().showPage,
              children: [
                // One trigger per page, not one around the carousel:
                // RefreshTrigger only hears its direct scrollable, and around
                // the PageView that is the sideways one.
                for (final grid in grids)
                  RefreshTrigger(
                    onRefresh: _pullToRefresh,
                    child: _MonthGrid(grid, state.muted),
                  ),
              ],
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
          PrimaryButton(onPressed: onRetry, child: const Text('Riprova')),
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
    final theme = Theme.of(context);
    final colors = ShiftColors.of(context);
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
                _FilterLetter(
                  // The letter is drawn, the Italian name is spoken — the same
                  // trade the Month Editor's segments make.
                  code: type.code,
                  label: type.label,
                  color: colors[type]!,
                  selected: shiftFilter.contains(type),
                  onSelected: () => cubit.toggleShift(type),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _FilterGroup(
            heading: 'Filtra per giorno',
            children: [
              for (var day = DateTime.monday; day <= DateTime.sunday; day++)
                _FilterLetter(
                  code: weekdayNames[day][0],
                  label: weekdayNames[day],
                  // A weekday is not a Shift Type and has no Shift Colour, so
                  // the app's accent stands in — same shape, same border,
                  // yellow rather than a hue that would claim to be a Shift.
                  color: theme.colorScheme.primary,
                  selected: weekdayFilter.contains(day),
                  onSelected: () => cubit.toggleWeekday(day),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One letter in the Filter, drawn the way the Month Editor draws its
/// choices — the shared idiom in [pickedStyle], not a shared widget: this one
/// wraps and multi-selects, and a control covering both would carry two
/// behaviours to serve neither.
class _FilterLetter extends StatelessWidget {
  const _FilterLetter({
    required this.code,
    required this.label,
    required this.color,
    required this.selected,
    required this.onSelected,
  });

  /// The letter that is drawn.
  final String code;

  /// The Italian name, which is what a screen reader says — and, for the
  /// weekdays, the only thing telling the two `M`s apart.
  final String label;

  /// What this letter turns when it is picked.
  final Color color;

  final bool selected;

  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // No fill either way: the border and the letter carry it, so the two
    // states differ by colour and weight alone. A plain Button, not a Toggle:
    // a Toggle swaps to a filled style whenever it is on.
    return Button(
      style: pickedStyle(theme, color: color, selected: selected),
      onPressed: onSelected,
      // A button carries no selected flag of its own, so it is said here.
      child: Semantics(
        selected: selected,
        child: Text(code, semanticsLabel: label),
      ),
    );
  }
}

/// One of the Filter's two groups — the Shift Filter or the Weekday Filter —
/// as a heading over its letters. The heading is what separates the two
/// groups and what settles the one collision the shared idiom creates — `S` is
/// Smonto under `Filtra per turno` and Sabato under `Filtra per giorno`, and
/// the letter alone cannot say which.
///
/// A [Wrap] rather than a row of equal shares: the letters fit one line on a
/// phone, and falling to a second line beats overflowing. A scroll view would
/// be worse still — it would fight the pull-to-refresh for the same gesture.
class _FilterGroup extends StatelessWidget {
  /// The heading doubles as the key. The two groups draw the same letters from
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
        Text(
          heading,
          style: Theme.of(
            context,
          ).typography.xSmall.copyWith(fontWeight: FontWeight.w500),
        ),
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
    // is what RefreshTrigger listens to.
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
    final shift = cell.shift;
    // A day with no Shift has no Shift Colour, so the accent stands in.
    final shiftColor = shift == null
        ? theme.colorScheme.primary
        : ShiftColors.of(context)[shift]!;
    // Today is marked only on the page that owns the day. It also appears as
    // filler on the next month's page whenever it is the last day of a month,
    // and a dimmed tile carrying a loud mark is neither one thing nor the
    // other — so the page that merely borrows the day draws it plainly.
    final highlighted = cell.isToday && !cell.isFiller;
    return Opacity(
      // One opacity for both reasons, so a muted filler day is not dimmed
      // twice. Today's mark dims with everything else: an exception for it
      // would read as "today matched".
      opacity: cell.isFiller || muted ? 0.35 : 1,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(theme.radiusMd),
              // Today keeps its own Shift Colour on the edge rather than a
              // slab of accent across the face: the Shift Code inside stays
              // the thing you read, and the border is only how you find it.
              side: highlighted
                  ? BorderSide(color: shiftColor)
                  : BorderSide(color: theme.colorScheme.border),
            ),
          ),
          // Tiles get small on a short screen. Scaling each text down beats
          // clipping, and beats a layout that only works above some width.
          child: Stack(
            children: [
              // The day number is how you find the right tile, not what you
              // read off it — so it stays small and gets out of the corner
              // the Shift Code wants.
              Positioned(
                top: 6,
                right: 6,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${cell.date.day}',
                    style: theme.typography.xSmall.copyWith(
                      fontWeight: highlighted
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
              if (shift != null)
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    // The day number sits 4px off a ~12px label; the Shift Code
                    // is drawn twice that size, so it sits twice as far off the
                    // corner and the two insets read as the same gap.
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        shift.code,
                        // The letter is drawn and the colour carries it; the
                        // Italian name is what is spoken — colour says
                        // nothing out loud, and neither does a bare `N`.
                        semanticsLabel: shift.label,
                        style: theme.typography.xLarge.copyWith(
                          color: shiftColor,
                          fontWeight: highlighted ? FontWeight(900) : null,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

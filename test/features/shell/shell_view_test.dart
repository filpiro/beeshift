import 'package:beeshift/features/calendar/cubit/calendar_cubit.dart';
import 'package:beeshift/features/month_editor/month_editor_view.dart';
import 'package:beeshift/features/settings/cubit/theme_cubit.dart';
import 'package:beeshift/features/shell/shell_view.dart';
import 'package:beeshift/shared/shift_type.dart';
import 'package:beeshift/shared/theme.dart';
import 'package:beeshift/shared/widgets/floating_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../data/fake_shifts_repository.dart';

/// The Shell: the bar over the Calendar, the round trip to Settings, the
/// Month Editor push, and the disabled edit button. What each destination
/// draws on its own is asserted in its own tests.
void main() {
  late FakeShiftsRepository repository;

  ThemeCubit fakeThemeCubit() =>
      ThemeCubit(read: () async => null, write: (_) async {});

  Future<void> pumpShell(
    WidgetTester tester, {
    Map<String, ShiftType> shifts = const {},
    bool failFirstLoad = false,
    double bottomInset = 0,
  }) async {
    repository = FakeShiftsRepository(shifts);
    if (failFirstLoad) repository.failing.add('fetchRange');
    final cubit = CalendarCubit(repository, clock: () => DateTime(2026, 2, 15));
    await cubit.load();
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: Builder(
          // A gesture bar or a home indicator, faked onto the real
          // MediaQuery rather than over it: replacing it wholesale would
          // zero the screen size for everything below.
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(viewPadding: EdgeInsets.only(bottom: bottomInset)),
            child: MultiBlocProvider(
              providers: [
                BlocProvider<CalendarCubit>.value(value: cubit),
                BlocProvider<ThemeCubit>(create: (_) => fakeThemeCubit()),
              ],
              child: ShellPage(repository: repository),
            ),
          ),
        ),
      ),
    );
  }

  /// Active is the accent on the glyph and nothing behind it — no pill, no
  /// fill.
  bool activeAt(WidgetTester tester, String label) {
    final button = find.byKey(Key(label));
    final style = tester.widget<IconButton>(button).style;
    expect(style?.backgroundColor, isNull, reason: 'the icon carries it alone');
    return style?.foregroundColor?.resolve({}) ==
        Theme.of(tester.element(button)).colorScheme.primary;
  }

  testWidgets('there is no floating edit button anywhere', (tester) async {
    await pumpShell(tester);

    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('a pill hugs three buttons — Calendario, Modifica, '
      'Impostazioni — each named to a screen reader', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpShell(tester);

    for (final label in ['Calendario', 'Modifica', 'Impostazioni']) {
      expect(find.byTooltip(label), findsOne);
      expect(find.bySemanticsLabel(label), findsOne);
    }

    // Left to right: the two destinations flank the one action.
    final order = [
      'Calendario',
      'Modifica',
      'Impostazioni',
    ].map((l) => tester.getCenter(find.byKey(Key(l))).dx).toList();
    expect(order[0], lessThan(order[1]));
    expect(order[1], lessThan(order[2]));

    // A pill hugging its buttons, not a bar spanning the screen.
    final pill = tester.getRect(find.byType(Material).last);
    expect(pill.width, lessThan(tester.getRect(find.byType(ShellPage)).width));
    handle.dispose();
  });

  testWidgets('one destination is active at a time, and Calendario is the '
      'way back from Settings', (tester) async {
    await pumpShell(tester);
    expect(activeAt(tester, 'Calendario'), isTrue);
    expect(activeAt(tester, 'Impostazioni'), isFalse);
    expect(find.text('Febbraio 2026'), findsOne);

    await tester.tap(find.byTooltip('Impostazioni'));
    await tester.pumpAndSettle();

    expect(activeAt(tester, 'Impostazioni'), isTrue);
    expect(activeAt(tester, 'Calendario'), isFalse);
    expect(find.text('Impostazioni'), findsOne, reason: "Settings' app bar");
    expect(find.text('Febbraio 2026'), findsNothing);

    await tester.tap(find.byTooltip('Calendario'));
    await tester.pumpAndSettle();

    expect(activeAt(tester, 'Calendario'), isTrue);
    expect(activeAt(tester, 'Impostazioni'), isFalse);
    expect(find.text('Febbraio 2026'), findsOne);
  });

  testWidgets('tapping the destination already showing does nothing', (
    tester,
  ) async {
    await pumpShell(tester);

    await tester.tap(find.byTooltip('Calendario'));
    await tester.pumpAndSettle();
    expect(find.text('Febbraio 2026'), findsOne, reason: 'still the Calendar');

    await tester.tap(find.byTooltip('Impostazioni'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Impostazioni'));
    await tester.pumpAndSettle();

    expect(
      activeAt(tester, 'Impostazioni'),
      isTrue,
      reason: 'no self-toggle back to the Calendar',
    );
    expect(find.text('Febbraio 2026'), findsNothing);
  });

  testWidgets('the bar clears the system bottom inset, and the grid clears '
      'the bar, with an inset and without', (tester) async {
    for (final inset in [0.0, 48.0]) {
      await pumpShell(tester, bottomInset: inset);

      final screen = tester.getRect(find.byType(ShellPage));
      final bar = tester.getRect(find.byType(FloatingBottomBar));
      expect(
        screen.bottom - bar.bottom,
        moreOrLessEquals(inset + barBottomMargin),
        reason: 'inset $inset: the system furniture is not shared',
      );
      expect(
        tester.getRect(find.byType(PageView)).bottom,
        lessThanOrEqualTo(bar.top),
        reason: 'inset $inset: the last row of tiles stays visible',
      );
    }
  });

  testWidgets('coming back from Settings finds the same month and Filter', (
    tester,
  ) async {
    await pumpShell(
      tester,
      shifts: {'2026-02-02': ShiftType.notte}, // a Monday
    );

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, ShiftType.notte.code));
    await tester.pumpAndSettle();
    expect(find.text('Marzo 2026'), findsOne);

    await tester.tap(find.byTooltip('Impostazioni'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Calendario'));
    await tester.pumpAndSettle();

    expect(
      find.text('Marzo 2026'),
      findsOne,
      reason: 'not rebuilt to page one',
    );
    expect(
      tester
          .widget<FilterChip>(
            find.widgetWithText(FilterChip, ShiftType.notte.code),
          )
          .selected,
      isTrue,
    );
  });

  testWidgets('Modifica pushes the Month Editor full-screen, covering the '
      'bar, and Save returns to a refreshed Calendar', (tester) async {
    await pumpShell(tester);

    await tester.tap(find.byTooltip('Modifica'));
    await tester.pumpAndSettle();

    expect(find.byType(MonthEditorPage), findsOne);
    expect(find.text('Febbraio 2026'), findsOne, reason: "editor's app bar");
    expect(find.byTooltip('Modifica'), findsNothing, reason: 'bar covered');
    expect(find.byTooltip('Impostazioni'), findsNothing, reason: 'bar covered');
    expect(
      find.byTooltip('Calendario'),
      findsNothing,
      reason: 'no escape hatch out of unsaved work',
    );

    await tester.tap(find.text(ShiftType.riposo.code).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();

    expect(find.byType(MonthEditorPage), findsNothing);
    expect(find.byTooltip('Modifica'), findsOne, reason: 'back on the Shell');
    expect(find.text(ShiftType.riposo.code), findsWidgets);
  });

  testWidgets('Modifica is disabled while the first load is still in '
      'flight', (tester) async {
    repository = FakeShiftsRepository();
    // Deliberately not awaited: the cubit's construction-time state — grids
    // still null — is exactly what the Shell sees while a first load hangs.
    final cubit = CalendarCubit(repository, clock: () => DateTime(2026, 2, 15));
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<CalendarCubit>.value(value: cubit),
            BlocProvider<ThemeCubit>(create: (_) => fakeThemeCubit()),
          ],
          child: ShellPage(repository: repository),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOne);
    expect(
      tester.widget<IconButton>(find.byKey(const Key('Modifica'))).onPressed,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('Impostazioni')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('Modifica is disabled while the Calendar has no grids, '
      'Impostazioni stays live', (tester) async {
    await pumpShell(tester, failFirstLoad: true);

    expect(find.text('Impossibile leggere i turni.'), findsOne);
    expect(
      tester.widget<IconButton>(find.byKey(const Key('Modifica'))).onPressed,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('Impostazioni')))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byTooltip('Impostazioni'));
    await tester.pumpAndSettle();

    expect(
      find.text('Impostazioni'),
      findsOne,
      reason:
          'a dead read must not '
          'cost the theme',
    );
  });
}

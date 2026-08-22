import 'package:beeshift/features/calendar/cubit/calendar_cubit.dart';
import 'package:beeshift/features/month_editor/month_editor_view.dart';
import 'package:beeshift/features/shell/shell_view.dart';
import 'package:beeshift/shared/shift_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../data/fake_shifts_repository.dart';

/// The Shell: the bar over the Calendar, the round trip to Settings, the
/// Month Editor push, and the disabled edit button. What each destination
/// draws on its own is asserted in its own tests.
void main() {
  late FakeShiftsRepository repository;

  Future<void> pumpShell(
    WidgetTester tester, {
    Map<String, ShiftType> shifts = const {},
    bool failFirstLoad = false,
  }) async {
    repository = FakeShiftsRepository(shifts);
    if (failFirstLoad) repository.failing.add('fetchRange');
    final cubit = CalendarCubit(repository, clock: () => DateTime(2026, 2, 15));
    await cubit.load();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: ShellPage(
            repository: repository,
            themeMode: ValueNotifier(ThemeMode.system),
          ),
        ),
      ),
    );
  }

  bool activeAt(WidgetTester tester, String label) =>
      tester
          .widget<IconButton>(find.byKey(Key(label)))
          .style
          ?.backgroundColor !=
      null;

  testWidgets('there is no floating edit button anywhere', (tester) async {
    await pumpShell(tester);

    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('a pill hugs the two buttons, Impostazioni and Modifica, both '
      'named to a screen reader', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpShell(tester);

    expect(find.byTooltip('Impostazioni'), findsOne);
    expect(find.byTooltip('Modifica'), findsOne);
    expect(find.bySemanticsLabel('Impostazioni'), findsOne);
    expect(find.bySemanticsLabel('Modifica'), findsOne);

    // A pill hugging its buttons, not a bar spanning the screen.
    final pill = tester.getRect(find.byType(Material).last);
    expect(pill.width, lessThan(tester.getRect(find.byType(ShellPage)).width));
    handle.dispose();
  });

  testWidgets('Impostazioni is active on Settings, and returns to the '
      'Calendar when tapped again', (tester) async {
    await pumpShell(tester);
    expect(activeAt(tester, 'Impostazioni'), isFalse);
    expect(find.text('Febbraio 2026'), findsOne);

    await tester.tap(find.byTooltip('Impostazioni'));
    await tester.pumpAndSettle();

    expect(activeAt(tester, 'Impostazioni'), isTrue);
    expect(find.text('Impostazioni'), findsOne, reason: "Settings' app bar");
    expect(find.text('Febbraio 2026'), findsNothing);

    await tester.tap(find.byTooltip('Impostazioni'));
    await tester.pumpAndSettle();

    expect(activeAt(tester, 'Impostazioni'), isFalse);
    expect(find.text('Febbraio 2026'), findsOne);
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
    await tester.tap(find.byTooltip('Impostazioni'));
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
        home: BlocProvider.value(
          value: cubit,
          child: ShellPage(
            repository: repository,
            themeMode: ValueNotifier(ThemeMode.system),
          ),
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

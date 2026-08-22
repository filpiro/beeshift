import 'package:catui/catui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/shifts_repository.dart';
import '../../shared/widgets/floating_bottom_bar.dart';
import '../calendar/calendar_view.dart';
import '../calendar/cubit/calendar_cubit.dart';
import '../month_editor/cubit/month_editor_cubit.dart';
import '../month_editor/month_editor_view.dart';
import '../settings/settings_view.dart';

/// The app's two destinations, Calendar and Settings, as an index over an
/// `IndexedStack`: switching is `setState`, and both keep their state for
/// free. There is no router — see ADR 0004.
class ShellPage extends StatefulWidget {
  const ShellPage({super.key, required this.repository});

  /// Handed on to the Month Editor, exactly as the Calendar used to.
  final ShiftsRepository repository;

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  static const _calendar = 0;
  static const _settings = 1;

  int _index = _calendar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _index,
            children: [
              const CalendarPage(),
              const SettingsPage(),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: barBottomMargin),
              child: BlocBuilder<CalendarCubit, CalendarState>(
                builder: (context, state) => FloatingBottomBar(
                  destinations: [
                    BarDestination(
                      icon: LucideIcons.settings,
                      label: 'Impostazioni',
                      active: _index == _settings,
                      onPressed: () => setState(
                        () => _index = _index == _settings
                            ? _calendar
                            : _settings,
                      ),
                    ),
                    BarDestination(
                      icon: LucideIcons.pencil,
                      label: 'Modifica',
                      // Editing a schedule that could not be read is
                      // meaningless — grids arrive together, one load.
                      onPressed: state.grids == null
                          ? null
                          : () => _openEditor(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Opens the Month Editor on whichever month the Calendar has on screen,
  /// pre-loaded from the grid already in hand. On the way back the Calendar
  /// re-queries — a local read, no sync: read-your-writes means the row is
  /// already there.
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

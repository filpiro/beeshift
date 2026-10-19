import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'cubit/theme_cubit.dart';

/// One control today: Theme Mode. Applies the instant it is tapped, via the
/// [ThemeCubit] held above the Shell — see ticket 04.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const _labels = {
    ThemeMode.light: 'Chiaro',
    ThemeMode.dark: 'Scuro',
    ThemeMode.system: 'Sistema',
  };

  /// Tab order. Not [ThemeMode.values]: that runs system, light, dark, and the
  /// tabs read Chiaro, Scuro, Sistema.
  static const _modes = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        AppBar(title: const Text('Impostazioni')),
        const Divider(),
      ],
      // Not at the top: the AppBar header already takes that inset.
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tema',
                style: Theme.of(
                  context,
                ).typography.xSmall.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, mode) => Tabs(
                  expand: true,
                  index: _modes.indexOf(mode),
                  onChanged: (i) =>
                      context.read<ThemeCubit>().setMode(_modes[i]),
                  children: [
                    for (final m in _modes) TabItem(child: Text(_labels[m]!)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:catui/catui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tema', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, mode) => CatSegmented<ThemeMode>(
                  segments: _labels,
                  selected: mode,
                  onChanged: (value) => context.read<ThemeCubit>().setMode(value),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:catui/catui.dart';
import 'package:flutter/material.dart';

/// One control today: Theme Mode. Applies the instant it is tapped and does
/// not survive a restart yet — that is ticket 04.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.themeMode});

  /// Held by the Shell, not here, so leaving Settings does not lose the
  /// choice — and so [MaterialApp] can react to it directly.
  final ValueNotifier<ThemeMode> themeMode;

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
              ValueListenableBuilder(
                valueListenable: themeMode,
                builder: (context, mode, _) => CatSegmented<ThemeMode>(
                  segments: _labels,
                  selected: mode,
                  onChanged: (value) => themeMode.value = value,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

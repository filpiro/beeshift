import 'package:beeshift/features/settings/cubit/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The cubit is the whole seam: storage is a pair of injected functions, so
/// every case here runs without touching SharedPreferences at all.
void main() {
  test('nothing stored keeps the system default, at construction and after '
      'the read lands', () async {
    final cubit = ThemeCubit(read: () async => null, write: (_) async {});

    expect(cubit.state, ThemeMode.system);
    await cubit.ready;
    expect(cubit.state, ThemeMode.system);
  });

  test('a stored value wins over the system default once the read lands', () async {
    final cubit = ThemeCubit(read: () async => ThemeMode.dark, write: (_) async {});

    await cubit.ready;

    expect(cubit.state, ThemeMode.dark);
  });

  test('setting a mode applies it at once and writes it', () async {
    ThemeMode? written;
    final cubit = ThemeCubit(
      read: () async => null,
      write: (mode) async => written = mode,
    );
    await cubit.ready;

    cubit.setMode(ThemeMode.light);

    expect(cubit.state, ThemeMode.light, reason: 'no confirmation step');
    expect(written, ThemeMode.light);
  });
}

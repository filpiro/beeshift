import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The worker's Theme Mode choice, read once at construction and applied the
/// moment it lands. Until then the app draws [ThemeMode.system] — also what a
/// fresh install, with nothing stored yet, keeps forever.
///
/// [read] and [write] are handed in rather than reached for directly, so this
/// stays a plain state machine under test. `main.dart` wires them to
/// SharedPreferences — device-local, never the replica, which syncs (ADR
/// 0003) and would carry the choice to the other phone.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit({
    required Future<ThemeMode?> Function() read,
    required Future<void> Function(ThemeMode) write,
  }) : _write = write,
       super(ThemeMode.system) {
    ready = read().then((stored) {
      if (stored != null) emit(stored);
    });
  }

  final Future<void> Function(ThemeMode) _write;

  /// Resolves once a stored value, if any, has been applied. A test seam —
  /// production never awaits it, since the point is to never block the first
  /// paint on a read.
  late final Future<void> ready;

  void setMode(ThemeMode mode) {
    emit(mode);
    _write(mode);
  }
}

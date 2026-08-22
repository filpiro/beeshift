import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'data/shifts_repository.dart';
import 'features/calendar/calendar_view.dart';
import 'features/calendar/cubit/calendar_cubit.dart';
import 'shared/theme.dart';

// Supplied at build time: flutter run --dart-define-from-file=env.json
const _syncUrl = String.fromEnvironment('TURSO_DATABASE_URL');
const _authToken = String.fromEnvironment('TURSO_AUTH_TOKEN');

void main() {
  runApp(const MainApp());
}

Future<ShiftsRepository> _openRepository() async {
  // Without the defines the URL is empty and libSQL fails with something that
  // says nothing about the actual mistake. See the README for how to run.
  assert(_syncUrl.isNotEmpty, 'Missing --dart-define-from-file=env.json');
  // Application support, not cache — Android can reclaim the cache directory.
  final dir = await getApplicationSupportDirectory();
  final repository = ShiftsRepository.replica(
    path: '${dir.path}/replica.db',
    syncUrl: _syncUrl,
    authToken: _authToken,
  );
  await repository.connect();
  // No sync on a normal launch: opening the app is instant and never waits on
  // the network. Resume and pull-to-refresh are the only triggers — ticket 06.
  await syncIfEmpty(repository);
  return repository;
}

/// The one launch that has to wait on the network: the first. Until a sync has
/// run, the replica has no `shifts` table, and a read of it throws rather than
/// returning nothing — so every later launch skips this and stays instant.
///
/// A failure here is left to travel: it lands on the same screen an unopenable
/// database does, which is the truth of it — there is no app either way, and
/// Retry is the only thing that helps.
Future<void> syncIfEmpty(ShiftsRepository repository) async {
  if (await repository.hasShiftsTable()) return;
  await repository.sync();
}

class MainApp extends StatefulWidget {
  const MainApp({super.key, this.open = _openRepository});

  /// How the app gets its repository. Injected only so a test can fail the
  /// one thing the app cannot degrade around, then let it succeed.
  final Future<ShiftsRepository> Function() open;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  /// Held in state rather than at the top level so Retry can replace it: a
  /// Future runs once, so retrying means opening a new one.
  late Future<ShiftsRepository> _repository = _open();

  /// Opening starts immediately, but the FutureBuilder only subscribes at the
  /// next build — so a failure landing in between would be reported as an
  /// unhandled async error. [Future.ignore] marks it handled without hiding
  /// it: the builder still receives it and draws the retry screen.
  Future<ShiftsRepository> _open() => widget.open()..ignore();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      // The only theme axis the worker controls is on the device, not here —
      // see Theme Mode in the glossary. Choosing it is ticket 03.
      themeMode: ThemeMode.system,
      // No Scaffold here: each of the three states brings its own, so the
      // Calendar's edit button cannot float over the other two.
      home: FutureBuilder(
        future: _repository,
        builder: (context, snapshot) {
          // Full screen, because there is no app without the database —
          // showing an empty Calendar would be pretending otherwise.
          if (snapshot.hasError) {
            // The screen stays plain — the cause goes to the console, so a
            // build-config mistake doesn't look like a dead network.
            debugPrint('Opening the database failed: ${snapshot.error}');
            // A statement body, not an arrow: setState must not be handed
            // a closure that returns the Future it has just assigned.
            return Scaffold(
              body: SafeArea(
                child: _ConnectError(
                  onRetry: () {
                    setState(() {
                      _repository = _open();
                    });
                  },
                ),
              ),
            );
          }
          final repository = snapshot.data;
          if (repository == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return BlocProvider(
            create: (_) =>
                CalendarCubit(repository, clock: DateTime.now)..load(),
            child: CalendarPage(repository: repository),
          );
        },
      ),
    );
  }
}

/// The one failure the app cannot degrade around.
class _ConnectError extends StatelessWidget {
  const _ConnectError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Impossibile aprire il database.'),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Riprova')),
        ],
      ),
    );
  }
}

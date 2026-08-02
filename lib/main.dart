import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'calendar_cubit.dart';
import 'calendar_page.dart';
import 'shifts_repository.dart';

// Supplied at build time: flutter run --dart-define-from-file=env.json
const _syncUrl = String.fromEnvironment('TURSO_DATABASE_URL');
const _authToken = String.fromEnvironment('TURSO_AUTH_TOKEN');

void main() {
  runApp(const MainApp());
}

Future<ShiftsRepository> _openRepository() async {
  // Application support, not cache — Android can reclaim the cache directory.
  final dir = await getApplicationSupportDirectory();
  final repository = ShiftsRepository.replica(
    path: '${dir.path}/replica.db',
    syncUrl: _syncUrl,
    authToken: _authToken,
  );
  await repository.connect();
  // No sync here: opening the app is instant and never waits on the network.
  // Resume and pull-to-refresh are the only triggers — see ticket 06.
  return repository;
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
      home: Scaffold(
        body: SafeArea(
          child: FutureBuilder(
            future: _repository,
            builder: (context, snapshot) {
              // Full screen, because there is no app without the database —
              // showing an empty Calendar would be pretending otherwise.
              if (snapshot.hasError) {
                // A statement body, not an arrow: setState must not be handed
                // a closure that returns the Future it has just assigned.
                return _ConnectError(
                  onRetry: () {
                    setState(() {
                      _repository = _open();
                    });
                  },
                );
              }
              final repository = snapshot.data;
              if (repository == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return BlocProvider(
                create: (_) =>
                    CalendarCubit(repository, clock: DateTime.now)..load(),
                child: CalendarPage(repository: repository),
              );
            },
          ),
        ),
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

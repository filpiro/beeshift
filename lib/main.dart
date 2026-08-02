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

// Lazy top-level: opened once, not on every rebuild.
final _repository = _openRepository();

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: FutureBuilder(
            future: _repository,
            builder: (context, snapshot) {
              // ponytail: bare error text and spinner. Ticket 08 makes these
              // the real full-screen error with Retry.
              if (snapshot.hasError) {
                return Center(child: Text('${snapshot.error}'));
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

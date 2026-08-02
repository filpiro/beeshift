import 'package:libsql_dart/libsql_dart.dart';

import 'shift_type.dart';

/// A date as the database stores it: ISO `YYYY-MM-DD`. See ADR-0003.
String isoDate(DateTime date) => date.toIso8601String().substring(0, 10);

/// Owns the libSQL client. Reads come from the local replica; writes go
/// straight to the Turso primary. See ADR-0001 and ADR-0002.
class ShiftsRepository {
  /// The real thing: an embedded replica synced against Turso. No sync
  /// interval, so no background timer runs — sync happens only when asked.
  ShiftsRepository.replica({
    required String path,
    required String syncUrl,
    required String authToken,
  }) : _client = LibsqlClient.replica(
         path,
         syncUrl: syncUrl,
         authToken: authToken,
         readYourWrites: true,
       );

  /// A plain local file, no sync and no network. Tests only.
  ShiftsRepository.local(String path) : _client = LibsqlClient.local(path);

  final LibsqlClient _client;

  Future<void> connect() => _client.connect();

  Future<void> sync() => _client.sync();

  /// Shifts between [from] and [to] inclusive, keyed by ISO date.
  Future<Map<String, ShiftType>> fetchRange(DateTime from, DateTime to) async {
    final rows = await _client.query(
      'select date, code from shifts where date between ? and ?',
      positional: [isoDate(from), isoDate(to)],
    );
    return {
      for (final row in rows)
        row['date'] as String: ShiftType.fromCode(row['code'] as String),
    };
  }

  /// Writes every entry in one statement. Days absent from [shifts] keep
  /// whatever they had.
  Future<void> upsertAll(Map<String, ShiftType> shifts) async {
    if (shifts.isEmpty) return;
    final placeholders = List.filled(shifts.length, '(?, ?)').join(', ');
    await _client.execute(
      'insert into shifts (date, code) values $placeholders '
      'on conflict(date) do update set code = excluded.code',
      positional: [
        for (final entry in shifts.entries) ...[entry.key, entry.value.code],
      ],
    );
  }
}

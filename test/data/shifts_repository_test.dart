import 'dart:io';

import 'package:beeshift/data/shifts_repository.dart';
import 'package:beeshift/shared/shift_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libsql_dart/libsql_dart.dart';

/// Covers only what a fake repository cannot: that the SQL is real SQL.
/// Runs against a throwaway local file — no sync, no network, no credentials.
void main() {
  late String path;
  late ShiftsRepository repository;

  setUp(() async {
    // ponytail: not deleted afterwards — Windows holds the open database file
    // and the OS reaps its own temp directory. A few KB per run.
    final dir = await Directory.systemTemp.createTemp('beeshift_test');
    path = '${dir.path}/test.db';
    // The app never creates schema; this temporary database has to.
    final schema = LibsqlClient.local(path);
    await schema.connect();
    await schema.execute(File('database/schema.sql').readAsStringSync());
    await schema.dispose();

    repository = ShiftsRepository.local(path);
    await repository.connect();
  });

  test('upserts a batch and reads it back', () async {
    await repository.upsertAll({
      '2026-08-01': ShiftType.notte,
      '2026-08-02': ShiftType.smonto,
    });
    await repository.upsertAll({'2026-08-02': ShiftType.ferie});

    expect(
      await repository.fetchRange(DateTime(2026, 8, 1), DateTime(2026, 8, 2)),
      {'2026-08-01': ShiftType.notte, '2026-08-02': ShiftType.ferie},
    );
  });

  test('fetchRange returns only the range, bounds included', () async {
    await repository.upsertAll({
      '2026-07-31': ShiftType.primo,
      '2026-08-01': ShiftType.secondo,
      '2026-08-31': ShiftType.riposo,
      '2026-09-01': ShiftType.ferie,
    });

    expect(
      (await repository.fetchRange(
        DateTime(2026, 8, 1),
        DateTime(2026, 8, 31),
      )).keys,
      ['2026-08-01', '2026-08-31'],
    );
  });

  test('the CHECK constraint rejects an invalid Shift Code', () async {
    // Goes round the repository: the enum makes a bad code unrepresentable
    // in Dart, and this asserts the database still refuses one.
    final client = LibsqlClient.local(path);
    await client.connect();
    expect(
      () => client.execute("insert into shifts values ('2026-08-01', 'X')"),
      throwsA(anything),
    );
  });
}

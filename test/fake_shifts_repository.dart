import 'package:beeshift/shift_type.dart';
import 'package:beeshift/shifts_repository.dart';

/// The primary test seam: a plain class standing in for [ShiftsRepository] via
/// its implicit interface — no abstract class exists, and none is needed.
///
/// Records the ranges it was asked for, so a test can assert both how many
/// queries a load made and how wide they were.
class FakeShiftsRepository implements ShiftsRepository {
  FakeShiftsRepository([Map<String, ShiftType> shifts = const {}])
    : _shifts = {...shifts};

  final Map<String, ShiftType> _shifts;

  /// One entry per [fetchRange] call, in order.
  final List<(DateTime, DateTime)> ranges = [];

  /// Every call, by name, in order — so a test can assert that a sync
  /// happened before the query rather than merely that both happened.
  final List<String> calls = [];

  /// One entry per [upsertAll] call: the exact payload it was handed.
  final List<Map<String, ShiftType>> batches = [];

  /// Fail on demand: method names in here throw instead of succeeding. A test
  /// adds and removes entries mid-run, which is what lets it assert a retry
  /// after connectivity comes back.
  final Set<String> failing = {};

  /// Records the call, then fails it if the test asked for that — recorded
  /// either way, because a failed attempt still happened.
  void _called(String name) {
    calls.add(name);
    if (failing.contains(name)) throw Exception('$name failed');
  }

  /// Whether the replica has a schema. A test sets this false to stand in for
  /// a brand-new replica file, which is an empty SQLite database.
  bool schema = true;

  @override
  Future<void> connect() async => _called('connect');

  @override
  Future<bool> hasShiftsTable() async {
    _called('hasShiftsTable');
    return schema;
  }

  @override
  Future<void> sync() async => _called('sync');

  @override
  Future<Map<String, ShiftType>> fetchRange(DateTime from, DateTime to) async {
    _called('fetchRange');
    ranges.add((from, to));
    final fromIso = isoDate(from);
    final toIso = isoDate(to);
    return {
      for (final entry in _shifts.entries)
        if (entry.key.compareTo(fromIso) >= 0 &&
            entry.key.compareTo(toIso) <= 0)
          entry.key: entry.value,
    };
  }

  @override
  Future<void> upsertAll(Map<String, ShiftType> shifts) async {
    _called('upsertAll');
    batches.add({...shifts});
    _shifts.addAll(shifts);
  }
}

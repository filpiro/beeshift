/// The six Shift Types. The enum is the source of truth — there is no
/// `shift_types` reference table and nothing is loaded at startup. The `CHECK`
/// constraint on `shifts.code` is a backstop, not the definition. See ADR-0003.
///
/// Declaration order is the display order.
enum ShiftType {
  primo('7', 'Primo'),
  secondo('3', 'Secondo'),
  notte('N', 'Notte'),
  smonto('S', 'Smonto'),
  riposo('R', 'Riposo'),
  ferie('F', 'Ferie');

  const ShiftType(this.code, this.label);

  /// The single letter stored in the database and shown in a day cell.
  final String code;

  /// The Italian name, shown wherever the code alone would be cryptic.
  final String label;

  static ShiftType fromCode(String code) =>
      values.firstWhere((type) => type.code == code);
}

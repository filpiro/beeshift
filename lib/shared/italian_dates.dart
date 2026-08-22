/// The app's date words. One user, one language, so there is nothing to
/// negotiate with a locale.
///
/// Both lists are indexed to match [DateTime] — `month` counts from 1 and
/// `weekday` counts from Monday — so element 0 is a placeholder that is never
/// read. That keeps every call site a plain lookup with no off-by-one.
///
/// ponytail: two const lists, not the intl package, for nineteen strings.
library;

const monthNames = [
  '',
  'Gennaio',
  'Febbraio',
  'Marzo',
  'Aprile',
  'Maggio',
  'Giugno',
  'Luglio',
  'Agosto',
  'Settembre',
  'Ottobre',
  'Novembre',
  'Dicembre',
];

/// Monday first, matching how the Rotation is written. The Calendar's column
/// headings are the first letter of each of these — `L M M G V S D` — which is
/// why there is no separate list of initials to keep in step with this one.
const weekdayNames = [
  '',
  'Lunedì',
  'Martedì',
  'Mercoledì',
  'Giovedì',
  'Venerdì',
  'Sabato',
  'Domenica',
];

/// The visible month, spelled out. The year is always there: the Data Window
/// crosses a year boundary every December.
String monthTitle(DateTime month) => '${monthNames[month.month]} ${month.year}';

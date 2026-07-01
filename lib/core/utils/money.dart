/// The rounding law: money is rounded to whole cents at every write
/// boundary. Display math may do what it likes; nothing fractional-cent
/// ever lands in the database.
library;

/// Rounds [value] to whole cents, half away from zero with DECIMAL
/// semantics: 1.005 rounds to 1.01 even though the nearest binary double
/// is 1.00499999999999989 (whose naive `(v*100).round()` gives 1.00).
/// A guard epsilon nudges scaled values that sit a hair below a half-cent
/// boundary due to binary representation error over the line; it is far
/// too small (1e-9 dollars-in-cents) to move any genuinely sub-half value.
double roundToCents(double value) {
  if (!value.isFinite) return value;
  final scaled = value * 100;
  final nudged = scaled + (scaled.isNegative ? -1e-9 : 1e-9);
  return nudged.roundToDouble() / 100;
}

/// Nullable variant for optional money fields: null (no price) stays null.
double? roundToCentsOrNull(double? value) =>
    value == null ? null : roundToCents(value);

/// The wire→storage crossing: decimal dollars (backup JSON, CSV, sync,
/// user input) become the integer cents the database stores. Same decimal
/// half-away-from-zero semantics as [roundToCents], so 1.005 → 101.
int centsFromDollars(double dollars) => (roundToCents(dollars) * 100).round();

/// Nullable variant: no price stays no price.
int? centsFromDollarsOrNull(double? dollars) =>
    dollars == null ? null : centsFromDollars(dollars);

/// The storage→wire crossing: integer cents back to the decimal dollars
/// every export and sync payload speaks. Exact inverse of [centsFromDollars]
/// for whole-cent values.
double dollarsFromCents(int cents) => cents / 100;

/// Nullable variant: no price stays no price.
double? dollarsFromCentsOrNull(int? cents) =>
    cents == null ? null : dollarsFromCents(cents);

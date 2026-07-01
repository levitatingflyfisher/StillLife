/// Locale-tolerant parsing of user-typed money amounts.
///
/// `double.tryParse` is locale-naive: a comma-decimal user typing "12,50"
/// gets `null`, and callers that feed that straight into a save silently
/// drop the price. This parser accepts both decimal-comma and decimal-dot
/// conventions and returns null ONLY for genuinely unparseable input, so
/// callers can surface a validation error instead of losing money data.
library;

import 'money.dart';

/// Currency symbols and whitespace (incl. NBSP/narrow-NBSP, which many
/// locales use as thousands grouping) that may decorate a typed amount.
final RegExp _decoration = RegExp('[\\s\\u00A0\\u202F\$€£¥₹¢]');

final RegExp _digitsSeparators = RegExp(r'^[0-9.,]+$');
final RegExp _digitsOnly = RegExp(r'^[0-9]+$');

/// Parses a user-typed money string.
///
/// Rules:
/// - currency symbols and spaces are stripped ("$12.50", "1 234,56");
/// - a comma with no dot is a decimal separator ("12,50" → 12.50);
/// - when both separators appear, the last one is the decimal separator and
///   the other is thousands grouping ("1.234,56" → 1234.56,
///   "1,234.56" → 1234.56);
/// - repeated same-side separators are thousands grouping ("1,234,567");
/// - a trailing separator is tolerated ("12." → 12, a mid-typing save);
/// - a single separator followed by exactly 3 digits with a groupable
///   integer part ("1,234", "1.234") is AMBIGUOUS — one thousand to a US
///   user, one-point-something to a comma-decimal user. Guessing either way
///   silently corrupts values 1000x, so it returns null (see
///   [isAmbiguousMoneyInput] for the caller-facing message);
/// - anything else — letters, bad grouping ("1,2,3"), bare separators —
///   returns null so the caller can show a validation error rather than
///   silently saving without a price.
double? parseMoneyInput(String raw) {
  var s = raw.replaceAll(_decoration, '');
  if (s.isEmpty || !_digitsSeparators.hasMatch(s)) return null;
  if (_isAmbiguousCanonical(s)) return null;

  final lastComma = s.lastIndexOf(',');
  final lastDot = s.lastIndexOf('.');

  String canonical;
  if (lastComma >= 0 && lastDot >= 0) {
    // Both separators: the last-occurring one is the decimal separator.
    final decimalIsComma = lastComma > lastDot;
    final decIdx = decimalIsComma ? lastComma : lastDot;
    final thousandsSep = decimalIsComma ? '.' : ',';
    final intPart = s.substring(0, decIdx);
    final fracPart = s.substring(decIdx + 1);
    if (!_validThousandsGroups(intPart, thousandsSep)) return null;
    canonical = '${intPart.replaceAll(thousandsSep, '')}.$fracPart';
  } else if (lastComma >= 0) {
    if (','.allMatches(s).length == 1) {
      // A single comma and no dot is a decimal separator ("12,50").
      canonical = s.replaceFirst(',', '.');
    } else {
      if (!_validThousandsGroups(s, ',')) return null;
      canonical = s.replaceAll(',', '');
    }
  } else if (lastDot >= 0 && '.'.allMatches(s).length > 1) {
    if (!_validThousandsGroups(s, '.')) return null;
    canonical = s.replaceAll('.', '');
  } else {
    canonical = s;
  }

  // Tolerate a trailing decimal separator ("12." saved mid-typing).
  if (canonical.endsWith('.')) {
    canonical = canonical.substring(0, canonical.length - 1);
  }
  if (canonical.isEmpty) return null;
  return double.tryParse(canonical);
}

/// Separators demoted to thousands grouping must actually look like
/// grouping: digit groups of 1-3, then exactly 3 ("1,234,567" yes,
/// "1,2,3" and "12..5" no).
bool _validThousandsGroups(String intPart, String sep) {
  if (intPart.isEmpty) return false;
  final groups = intPart.split(sep);
  if (groups.length == 1) {
    // No grouping separator present at all — plain digits are fine.
    return _digitsOnly.hasMatch(intPart);
  }
  if (!groups.every(_digitsOnly.hasMatch)) return false;
  if (groups.first.isEmpty || groups.first.length > 3) return false;
  return groups.skip(1).every((g) => g.length == 3);
}

/// True when [raw] is the ambiguous single-separator-then-exactly-3-digits
/// form ("1,234" / "1.234", decorations stripped): the integer part could be
/// a thousands group (1–3 digits) AND the 3-digit tail could equally be a
/// fraction. Deterministic and locale-independent — an inventory app must
/// refuse to guess rather than corrupt a value 1000x based on the device
/// locale.
bool isAmbiguousMoneyInput(String raw) =>
    _isAmbiguousCanonical(raw.replaceAll(_decoration, ''));

bool _isAmbiguousCanonical(String s) {
  if (!_digitsSeparators.hasMatch(s)) return false;
  final commas = ','.allMatches(s).length;
  final dots = '.'.allMatches(s).length;
  if (commas + dots != 1) return false;
  final sep = commas == 1 ? ',' : '.';
  final idx = s.indexOf(sep);
  final intPart = s.substring(0, idx);
  final fracPart = s.substring(idx + 1);
  // Readable as grouping only when the leading group has 1–3 digits and the
  // tail is exactly 3; readable as a decimal always — both at once is the
  // ambiguity.
  return fracPart.length == 3 &&
      intPart.isNotEmpty &&
      intPart.length <= 3 &&
      _digitsOnly.hasMatch(intPart) &&
      _digitsOnly.hasMatch(fracPart);
}

/// Parses a user-typed money string straight to storage cents, folding the
/// rounding law in so no caller can save an unrounded amount.
int? parseMoneyInputCents(String raw) =>
    centsFromDollarsOrNull(parseMoneyInput(raw));

/// A [TextFormField] validator for optional money fields: empty is fine
/// (no price is a legal state), anything else must parse — and the
/// ambiguous "1,234" form gets an actionable message instead of a silent
/// 1000x misreading.
String? validateMoneyInput(String? text) {
  final t = text?.trim();
  if (t == null || t.isEmpty) return null;
  if (isAmbiguousMoneyInput(t)) {
    return 'Ambiguous amount — use 1234 or 1,234.00';
  }
  return parseMoneyInput(t) == null ? 'Enter a valid amount' : null;
}

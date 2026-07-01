import 'package:intl/intl.dart';

extension CurrencyExtensions on double {
  String toCurrency({String locale = 'en_US', String symbol = '\$'}) {
    return NumberFormat.currency(locale: locale, symbol: symbol).format(this);
  }

  String toCompactCurrency({String locale = 'en_US', String symbol = '\$'}) {
    return NumberFormat.compactCurrency(
      locale: locale,
      symbol: symbol,
    ).format(this);
  }
}

extension NullableCurrencyExtensions on double? {
  String toCurrencyOrEmpty({String locale = 'en_US', String symbol = '\$'}) {
    return this?.toCurrency(locale: locale, symbol: symbol) ?? '';
  }
}

/// Display formatting for the storage representation: integer cents.
/// (Money is stored as cents and only becomes decimal dollars on a wire
/// or a screen — see lib/core/utils/money.dart.)
extension CentsCurrencyExtensions on int {
  String centsToCurrency({String locale = 'en_US', String symbol = '\$'}) {
    return (this / 100).toCurrency(locale: locale, symbol: symbol);
  }

  String centsToCompactCurrency({String locale = 'en_US', String symbol = '\$'}) {
    return (this / 100).toCompactCurrency(locale: locale, symbol: symbol);
  }
}

extension NullableCentsCurrencyExtensions on int? {
  String centsToCurrencyOrEmpty({String locale = 'en_US', String symbol = '\$'}) {
    return this?.centsToCurrency(locale: locale, symbol: symbol) ?? '';
  }
}

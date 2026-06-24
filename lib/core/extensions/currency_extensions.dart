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

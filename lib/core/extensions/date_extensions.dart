import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  String toShortDate() => DateFormat.yMd().format(this);
  String toLongDate() => DateFormat.yMMMMd().format(this);
  String toIso() => toIso8601String();

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}

extension NullableDateTimeExtensions on DateTime? {
  String toShortDateOrEmpty() => this?.toShortDate() ?? '';
}

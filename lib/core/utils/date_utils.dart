import 'package:intl/intl.dart';

extension PalavraDateFormatting on DateTime {
  String toBrtDateLabel() => DateFormat('dd/MM/yyyy').format(this);

  String toFirestoreDayId() => DateFormat('yyyy-MM-dd').format(this);

  bool isSameCalendarDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}
